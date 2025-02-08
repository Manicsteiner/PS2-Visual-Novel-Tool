extends Control

@onready var file_load_exe: FileDialog = $FILELoadEXE
@onready var file_load_sfs: FileDialog = $FILELoadSFS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_file: String
var exe_path: String
var remove_alpha: bool = true
var debug_out: bool = false


func _process(_delta: float) -> void:
	if folder_path and selected_file:
		extract_sfs()
		folder_path = ""
		selected_file = ""
		

func extract_sfs() -> void:
	var buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var exe_file: FileAccess
	var f_name: String
	var f_name_off: int
	var f_size: int
	var f_sector_size: int
	var f_offset: int
	var num_files: int
	var pos: int
	var entry_point: int
	var names_off: int
	var off_tbl: int
	var exe_name: String 
	
	if selected_file.get_file() == "RTDATA.SFS":
		if exe_path == "":
			if Main.game_type == Main.ROUTESPE:
				exe_name = "SLPS_257.27"
			OS.alert("Please load %s first." % exe_name)
			return
		
		in_file = FileAccess.open(selected_file, FileAccess.READ)
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
		if Main.game_type == Main.ROUTESPE:
			entry_point = 0xFFF80
			names_off = 0x003f2040 - entry_point # contains proper folder names
			off_tbl = 0x003e0ec0 - entry_point # contains just names but proper offsets and sizes
		
		var i: int = 0
		var cnt: int = 0
		while true:
			# Count offsets since there's no good way to determine table ends
			in_file.seek(i)
			f_offset = in_file.get_32()
			if f_offset == 0:
				num_files = cnt - 1
				break
			cnt += 1
			i += 4
		for file in range(0, num_files):
			exe_file.seek((file * 0x20) + off_tbl + 0x10)
			f_size = exe_file.get_32()
			f_sector_size = exe_file.get_32() * 0x800
			f_offset = exe_file.get_32() * 0x800
			
			exe_file.seek((file * 4) + names_off)
			f_name_off = exe_file.get_32() - entry_point
			
			exe_file.seek(f_name_off)
			f_name = exe_file.get_line()
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "%s" % f_name.get_base_dir())
			
			if f_name.get_extension() == "txx" or f_name.get_extension() == "txx0":
				print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
				if debug_out:
					out_file = FileAccess.open(folder_path + "%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					var tiles: Array[PackedByteArray] = make_txx_debug(buff)
					for tile in range(tiles.size()):
						out_file = FileAccess.open(folder_path + "%s" % f_name + "_%02d.dec" % tile, FileAccess.WRITE)
						out_file.store_buffer(tiles[tile])
						out_file.close()
				
				var png: Image = make_txx(buff)
				png.save_png(folder_path + "%s" % f_name + ".png")
				continue
			
			print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])

			out_file = FileAccess.open(folder_path + "%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
	else:
		in_file = FileAccess.open(selected_file, FileAccess.READ)
		
		var i: int = 0
		var cnt: int = 0
		while true:
			in_file.seek(i)
			f_offset = in_file.get_32()
			if f_offset == 0:
				num_files = cnt - 1
				break
			cnt += 1
			i += 4
		for file in range(0, num_files):
			in_file.seek(file * 4)
			var f_id: int = file
			f_offset = in_file.get_32() * 0x800
			f_size = (in_file.get_32() * 0x800) - f_offset
			if f_size == 0:
				f_size = in_file.get_length() - f_offset
			
			f_name = "%08d" % f_id
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			if buff.slice(0, 4).get_string_from_ascii() == "STER":
				f_name = buff.slice(0x20, 0x30).get_string_from_ascii() + ".STER"
			elif buff.slice(0, 4).get_string_from_ascii() == "VAGp":
				f_name = buff.slice(0x20, 0x30).get_string_from_ascii() + ".VAG"
			elif buff.decode_u32(0) == 0:
				f_name += ".ADPCM"
			else:
				f_name += ".BIN"
				
			print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
	print_rich("[color=green]Finished![/color]")
		

func make_txx(data: PackedByteArray) -> Image:
	var fp: int
	var img: Image
	var f_img: Image
	var img_part: PackedByteArray
	var arr: Array[Image]
	var part_size: int
	var num_img_parts: int = data.decode_u32(0) / 0x10
	var is_rgb: bool
	
	for part in range(0, num_img_parts):
		var part_start: int = data.decode_u32(part << 4)
		var part_width: int = data.decode_u32((part << 4) + 4) & 0xFFFF
		var part_height: int = data.decode_u32((part << 4) + 8) & 0xFFFF
		var part_comp_size: int = data.decode_u32((part << 4) + 0xC)
		
		var tile_w_check: int = data.decode_u32((part << 4) + 4)
		var tile_h_check: int = data.decode_u32((part << 4) + 8)
		if tile_w_check >= 0x40000000 or tile_h_check >= 0x40000000:
			push_error("Tile > 0x40000000")
		
		is_rgb = (part_comp_size & 0x80000000) != 0
		if is_rgb:
			fp = ((part_height + 0x3F) & 0xFFC0)
			part_size = (fp * part_width) * 3 #<< 1) + fp
			part_comp_size &= 0x7FFFFFFF
			img_part = decomp_lzss(data.slice(part_start, part_start + part_comp_size), part_comp_size, part_size)
			img = Image.create_from_data(part_width, part_height, false, Image.FORMAT_RGB8, img_part)
			arr.append(img)
		else:
			# Has pallete. At start of decompressed data, 0x400 size
			#fp = ((part_height + 0x3F) & 0xFFC0)
			#part_size = (fp * part_width) + 0x400
			part_size = (part_width * part_height) + 0x400
			img_part = decomp_lzss(data.slice(part_start, part_start + part_comp_size), part_comp_size, part_size)
			var palette: PackedByteArray = img_part.slice(0, 0x400)
			img_part = img_part.slice(0x400)
			if remove_alpha:
				for i in range(0, 0x400, 4):
					palette.encode_u8(i + 3, 255)
			palette = ComFuncs.unswizzle_palette(palette, 32)
			img = Image.create_empty(part_width, part_height, false, Image.FORMAT_RGBA8)
			for y in range(part_height):
				for x in range(part_width):
					var pixel_index: int = img_part[x + y * part_width]
					var r: int = palette[pixel_index * 4 + 0]
					var g: int = palette[pixel_index * 4 + 1]
					var b: int = palette[pixel_index * 4 + 2]
					var a: int = palette[pixel_index * 4 + 3]
					img.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
			arr.append(img)
			
	#var tile_size: int = 256
	var tile_size: int = data.decode_u32(4) & 0xFFFF
	var has_2col_flag: bool = (data.decode_u32(4) & 0x20000000) != 0 # TODO: There's also a 0x40 check in code but have yet to see an image with it
	var tiles_per_row: int
	var tiles_per_col: int
	# No idea what these flags do so some images will have to remain messed up
	if num_img_parts == 12 and !has_2col_flag:
		tiles_per_row = 3
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	elif num_img_parts == 6 and has_2col_flag:
		tiles_per_row = ceil(sqrt(num_img_parts))
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	elif has_2col_flag:
		tiles_per_row = 2
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	else:
		tiles_per_row = ceil(sqrt(num_img_parts))
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	var w: int = tiles_per_row * tile_size
	var h: int = tiles_per_col * tile_size
	var final_dims: Vector2i
	if num_img_parts == 2:
		final_dims = Vector2i(tile_size, tile_size * 2)  # One column, two rows
	else:
		final_dims = Vector2i(w, h)
	var final_w: int = final_dims.x
	var final_h: int = final_dims.y

	if is_rgb:
		f_img = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGB8)
	else:
		f_img = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGBA8)

	var img_i: int = 0
	for row in range(final_h / tile_size):
		for col in range(final_w / tile_size):
			if img_i >= num_img_parts:
				break  # Stop if all tiles are placed

			var dst_x: int = col * tile_size
			var dst_y: int = row * tile_size
			var tile_img: Image = arr[img_i]

			f_img.blend_rect(tile_img, Rect2i(0, 0, tile_size, tile_size), Vector2i(dst_x, dst_y))
			img_i += 1

	return f_img
	
	
func make_txx_debug(data: PackedByteArray) -> Array[PackedByteArray]:
	#var s2: int
	#var s4: int # width
	#var s5: int # height
	var fp: int
	var img: Image
	var img_part: PackedByteArray
	var arr: Array[PackedByteArray]
	var part_size: int
	var num_img_parts: int = data.decode_u32(0) / 0x10
	
	for part in range(0, num_img_parts):
		var part_start: int = data.decode_u32(part << 4)
		var part_width: int = data.decode_u32((part << 4) + 4) & 0xFFFF
		var part_height: int = data.decode_u32((part << 4) + 8) & 0xFFFF
		var part_comp_size: int = data.decode_u32((part << 4) + 0xC)
		
		if (part_comp_size & 0x80000000) != 0:
			fp = ((part_height + 0x3F) & 0xFFC0)
			part_size = (fp * part_width) * 3 #<< 1) + fp
			part_comp_size &= 0x7FFFFFFF
			img_part = decomp_lzss(data.slice(part_start, part_start + part_comp_size), part_comp_size, part_size)
			arr.append(img_part)
		else:
			#fp = ((part_height + 0x3F) & 0xFFC0)
			#part_size = (fp * part_width) + 0x400
			part_size = (part_width * part_height) + 0x400
			img_part = decomp_lzss(data.slice(part_start, part_start + part_comp_size), part_comp_size, part_size)
			arr.append(img_part)
			
	return arr
	
	
func decomp_lzss(buffer:PackedByteArray, zsize:int, size:int) -> PackedByteArray:
	var dec:PackedByteArray
	var dict:PackedByteArray
	var in_off:int = 0
	var out_off:int = 0
	var dic_off:int = 0x3ee
	var mask:int = 0
	var cb:int
	var b1:int
	var b2:int
	var len:int
	var loc:int
	var byte:int
	
	dict.resize(0x1000)
	dec.resize(size)
	while out_off < size:
		if mask == 0:
			cb = buffer[in_off]
			in_off += 1
			mask = 1

		if (mask & cb):
			dec[out_off] = buffer[in_off]
			dict[dic_off] = buffer[in_off]

			out_off += 1
			in_off += 1
			dic_off = (dic_off + 1) & 0x3ff
		else:
			b1 = buffer[in_off]
			b2 = buffer[in_off + 1]
			len = (b2 & 0x0f) + 3
			loc = b1| ((b2 & 0xf0) << 4)

			for b in range(len):
				byte = dict[(loc+b) & 0x3ff]
				if out_off+b >= size:
					return dec
				dec[out_off+b] = byte
				dict[(dic_off + b) & 0x3ff] = byte
			dic_off = (dic_off + len) & 0x3ff
			in_off += 2
			out_off += len
			
		mask = (mask << 1) & 0xFF

	return dec
	
	
func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_load_sfs_pressed() -> void:
	file_load_sfs.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_file_load_sfs_file_selected(path: String) -> void:
	selected_file = path
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
