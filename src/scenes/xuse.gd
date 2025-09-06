extends Control

@onready var file_load_ard: FileDialog = $FILELoadARD
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var selected_files: PackedStringArray
var folder_path: String


func _ready() -> void:
	file_load_ard.filters = ["*.ARD"]
	

func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract_ard()
		selected_files.clear()
		folder_path = ""


func extract_ard() -> void:
	for file in range(0, selected_files.size()):
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		var base_dir: String = "%s/%s" % [folder_path, arc_name]
		
		in_file.seek(0)
		if in_file.get_buffer(8).get_string_from_ascii() != "DARC0091":
			OS.alert("%s doesn't have a valid DARC header!" % arc_name)
			continue
			
		in_file.seek(12)
		var num_files: int = in_file.get_32()
		var dir: DirAccess = DirAccess.open(folder_path)
		
		for i in range(num_files):
			in_file.seek((i * 8) + 16)
			
			var f_off: int = in_file.get_32()
			var f_size: int = in_file.get_32()
			if f_off == 0 or f_size == 0: continue
			
			var f_name: String = "%08d" % i
			
			print("%08X %08X %s" % [f_off, f_size, folder_path + "/%s" % arc_name + "/%s" % f_name])
			
			in_file.seek(f_off)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			dir.make_dir_recursive(arc_name)
			
			if buff.slice(0, 3).get_string_from_ascii() == "SZ3":
				var slice_off: int = ComFuncs.swapNumber(buff.decode_u32(12), "32")
				var dec_size: int = ComFuncs.swapNumber(buff.decode_u32(4), "32")
				var comp_size: int = ComFuncs.swapNumber(buff.decode_u32(8), "32") - slice_off
				
				buff = decompLZSS_mod(buff.slice(slice_off), comp_size, dec_size)
				
				if buff.slice(0, 2).get_string_from_ascii() == "BM":
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".SZ3.BMP", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				elif buff.slice(0, 3).get_string_from_ascii() == "Eb0":
					var png: Image = make_indexed_image(buff)
					png.save_png(folder_path + "/%s" % arc_name + "/%s" % f_name + ".SZ3.PNG")
					
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".SZ3.DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				else:
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".SZ3.DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
			elif buff.slice(0, 4).get_string_from_ascii() == "VAGp":
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".VAG", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			else:
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
	print_rich("[color=green]Finished![/color]")
	
	
func make_indexed_image(data: PackedByteArray) -> Image:
	var format: int = ComFuncs.swapNumber(data.decode_u16(4), "16")
	var bpp: int = ComFuncs.swapNumber(data.decode_u16(6), "16")
	if bpp != 8: push_error("bpp isn't 8")
	var width: int = ComFuncs.swapNumber(data.decode_u16(8), "16")
	var height: int = ComFuncs.swapNumber(data.decode_u16(10), "16")
	if format == 1:
		var pal_off: int = ComFuncs.swapNumber(data.decode_u32(12), "32")

		var palette_buf: PackedByteArray = data.slice(pal_off, pal_off + 0x400)
		for i in range(0, palette_buf.size(), 4):
			var a: int = int((palette_buf.decode_u8(i + 3) / 128.0) * 255.0)
			palette_buf.encode_u8(i + 3, a)

		var img_data_off: int = pal_off + 0x400
		var img_data_size: int = width * height
		var img_data: PackedByteArray = data.slice(img_data_off, img_data_off + img_data_size)

		var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)

		for y in range(height):
			for x in range(width):
				var idx: int = img_data.decode_u8(y * width + x)
				var color: Color = Color8(
					palette_buf.decode_u8(idx * 4 + 0),  # R
					palette_buf.decode_u8(idx * 4 + 1),  # G
					palette_buf.decode_u8(idx * 4 + 2),  # B
					palette_buf.decode_u8(idx * 4 + 3)   # A
				)
				img.set_pixel(x, y, color)
		return img
	elif format == 3:
		print_rich("[color=yellow]format == 3, unknown format?")
		
		var img_off: int = ComFuncs.swapNumber(data.decode_u32(12), "32")
		var img_data_size: int = width * height
		var img_data: PackedByteArray = data.slice(img_off, img_off + img_data_size)
		var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
		for y in range(height):
			for x in range(width):
				var v: int = img_data.decode_u8(y * width + x)
				var l: int = (v >> 4) * 17   # 4-bit luminance expanded to 0-255
				var a: int = (v & 0xF) * 17  # 4-bit alpha expanded to 0-255
				img.set_pixel(x, y, Color8(l, l, l, a))
		return img
	else:
		push_error("Unknown format %04X" % format)
		
	return Image.create_empty(1, 1, false, Image.FORMAT_L8)
	
	
func decompLZSS_mod(buffer: PackedByteArray, zsize: int, dsize: int, dic_off: int = 0xFEE) -> PackedByteArray:
	var dec: PackedByteArray
	var dict: PackedByteArray
	var in_off: int = 0
	var out_off: int = 0
	var mask: int = 0
	var cb: int
	
	dict.resize(0x1000)
	dec.resize(dsize)
	mask = 0
	while out_off < dsize:
		if mask == 0:
			cb = buffer[in_off]
			in_off += 1
			mask = 0x80  # start with high bit

		if cb & mask:
			# literal
			var val: int = buffer[in_off]
			in_off += 1
			dec[out_off] = val
			dict[dic_off] = val
			dic_off = (dic_off + 1) & 0xFFF
			out_off += 1
		else:
			var b1: int = buffer[in_off]
			var b2: int = buffer[in_off + 1]
			in_off += 2

			var length: int = (b2 & 0x0F) + 3
			var offset: int = b1 | ((b2 & 0xF0) << 4)

			for i in range(length):
				var val: int = dict[(offset + i) & 0xFFF]
				dec[out_off] = val
				dict[dic_off] = val
				dic_off = (dic_off + 1) & 0xFFF
				out_off += 1
				if out_off >= dsize:
					return dec

		mask >>= 1

	return dec


func _on_load_ard_pressed() -> void:
	file_load_ard.show()


func _on_file_load_ard_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
