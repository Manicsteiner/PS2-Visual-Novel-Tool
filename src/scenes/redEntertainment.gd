extends Control

@onready var file_load_bin: FileDialog = $FILELoadBIN
@onready var file_load_accessdb: FileDialog = $FILELoadACCESSDB
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var selected_files: PackedStringArray
var accessdb: String = ""
var folder_path: String = ""
var out_decomp: bool = false

func _ready() -> void:
	file_load_bin.filters = [
		"BG000.BIN, BG100.BIN, BG200.BIN,
		BG300.BIN, BG400.BIN, BG500.BIN,
		BG800.BIN, BG900.BIN"
		]
	file_load_accessdb.filters = ["ACCESSDB.BIN"]


func _process(delta: float) -> void:
	if selected_files and folder_path:
		extract_bin()
		selected_files.clear()
		folder_path = ""


func extract_bin() -> void:
	for file: int in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var accessdb_file: FileAccess = FileAccess.open(accessdb, FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		var tbl_start: int
		var tbl_end: int
		if arc_name == "BG000":
			tbl_start = 0x100
			tbl_end = 0x9F0
		elif arc_name == "BG100":
			tbl_start = 0x9F0
			tbl_end = 0x1990
		elif arc_name == "BG200":
			tbl_start = 0x1990
			tbl_end = 0x2A88
		elif arc_name == "BG300":
			tbl_start = 0x2A90
			tbl_end = 0x2F98
		elif arc_name == "BG400":
			tbl_start = 0x2FA0
			tbl_end = 0x3A18
		elif arc_name == "BG500":
			tbl_start = 0x3A20
			tbl_end = 0x4200
		elif arc_name == "BG800":
			tbl_start = 0x4200
			tbl_end = 0x42F8
		elif arc_name == "BG900":
			tbl_start = 0x4300
			tbl_end = 0x4838
		
		var table: int = tbl_start
		var id: int = 0
		while table < tbl_end:
			accessdb_file.seek(table)
			var f_off: int = accessdb_file.get_32() * 0x800
			var f_size: int = accessdb_file.get_32() * 0x800
			#if id != 334:
				#table += 8
				#id += 1
				#continue
				
			print("%08X %08X %s" % [f_off, f_size, folder_path + "/%s" % arc_name + "_%04d" % id + ".BIN"])
			
			in_file.seek(f_off)
			var buff_comp: PackedByteArray = in_file.get_buffer(f_size)
			
			var comp_off: int = buff_comp.decode_u32(0)
			if buff_comp.decode_u32(8) != 0: 
				push_error("Warning: ID %04d at 0x8 has an offset! Skipping..." % id)
				table += 8
				id += 1
				continue
			
			var cnt: int = 0
			var part_id: int = 0
			while comp_off != 0:
				var temp_buff: PackedByteArray = decode_task(PackedByteArray(buff_comp.slice(comp_off)), 0)
				
				if out_decomp:
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "_%04d" % id + "_%02d" % part_id + ".BIN", FileAccess.WRITE)
					out_file.store_buffer(temp_buff)
					out_file.close()
					
				var png: Image = make_img(temp_buff)
				png.save_png(folder_path + "/%s" % arc_name + "_%04d" % id + "_%02d" % part_id + ".PNG")
				
				cnt += 4
				part_id += 1
				comp_off = buff_comp.decode_u32(cnt)
			
			table += 8
			id += 1
	print_rich("[color=green]Finished![/color]")
	
	
func make_img(data: PackedByteArray) -> Image:
	var palette_count: int = data.decode_u32(0x4)
	var palette_offset: int = data.decode_u32(0x8)
	var num_parts: int = data.decode_u32(0xC)

	# Parse part offsets
	var part_offsets: Array[int] = []
	for i in range(num_parts):
		var part_offset: int = data.decode_u32(0x10 + i * 4)
		part_offsets.append(part_offset)

	var palette: PackedByteArray = PackedByteArray()
	for i in range(256):
		var off: int = palette_offset + i * 4
		var r: int = data.decode_u8(off + 0)
		var g: int = data.decode_u8(off + 1)
		var b: int = data.decode_u8(off + 2)
		var a: int = data.decode_u8(off + 3)
		a = int((a / 128.0) * 255.0)  # Expand alpha

		palette.append(r)
		palette.append(g)
		palette.append(b)
		palette.append(a)

	palette = ComFuncs.unswizzle_palette(palette, 32)

	# Read and decode image parts
	var images: Array[Image] = []
	var total_width: int = 0
	var total_height: int = 0

	for part_offset in part_offsets:
		var width: int = data.decode_u32(part_offset + 0x30)
		var height: int = data.decode_u32(part_offset + 0x34)
		var image_data_offset: int = part_offset + 0x70

		var img: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)

		for y in range(height):
			for x in range(width):
				var index_offset: int = image_data_offset + y * width + x
				var color_index: int = data.decode_u8(index_offset)
				var palette_index: int = color_index * 4

				var r: int = palette.decode_u8(palette_index + 0)
				var g: int = palette.decode_u8(palette_index + 1)
				var b: int = palette.decode_u8(palette_index + 2)
				var a: int = palette.decode_u8(palette_index + 3)

				img.set_pixel(x, y, Color8(r, g, b, a))

		images.append(img)
		total_width = max(total_width, width)
		total_height += height

	# Compose final image with parts stacked vertically
	var final_img: Image = Image.create_empty(total_width, total_height, false, Image.FORMAT_RGBA8)

	var y_offset: int = 0
	for img in images:
		var width: int = img.get_width()
		var height: int = img.get_height()

		for y in range(height):
			for x in range(width):
				final_img.set_pixel(x, y + y_offset, img.get_pixel(x, y))

		y_offset += height

	return final_img
	
	
func decode_task(src: PackedByteArray, start_offset: int, dst_size: int = 0xD2000) -> PackedByteArray: ##Size is guessed as its not clear where they are.
	var dst := PackedByteArray()
	dst.resize(dst_size)
	
	var src_size: int = src.size()
	var src_pos: int = start_offset
	var dst_pos: int = 0
	var control: int = src.decode_u8(src_pos)
	src_pos += 1

	while true:
		var control_bit_pos: int = 0
		while control_bit_pos < 8:
			if (control & 1) == 0:
				# Literal byte copy
				var byte_val: int = src.decode_u8(src_pos)
				src_pos += 1
				dst[dst_pos] = byte_val
				dst_pos += 1
			else:
				var token: int = src.decode_u8(src_pos)
				src_pos += 1
				if (token & 0x80) == 0:
					# Short back-reference (distance: 10 bits, length: 2-?, format A)
					var length: int = (token >> 2) + 3
					var offset_lo: int = src.decode_u8(src_pos)
					src_pos += 1
					var offset: int = ((token & 0x03) << 8) | offset_lo
					var copy_pos: int = dst_pos - offset
					for i in range(length):
						if dst_pos >= dst_size: return dst
						dst[dst_pos] = dst[copy_pos]
						dst_pos += 1
						copy_pos += 1
				elif (token & 0x40) == 0:
					# Medium back-reference (length in low 4 bits, offset in high 4 bits, format B)
					var length: int = ((token >> 4) & 0x03) + 2
					var offset: int = (token & 0x0F) + 1
					var copy_pos: int = dst_pos - offset
					for i in range(length):
						dst[dst_pos] = dst[copy_pos]
						dst_pos += 1
						copy_pos += 1
				else:
					# Format C - raw copy of (token & 0x3F) + 8 bytes
					if token == 0xFF:
						return dst.slice(0, dst_pos)
					var length: int = (token & 0x3F) + 8
					for i in range(length):
						dst[dst_pos] = src.decode_u8(src_pos)
						dst_pos += 1
						src_pos += 1
			control_bit_pos += 1
			control >>= 1

		# Refresh control byte
		if dst_pos >= dst_size:
			break
		control = src.decode_u8(src_pos)
		src_pos += 1

	return dst


func _on_file_load_accessdb_file_selected(path: String) -> void:
	accessdb = path


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_accessdb_pressed() -> void:
	file_load_accessdb.show()


func _on_load_bin_pressed() -> void:
	if not accessdb:
		OS.alert("Please load a table file first (ACCESSDB.BIN).")
		return
	file_load_bin.show()


func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp
