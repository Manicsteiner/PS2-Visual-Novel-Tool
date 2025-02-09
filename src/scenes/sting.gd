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
	var step_mod: int
	
	if Main.game_type == Main.ROUTESPE:
		step_mod = 4
	elif Main.game_type == Main.TOHEART:
		step_mod = 0x10
		
	if (
		selected_file.get_file() == "RTDATA.SFS" or 
		selected_file.get_file() == "TOH_DATA.SFS"
		):
		if exe_path == "":
			if Main.game_type == Main.ROUTESPE:
				exe_name = "SLPS_257.27"
			elif Main.game_type == Main.TOHEART:
				exe_name = "SLPS_254.12"
			OS.alert("Please load %s first." % exe_name)
			return
		
		in_file = FileAccess.open(selected_file, FileAccess.READ)
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
		if Main.game_type == Main.ROUTESPE:
			entry_point = 0xFFF80
			names_off = 0x003f2040 - entry_point # contains proper folder names
			off_tbl = 0x003e0ec0 - entry_point # contains just names but proper offsets and sizes
		elif Main.game_type == Main.TOHEART:
			entry_point = 0xFFF80
			names_off = 0x00246a00 - entry_point
			off_tbl = 0x00231610 - entry_point
		
		var i: int = 0
		var cnt: int = 0
		while true:
			# Count offsets since there's no good way to determine table ends
			in_file.seek(i )
			f_offset = in_file.get_32()
			if f_offset == 0:
				num_files = cnt - 1
				break
			cnt += 1
			i += step_mod
		for file in range(0, num_files):
			exe_file.seek((file * 0x20) + off_tbl + 0x10)
			f_size = exe_file.get_32()
			f_sector_size = exe_file.get_32() * 0x800
			f_offset = exe_file.get_32() * 0x800
			
			exe_file.seek((file * 4) + names_off)
			f_name_off = exe_file.get_32() - entry_point
			
			exe_file.seek(f_name_off)
			f_name = exe_file.get_line()
			
			#if f_name.get_file() != "C0C01.tpp":
				#continue
			
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
			elif f_name.get_extension() == "tpp":
				print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
				if debug_out:
					out_file = FileAccess.open(folder_path + "%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					buff = lzss_toheart(buff)
					out_file = FileAccess.open(folder_path + "%s" % f_name + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					var tiles: Array[PackedByteArray] = make_tpp_debug(buff)
					for tile in range(tiles.size()):
						out_file = FileAccess.open(folder_path + "%s" % f_name + "_%02d.DEC" % tile, FileAccess.WRITE)
						out_file.store_buffer(tiles[tile])
						out_file.close()
					continue
				buff = lzss_toheart(buff)
				var png: Image = make_tpp(buff, f_name.get_file(), f_name.get_base_dir().erase(0))
				png.save_png(folder_path + "%s" % f_name + ".png")
				continue

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
			i += step_mod
		if step_mod == 4:
			for file in range(0, num_files):
				in_file.seek(file * step_mod)
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
		elif step_mod == 0x10:
			for file in range(0, num_files):
				in_file.seek(file * step_mod)
				var f_id: int = file
				f_size = in_file.get_32()
				f_sector_size = in_file.get_32() * 0x800
				f_offset = in_file.get_32() * 0x800
				
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
	
	
#func lzss_toheart_mips(compressed: PackedByteArray) -> PackedByteArray:
	#var out: PackedByteArray
	#var out_size: int = compressed.decode_u32(0)
	#var flag: int = compressed.decode_u32(4)
	#var comp_size: int = compressed.decode_u32(8)
	#var v0: int
	#var v1: int
	#var a0: int
	#var s0: int
	#var s1: int
	#var s2: int
	#var s3: int
	#var SP_40: int # out offset
	#var SP_50: int = 0 # in offset
	#
	#out.resize(out_size)
	#compressed = compressed.slice(0xC)
	#SP_40 = 0
	#SP_50 = 0
	#s3 = SP_40
	#var goto: int = 0x001F0580
	#while true:
		#match goto:
			#0x001F0580:
				#v1 = SP_50
				#v0 = SP_50 + 1
				#SP_50 = v0
				#v0 = compressed.decode_u8(v1)
				#v0 &= 0xFF # why
				#s0 = v0 & 0xFFFF
				#v0 = s0 & 0xFFFF
				#if v0 == 0:
					#break
					##goto = 0x001F0690
				#else:
					#v0 = s0 & 0xFFFF
					#v0 &= 0x80
					#if v0 == 0:
						#goto = 0x001F0670
					#else:
						#v0 = s0 & 0xFFFF
						#v0 &= 0x40
						#a0 = v0 << 2
						#v1 = SP_50
						#if v1 >= comp_size:
							#return out
						#v0 = v1 + 1
						#SP_50 = v0
						#v0 = compressed.decode_u8(v1)
						#v0 &= 0xFF
						#v0 = (a0 + v0) & 0xFFFFFFFF
						#v0 &= 0xFFFF
						#s2 = v0 & 0xFFFF
						#v0 = s0 & 0xFFFF
						#v0 &= 0x3F
						#v0 += 3
						#v0 &= 0xFFFF
						#s0 = v0 & 0xFFFF
						#v1 = SP_40
						#v0 = s2 & 0xFFFF
						#v0 = (v1 - v0) & 0xFFFFFFFF
						#s1 = v0 - 1
						## 001F0630
						#v1 = s0
						#v0 = v1 - 1
						#s0 = v0 & 0xFFFF
						#while v1 != 0:
							#v0 = s1
							#if v0 >= out_size:
								#return out
							#s1 = v0 + 1
							#a0 = out.decode_u8(v0)
							#v1 = SP_40
							#v0 = v1 + 1
							#SP_40 = v0
							#out.encode_u8(v1, a0)
							#v1 = s0
							#v0 = v1 - 1
							#s0 = v0 & 0xFFFF
						#goto = 0x001F0580
			#0x001F0650:
				#v1 = SP_50
				#v0 = v1 + 1
				#SP_50 = v0
				#a0 = compressed.decode_u8(v1)
				#v1 = SP_40
				#v0 = v1 + 1
				#SP_40 = v0
				#out.encode_u8(v1, a0)
				#goto = 0x001F0670
			#0x001F0670:
				#v1 = s0
				#v0 = v1 - 1
				#s0 = v0 & 0xFFFF
				#if v1 != 0:
					#goto = 0x001F0650
				#else:
					#goto = 0x001F0580
					#
	#return out
	
	
func lzss_toheart(compressed: PackedByteArray) -> PackedByteArray:
	var decompressed_size: int = compressed.decode_u32(0)
	var flag: int = compressed.decode_u32(4)
	var compressed_size: int = compressed.decode_u32(8)
	var output: PackedByteArray
	var output_offset: int = 0
	var input_offset: int = 0
	var match_offset: int
	var match_length: int
	var reference_position: int
	
	output.resize(decompressed_size)
	compressed = compressed.slice(0xC) # Skip header

	while true:
		var control_byte: int = compressed.decode_u8(input_offset)
		input_offset += 1
		
		if control_byte == 0:
			break
		
		if (control_byte & 0x80) != 0: 
			# Dictionary match case
			var match_high: int = (control_byte & 0x40) << 2
			if input_offset >= compressed_size:
				return output
				
			var match_low: int = compressed.decode_u8(input_offset)
			input_offset += 1
			match_offset = (match_high + match_low) & 0xFFFF
			
			match_length = (control_byte & 0x3F) + 3
			reference_position = output_offset - match_offset - 1
			
			# Copy matched bytes from output buffer
			for _i in range(match_length):
				if reference_position >= decompressed_size:
					return output
					
				var byte_value: int = output.decode_u8(reference_position)
				output.encode_u8(output_offset, byte_value)
				
				reference_position += 1
				output_offset += 1
		else:
			# Literal byte case
			for _i in range(control_byte):
				var byte_value: int = compressed.decode_u8(input_offset)
				input_offset += 1
				
				output.encode_u8(output_offset, byte_value)
				output_offset += 1

	return output
	
	
func make_tpp(data: PackedByteArray, image_name: String, base_dir: String) -> Image:
	# This format sucks. Different flags likely represent certain things but I'll be damned.
	
	if base_dir == "etc": # these folders is has a bunch of weirdly sized tiles
		push_error("Skipping folder 'etc' and 'sam' as these have different tile sizes")
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	
	var num_img_parts: int = data.decode_u32(0)
	var f_img: Image
	var img: Image
	var img_part: PackedByteArray
	var palette: PackedByteArray
	var arr: Array[Image]
	var has_pal: bool = data.decode_u32(0x10)  != 0
	var tile_size_flag: int = data.decode_u32(0x2C)
	
	if !has_pal:
		# RGBA
		for part in range(0, num_img_parts):
			var part_start: int = data.decode_u32((part * 0x20) + 0x10 + 4)
			var part_width: int
			var part_height: int
			if tile_size_flag == 2:
				part_width = 128
				part_height = 128
			elif tile_size_flag == 1:
				part_width = 256
				part_height = 128
			else:
				part_width = 256
				part_height = 256
			var part_size: int = (part_width * part_height) << 2
			img_part = data.slice(part_start + 0x20, part_start + 0x20 + part_size)
			if remove_alpha:
				for i in range(0, part_size, 4):
					img_part.encode_u8(i + 3, 255)
				
			img = Image.create_from_data(part_width, part_height, false, Image.FORMAT_RGBA8, img_part)
			arr.append(img)
	else:
		if base_dir == "ending":
			# 4 bit + palette
			for part in range(0, num_img_parts):
				var part_pal_start: int = data.decode_u32((part * 0x20) + 0x10)
				var part_start: int = data.decode_u32((part * 0x20) + 0x10 + 4)
				var part_width: int
				var part_height: int
				if image_name.contains("spic"):
					part_width = 256
					part_height = 256
				else:
					part_width = 512
					part_height = 512
					
				var part_size: int = (part_width * part_height)
				palette = data.slice(part_pal_start + 0x20, part_pal_start + 0x20 + 0x40)
				img_part = data.slice(part_start + 0x20, part_start + 0x20 + part_size)
				for i in range(0, 0x40, 2):
					var bgr555: int = data.decode_u16(0x20 + i)
					var r: int = ((bgr555 >> 10) & 0x1F) * 8
					var g: int = ((bgr555 >> 5) & 0x1F) * 8
					var b: int = (bgr555 & 0x1F) * 8
					palette.append(r)
					palette.append(g)
					palette.append(b)
					palette.append(255)
				img = Image.create_empty(part_width, part_height, false, Image.FORMAT_RGBA8)
				for y in range(part_height):
					for x in range(0, part_width, 2):  # Two pixels per byte
						var byte_index: int  = (x + y * part_width) / 2
						var byte_value: int  = img_part[byte_index]
						# Extract two 4-bit indices (little-endian order)
						var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
						var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)
						# Set first pixel
						var r1: int = palette[pixel_index_1 * 4 + 0]
						var g1: int = palette[pixel_index_1 * 4 + 1]
						var b1: int = palette[pixel_index_1 * 4 + 2]
						var a1: int = palette[pixel_index_1 * 4 + 3]
						img.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))
						# Set second pixel (only if within bounds)
						if x + 1 < part_width:
							var r2: int = palette[pixel_index_2 * 4 + 0]
							var g2: int = palette[pixel_index_2 * 4 + 1]
							var b2: int = palette[pixel_index_2 * 4 + 2]
							var a2: int = palette[pixel_index_2 * 4 + 3]
							img.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
				arr.append(img)
		else:
			# 8 bit + pal
			for part in range(0, num_img_parts):
				var part_pal_start: int = data.decode_u32((part * 0x20) + 0x10)
				var part_start: int = data.decode_u32((part * 0x20) + 0x10 + 4)
				var part_width: int
				var part_height: int
				if tile_size_flag == 2 or image_name == "C2901.tpp": # why do these formats suck
					part_width = 128
					part_height = 128
				elif base_dir == "sam":
					part_width = 256
					part_height = 128
				else:
					part_width = 256
					part_height = 256
				var part_size: int = (part_width * part_height)
				palette = data.slice(part_pal_start + 0x20, part_pal_start + 0x20 + 0x400)
				img_part = data.slice(part_start + 0x20, part_start + 0x20 + part_size)
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
	
	var tile_size: int
	var tiles_per_row: int
	var tiles_per_col: int
	# Likely a better way to do this.
	if tile_size_flag == 2 or image_name == "C2901.tpp" and base_dir != "ending":
		tile_size = 128
		if image_name.begins_with("AL_"):
			tiles_per_row = 1
			tiles_per_col = num_img_parts
		elif num_img_parts == 8:
			tiles_per_row = 4
			tiles_per_col = 4
		elif num_img_parts == 9:
			tiles_per_row = 3
			tiles_per_col = 4
		elif num_img_parts == 0xC:
			tiles_per_row = 4
			tiles_per_col = 5
		elif num_img_parts == 0x14:
			tiles_per_row = 4
			tiles_per_col = 6
		else:
			tiles_per_row = ceil(sqrt(num_img_parts))
			tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	elif tile_size_flag == 1:
		tile_size = 256
		tiles_per_row = ceil(sqrt(num_img_parts))
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	else:
		if base_dir == "ending":
			tile_size = 512
		else:
			tile_size = 256
		tiles_per_row = ceil(sqrt(num_img_parts))
		tiles_per_col = ceil(float(num_img_parts) / tiles_per_row)
	var w: int = tiles_per_row * tile_size
	var h: int = tiles_per_col * tile_size
	var final_dims: Vector2i
	if image_name == "C2901.tpp":
		final_dims = Vector2i(num_img_parts * tile_size / 4, num_img_parts * tile_size / 4)
	elif image_name.contains("AL_"):
		final_dims = Vector2i(num_img_parts * tile_size, 128)
	elif base_dir == "ending":
		if image_name.contains("spic"):
			final_dims = Vector2i(512, 256)
		else:
			final_dims = Vector2i(512, 512)
	elif tile_size_flag == 2 and num_img_parts == 0xC:
		final_dims = Vector2i(512, 512)
	elif tile_size_flag == 2 and num_img_parts == 0x14:
		final_dims = Vector2i(640, 512)
	elif tile_size_flag == 1 and base_dir == "visual":
		final_dims = Vector2i(w, h)
	elif tile_size_flag == 1:
		final_dims = Vector2i(tile_size * 2, tile_size * 2)
	else:
		final_dims = Vector2i(w, h)
	var final_w: int = final_dims.x
	var final_h: int = final_dims.y

	f_img = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGBA8)

	var img_i: int = 0
	if base_dir == "visual" and tile_size_flag == 1:
		for row in range(tiles_per_col):
			for col in range(tiles_per_row):
				if img_i >= num_img_parts:
					break
				var dst_x: int = col * tile_size
				var dst_y: int = row * tile_size
				var tile_img: Image = arr[img_i]
				f_img.blend_rect(tile_img, Rect2i(0, 0, tile_size, tile_size), Vector2i(dst_x, dst_y))
				img_i += 1
	elif tile_size_flag == 2 or tile_size_flag == 1 or image_name == "C2901.tpp":
		for row in range(tiles_per_col):
			for col in range(tiles_per_row):
				if img_i >= num_img_parts:
					break
				var dst_y: int = col * tile_size
				var dst_x: int = row * tile_size
				var tile_img: Image = arr[img_i]
				f_img.blend_rect(tile_img, Rect2i(0, 0, tile_size, tile_size), Vector2i(dst_x, dst_y))
				img_i += 1
	else:
		for row in range(tiles_per_col):
			for col in range(tiles_per_row):
				if img_i >= num_img_parts:
					break
				var dst_x: int = col * tile_size
				var dst_y: int = row * tile_size
				var tile_img: Image = arr[img_i]
				f_img.blend_rect(tile_img, Rect2i(0, 0, tile_size, tile_size), Vector2i(dst_x, dst_y))
				img_i += 1
	return f_img
	
	
func make_tpp_debug(data: PackedByteArray) -> Array[PackedByteArray]:
	var num_img_parts: int = data.decode_u32(0)
	var img_part: PackedByteArray
	var palette: PackedByteArray
	var arr: Array[PackedByteArray]
	var has_pal: bool = data.decode_u32(0x10)  != 0
	var tile_size_flag: int = data.decode_u32(0x2C)
	
	if !has_pal:
		for part in range(0, num_img_parts):
			var part_start: int = data.decode_u32((part * 0x20) + 0x10 + 4)
			var part_width: int
			var part_height: int
			if tile_size_flag == 2:
				part_width = 128
				part_height = 128
			else:
				part_width = 256
				part_height = 256
			var part_size: int = (part_width * part_height) * 3
			img_part = data.slice(part_start, part_start + 0x20 + part_size)
			arr.append(img_part)
	else:
		# 8 bit + pal
		for part in range(0, num_img_parts):
			var part_pal_start: int = data.decode_u32((part * 0x20) + 0x10)
			var part_start: int = data.decode_u32((part * 0x20) + 0x10 + 4)
			var part_width: int
			var part_height: int
			if tile_size_flag == 2:
				part_width = 128
				part_height = 128
			else:
				part_width = 256
				part_height = 256
			var part_size: int = (part_width * part_height)
			palette = data.slice(part_pal_start, part_pal_start + 0x20 + 0x400)
			img_part = data.slice(part_start, part_start + 0x20 + part_size)
			arr.append(palette)
			arr.append(img_part)
	return arr
		
		
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
