extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var remove_alpha: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractArc()
		selected_files.clear()
		chose_file = false
		chose_folder = false
		
		
func extractArc() -> void:
	for i in selected_files.size():
		parse_pidx_fsts(selected_files[i])
	
	print_rich("[color=green]Finished![/color]")
	
	
func parse_pidx_fsts(file_path: String):
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file")
		return

	# Check file signature
	var signature: String = file.get_buffer(4).get_string_from_ascii()
	if signature == "PIDX":
		# Read offsets and counts
		var packs_offset: int = file.get_32()
		var packs_count: int  = file.get_32()
		var info_offset: int  = file.get_32()
		var files_count: int  = file.get_32()
		var dummy: int  = file.get_32()
		var offset2: int  = file.get_32()
		var offset2_size: int  = file.get_32()
		var names_offset: int  = file.get_32()
		var names_size: int  = file.get_32()

		if files_count == 0:
			file.seek(info_offset)
			files_count = file.get_32()
			info_offset = file.get_position()
			var last_name_pos: int  = names_offset
			for i in files_count:
				file.seek((i * 4) + info_offset)
				var f_info: int  = file.get_32()
				file.seek(f_info + info_offset)
				dummy = file.get_32()
				var f_offset: int  = file.get_32()
				var f_size: int  = file.get_32()
				file.seek(last_name_pos)
				var f_name: String = file.get_line()
				last_name_pos = file.get_position()
				# skip first file always?
				if i == 0:
					file.seek(last_name_pos)
					f_name = file.get_line()
					last_name_pos = file.get_position()
				
				file.seek(f_offset)
				var buff: PackedByteArray = file.get_buffer(f_size)
				var bytes: int = buff.decode_u32(0)
				if bytes == 0x53545346:
					f_name += ".FST"
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		else:
			for i in files_count:
				file.seek((i * 0x18) + info_offset)
				var unk32_1: int = file.get_32()
				var f_name_off: int = file.get_32()
				var unk32_2: int = file.get_32()
				var f_offset: int = file.get_32()
				var f_dec_size: int = file.get_32()
				var f_comp_size: int = file.get_32()
				if f_comp_size == 0 and f_dec_size == 0:
					continue
				file.seek(names_offset + f_name_off)
				var f_name: String = file.get_line()
				file.seek(f_offset)
				var buff: PackedByteArray = file.get_buffer(f_comp_size)
				if f_comp_size != f_dec_size:
					buff = decompress_lz(buff)
					f_comp_size = f_dec_size # for printing
					var bytes: int = buff.decode_u32(0)
					if bytes == 0x20584554: #TEX/20
						var tga: PackedByteArray = parseTexture(buff)
						if tga.size() == 0:
							print_rich("[color=red]TGA output failed in %s![/color]" % f_name)
						else:
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
							out_file.store_buffer(tga)
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				
				print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name])
				
	elif signature == "FSTS":
		var dir: DirAccess = DirAccess.open(folder_path)
		var file_name: String
		
		var files_count: int = file.get_32()
		var info_offset: int = file.get_32()
		var names_offset: int = file.get_32()
		var names_size: int = file.get_32()
		var last_name_pos: int  = names_offset
		for i in files_count:
			file.seek((i * 0x10) + info_offset)
			var unk32: int = file.get_32() # file id?
			var f_offset: int = file.get_32()
			var f_comp_size: int = file.get_32()
			var f_dec_size: int = file.get_32()
			file.seek(last_name_pos)
			var f_name: String = file.get_line()
			last_name_pos = file.get_position()
			
			file.seek(f_offset)
			var buff: PackedByteArray = file.get_buffer(f_comp_size)
			if f_comp_size != f_dec_size:
				buff = decompress_lz(buff)
				f_comp_size = f_dec_size # for printing
				var bytes: int = buff.decode_u32(0)
				if bytes == 0x20584554: #TEX/20
					var tga: PackedByteArray = parseTexture(buff)
					if tga.size() == 0:
						print_rich("[color=red]TGA output failed in %s![/color]" % f_name)
					else:
						#dir.make_dir_recursive(f_name.get_base_dir())
						dir.make_dir_recursive(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name.get_base_dir())
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name + ".TGA", FileAccess.WRITE)
						out_file.store_buffer(tga)
			
			dir.make_dir_recursive(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name.get_base_dir())
			var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			
			print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name])
	else:
		print("Invalid header in %s" % file_path)
		file.close()
		return
			

	file.close()
	return

	
	
func parseTexture(img_dat: PackedByteArray) -> PackedByteArray:
	# todo TXF textures
	# todo some TEX files have 0x40 size palettes
	var tile_w: int = img_dat.decode_u16(0x38)
	var tile_h: int = img_dat.decode_u16(0x3A)
	var tile_size: int
	var f_w: int = img_dat.decode_u32(0x14)
	var f_h: int = img_dat.decode_u32(0x18)
	var tile_dat_off: int = 0x20
	var tile_hdr_size: int = img_dat.decode_u32(0x28)
	var num_tiles: int
	var img_size: int = img_dat.size()
	var has_pal: bool
	var pal: PackedByteArray
	var img_type: int
	var bpp: int
	var img_bpp: int
	
	# this image format sucks
	while true:
		
		# check if tile equal to file size
		tile_size = (img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A)) * 4 #RGBA
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RGBA[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 32
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
		tile_size = (img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A)) * 3 #RGB
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RGB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 24
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
		tile_size = (img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A)) * 2 #RB
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 16
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
		
		# check if tile equal to size INCLUDING header size *sigh*
		tile_size = img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A)  #RGBA
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RGBA[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 32
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
		tile_size = img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A) #RGB
		if tile_size == img_size:
			print_rich("[color=green]RGB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 24
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
		tile_size = img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A) #RB
		if tile_size == img_size:
			print_rich("[color=green]RB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 16
			has_pal = false
			f_h = tile_h
			f_w = tile_w
			break
			
		# check if final w/h equal to file size
		tile_size = (f_w * f_h) * 4 #RGBA
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RGBA[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 32
			has_pal = false
			break
		tile_size = (f_w * f_h) * 3 #RGB
		if tile_size == img_size - tile_dat_off - tile_hdr_size:
			print_rich("[color=green]RGB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 24
			has_pal = false
			break
			
		# check if final w/h equal to size INCLUDING header size
		tile_size = (f_w * f_h) * 4 #RGBA
		if tile_size == img_size:
			print_rich("[color=green]RGBA[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 32
			has_pal = false
			break
		tile_size = (f_w * f_h) * 3 #RGB
		if tile_size == img_size:
			print_rich("[color=green]RGB[/color]")
			img_type = 2
			bpp = 32
			img_bpp = 24
			has_pal = false
			break
			
		# check if tile equal to file size
		tile_size = img_dat.decode_u16(0x38) * img_dat.decode_u16(0x3A)
		if tile_size == img_size - tile_dat_off - tile_hdr_size - 0x400:
			print_rich("[color=green]GREY + PAL[/color]")
			img_type = 1
			bpp = 32
			img_bpp = 8
			has_pal = true
			f_h = tile_h
			f_w = tile_w
			break
			
		print_rich("[color=red]Unknown BPP![/color]")
		return PackedByteArray()
		
	
	var tga_hdr: PackedByteArray = ComFuncs.makeTGAHeader(has_pal, img_type, bpp, img_bpp, f_w, f_h)
	if has_pal:
		pal = ComFuncs.unswizzle_palette(img_dat.slice(img_size - 0x400), 32)
		pal = ComFuncs.rgba_to_bgra(pal)
		if remove_alpha:
			for i in range(0, pal.size(), 4):
				pal.encode_u8(i + 3, 0xFF)
		tga_hdr.append_array(pal)
		tga_hdr.append_array(img_dat.slice(tile_dat_off + tile_hdr_size))
		return tga_hdr
	img_dat = img_dat.slice(tile_dat_off + tile_hdr_size)
	if img_bpp == 16:
		img_dat = ComFuncs.convert_palette16_bgr_to_rgb(img_dat)
	if img_bpp == 24:
		img_dat = ComFuncs.rgb_to_bgr(img_dat)
	elif img_bpp == 32:
		img_dat = ComFuncs.rgba_to_bgra(img_dat)
		if remove_alpha:
			for i in range(0, img_dat.size(), 4):
				img_dat.encode_u8(i + 3, 0xFF)
	tga_hdr.append_array(img_dat)
	return tga_hdr
	
	
func decompress_lz(input_data: PackedByteArray) -> PackedByteArray:
	var output_buffer: PackedByteArray
	var output_size: int = input_data.decode_u32(4)
	var dic: PackedByteArray
	var header: PackedByteArray = input_data.slice(0, 8)
	var sp: int
	var v0: int
	var v1: int
	var a0: int
	var a1: int
	var a3: int = 0
	var t0: int
	var t1: int
	var t2: int
	var t3: int
	var t4: int = 0
	var t5: int
	var t6: int
	var t7: int
	var t8: int
	var t9: int = 0 #output buffer
	var do_decompress: bool = true
	var byte_0: int = header[0]
	var byte_1: int = header[1]
	var byte_2: int = header[2]
	var byte_3: int = header[3]
	
	output_buffer.resize(output_size)
	
	# Check if first 4 bytes indicate "ARZ"
	# "ARZ" (ASCII values: 0x41, 0x52, 0x5A)
	if byte_0 == 0x41 and byte_1 == 0x52 and byte_2 == 0x5A:
		# Validate byte 3
		if (byte_3 + 0xD0) & 0xFF < 0x0A:
			do_decompress = false  # Decrypt only
		elif (byte_3 + 0x9F) & 0xFF < 0x06:
			do_decompress = false  # Decrypt only
	# Alternate check if byte_0 is a space (0x20)
	if byte_0 == 0x20:
		if byte_1 == 0x33 and byte_2 == 0x3B:
			# Validate byte 3 in alternate case
			if (byte_3 + 0xD0) & 0xFF < 0x0A:
				do_decompress = true  # Decompress + decrypt
			elif (byte_3 + 0x9F) & 0xFF < 0x06:
				do_decompress = true  # Decompress + decrypt
	# Combine the next 4 bytes into a single value for further validation
	var combined_value: int = (
		(header[4] << 24) |
		(header[5] << 16) |
		(header[6] << 8) |
		header[7]
		)
		
	if combined_value <= 0:
		do_decompress = false  # Decrypt only
		
	if !do_decompress:
		# Do only decrypt
		var read_off: int = 8
		var out_off: int = 0
		while read_off < output_size:
			if (out_off >= output_size) or (read_off >= input_data.size()):
				break
			var byte: int = input_data.decode_u8(read_off) ^ 0x72
			output_buffer.encode_u8(out_off, byte)
			out_off += 1
			read_off += 1
		return output_buffer
		
	elif do_decompress:
		# Do decompression + decrypt compressed bytes
		t2 = 8
		t8 = 0
		t6 = 0xFEE
		t7 = 0
		dic.resize(0x1000)
		while t8 < output_size:
			t7 >>= 1
			v0 = t7 & 0x0100
			if v0 != 0:
				a1 = t7 & 1
				v0 = t0 < t2
				if a1 == 0:
					if v0 == 0:
						return output_buffer
					v0 = a3 + t2
					t2 += 1
					if v0 >= input_data.size():
						return output_buffer
					v1 = input_data.decode_u8(v0)
					a0 = t0 < t2
					if a0 == 0:
						return output_buffer
					t3 = v1 ^ 0x72
					v0 = a3 + t2
					t2 += 1
					if v0 >= input_data.size():
						return output_buffer
					v1 = input_data.decode_u8(v0)
					t5 = 0
					t1 = v1 ^ 0x72
					a0 = t1 & 0xF
					v0 = t1 & 0xF0
					t1 = a0 + 2
					v0 <<= 4
					v1 = t1 < a1
					t3 |= v0
					if v1 != 0:
						continue
					t4 = 0
					t5 = 0
					while t4 == 0:
						v0 = t3 + t5
						t5 += 1
						a0 = output_size
						v0 &= 0x0FFF
						v1 = sp + v0
						v0 = 0
						a0 = t8 < a0
						t4 = t1 < t5
						if a0 == 0:
							return output_buffer
						a1 = dic.decode_u8(v1)
						v1 = t9 + t8
						t8 += 1
						v0 = sp + t6
						t6 += 1
						dic.encode_s8(v0, a1)
						t6 &= 0x0FFF
						output_buffer.encode_s8(v1, a1)
					continue
				v1 = a3 + t2
				if v0 != 0:
					t2 += 1
					a0 = output_size
					v0 = 0
					if v1 >= input_data.size():
						return output_buffer
					a1 = input_data.decode_u8(v1)
					a0 = t8 < a0
					if a0 == 0:
						return output_buffer
					a1 ^= 0x72
					v1 = t9 + t8
					t8 += 1
					v0 = sp + t6
					t6 += 1
					dic.encode_s8(v0, a1)
					t6 &= 0x0FFF
					output_buffer.encode_s8(v1, a1)
					continue
			else:
				v0 = t0 < t2
				if v0 == 0:
					return output_buffer
				v1 = a3 + t2
				t2 += 1
				v0 = input_data.decode_u8(v1)
				a1 = v0 ^ 0x72
				t7 = a1 | 0xFF00
				a1 = t7 & 1
				v0 = t0 < t2
				if a1 == 0:
					if v0 == 0:
						return output_buffer
					v0 = a3 + t2
					t2 += 1
					v1 = input_data.decode_u8(v0)
					a0 = t0 < t2
					if a0 == 0:
						return output_buffer
					t3 = v1 ^ 0x72
					v0 = a3 + t2
					t2 += 1
					v1 = input_data.decode_u8(v0)
					t5 = 0
					t1 = v1 ^ 0x72
					a0 = t1 & 0xF
					v0 = t1 & 0xF0
					t1 = a0 + 2
					v0 <<= 4
					v1 = t1 < a1
					t3 |= v0
					if v1 != 0:
						continue
					t4 = 0
					t5 = 0
					while t4 == 0:
						v0 = t3 + t5
						t5 += 1
						a0 = output_size
						v0 &= 0x0FFF
						v1 = sp + v0
						v0 = 0
						a0 = t8 < a0
						t4 = t1 < t5
						if a0 == 0:
							return output_buffer
						a1 = dic.decode_u8(v1)
						v1 = t9 + t8
						t8 += 1
						v0 = sp + t6
						t6 += 1
						dic.encode_s8(v0, a1)
						t6 &= 0x0FFF
						output_buffer.encode_s8(v1, a1)
					continue
				v1 = a3 + t2
				if v0 != 0:
					t2 += 1
					a0 = output_size
					v0 = 0
					a1 = input_data.decode_u8(v1)
					a0 = t8 < a0
					if a0 == 0:
						return output_buffer
					a1 ^= 0x72
					v1 = t9 + t8
					t8 += 1
					v0 = sp + t6
					t6 += 1
					dic.encode_s8(v0, a1)
					t6 &= 0x0FFF
					output_buffer.encode_s8(v1, a1)
					continue
				
		return output_buffer
		
	push_error("Decompression error")
	return PackedByteArray()


func _on_load_dat_pressed() -> void:
	file_load_arc.visible = true


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	file_load_arc.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
