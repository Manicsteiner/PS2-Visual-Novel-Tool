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
				if f_name.get_extension() == "bnk":
					# Kinda dumb, but these aren't compressed
					f_comp_size = f_dec_size
				var buff: PackedByteArray = file.get_buffer(f_comp_size)
				if f_comp_size != f_dec_size and f_comp_size > 0:
					buff = decompress_lz(buff, f_comp_size)
					f_comp_size = f_dec_size # for printing
					var bytes: int = buff.decode_u32(0)
					if bytes == 0x20584554: #TEX/20
						var tga: PackedByteArray = parseTexture(buff)
						if tga.size() == 0:
							print_rich("[color=red]TGA output failed in %s![/color]" % f_name)
						else:
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
							out_file.store_buffer(tga)
					elif f_name.get_extension() == "agi":
						var img_type: int = buff.decode_u16(0x10)
						if img_type == 4 or img_type == 9 or img_type == 0xA:
							# 8 bit + 0x400 palette size
							var tga: PackedByteArray = parseAgi(buff)
							if tga.size() == 0:
								print_rich("[color=red]TGA output failed in %s![/color]" % f_name)
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
							out_file.store_buffer(tga)
						elif img_type == 8:
							# 4 bit + 0x40 palette size
							# some junk in the lower right corner of converted images
							var img_dat_off: int = buff.decode_u32(0x8)
							var f_w: int = buff.decode_u16(0x18)
							var f_h: int = buff.decode_u16(0x1A)
							var img_size: int = buff.decode_u32(0x1C)
							var img_dat: PackedByteArray = buff.slice(img_dat_off, img_size - img_dat_off)
							var new_pal: PackedByteArray = buff.slice(img_size) #ComFuncs.unswizzle_palette(buff.slice(img_size), 4)
							if remove_alpha:
								for a in range(0, new_pal.size(), 4):
									new_pal.encode_u8(a + 3, 0xFF)
							img_dat.append_array(new_pal)
							var png: Image = ComFuncs.convert_4bit_greyscale_to_8bit_image(img_dat, f_w, f_h, true)
							png.save_png(folder_path + "/%s" % f_name + ".PNG")
							print_rich("[color=green]GREY + PAL (4bit)[/color]")
						else:
							print_rich("[color=red]Unknown image in file %s![/color]" % f_name)
					elif f_name.get_extension() == "fac":
						# Make 8 bit + pal character images
						var images: Array[PackedByteArray] = parseFac(buff)
						for a in images.size():
							var tga: PackedByteArray = images[a]
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%02d" % a + ".TGA", FileAccess.WRITE)
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
				buff = decompress_lz(buff, f_comp_size)
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
				elif f_name.get_extension() == "agi":
					var img_type: int = buff.decode_u16(0x10)
					if img_type == 4 or img_type == 9:
						# 8 bit + 0x400 palette size
						var tga: PackedByteArray = parseAgi(buff)
						if tga.size() == 0:
							print_rich("[color=red]TGA output failed in %s![/color]" % f_name)
						dir.make_dir_recursive(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name.get_base_dir())
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name + ".TGA", FileAccess.WRITE)
						out_file.store_buffer(tga)
					elif img_type == 8:
						# 4 bit + 0x40 palette size
						var img_dat_off: int = buff.decode_u32(0x8)
						var f_w: int = buff.decode_u16(0x18)
						var f_h: int = buff.decode_u16(0x1A)
						var img_size: int = buff.decode_u32(0x1C)
						var img_dat: PackedByteArray = buff.slice(img_dat_off, img_size - img_dat_off)
						var new_pal: PackedByteArray = buff.slice(img_size) #ComFuncs.unswizzle_palette(buff.slice(img_size), 4)
						if remove_alpha:
							for a in range(0, new_pal.size(), 4):
								new_pal.encode_u8(a + 3, 0xFF)
						img_dat.append_array(new_pal)
						var png: Image = ComFuncs.convert_4bit_greyscale_to_8bit_image(img_dat, f_w, f_h, true)
						dir.make_dir_recursive(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name.get_base_dir())
						png.save_png(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name + ".PNG")
						print_rich("[color=green]GREY + PAL (4bit)[/color]")
					else:
						print_rich("[color=red]Unknown image in file %s![/color]" % f_name)
				elif f_name.get_extension() == "fac":
						# Make 8 bit + pal character images
						var images: Array[PackedByteArray] = parseFac(buff)
						for a in images.size():
							var tga: PackedByteArray = images[a]
							dir.make_dir_recursive(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name.get_base_dir())
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % file_path.get_file() + "/%s" % f_name + "_%02d" % a + ".TGA", FileAccess.WRITE)
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

	
func parseFac(data: PackedByteArray) -> Array[PackedByteArray]:
	# Make and return parts of character .fac images
	var out_arr: Array[PackedByteArray]
	var hdr_jump: int = 0
	var pos: int = 0
	
	# Find first IMAG bytes
	while pos < data.size():
		var bytes: int = data.decode_u32(pos)
		if bytes == 0x47414D49: # IMAG
			break
		hdr_jump = data.decode_u32(pos + 4)
		pos += hdr_jump
		
	# Find and append image data.
	var imag_bytes_pos: int = pos
	while imag_bytes_pos < data.size():
		var image_size: int = data.decode_u32(imag_bytes_pos + 4)
		var image_hdr_start: int = data.decode_u32(imag_bytes_pos + 0x14)
		var image_hdr_size: int = data.decode_u32(imag_bytes_pos + image_hdr_start)
		var image_data_start: int = data.decode_u32(imag_bytes_pos + image_hdr_start + 0x8)
		var width: int = data.decode_u16(imag_bytes_pos + image_hdr_start + 0x18)
		var height: int = data.decode_u16(imag_bytes_pos + image_hdr_start + 0x1A)
		var tga: PackedByteArray = ComFuncs.makeTGAHeader(true, 1, 32, 8, width, height)
		var img_dat: PackedByteArray = data.slice(imag_bytes_pos + image_hdr_size + image_data_start, (width * height) + imag_bytes_pos + image_hdr_size + image_data_start + 0x400)
		var pal_dat: PackedByteArray = ComFuncs.unswizzle_palette(img_dat.slice(img_dat.size() - 0x400), 32)
		pal_dat = ComFuncs.rgba_to_bgra(pal_dat)
		if remove_alpha:
			for i in range(0, pal_dat.size(), 4):
				pal_dat.encode_u8(i + 3, 0xFF)
		img_dat = img_dat.slice(0, -0x400)
		tga.append_array(pal_dat)
		tga.append_array(img_dat)
		out_arr.append(tga)
		
		imag_bytes_pos += image_size
		if imag_bytes_pos == img_dat.size():
			break
			
	print_rich("[color=green]FAC: GREY + PAL (8 bit)[/color]")
	return out_arr
	
	
func parseAgi(img_dat: PackedByteArray) -> PackedByteArray:
	var img_dat_off: int = img_dat.decode_u32(0x8)
	var img_type: int = img_dat.decode_u16(0x10)
	var f_w: int = img_dat.decode_u16(0x18)
	var f_h: int = img_dat.decode_u16(0x1A)
	var img_size: int = img_dat.decode_u32(0x1C)
	var pal: PackedByteArray
	
	if (f_w * f_h) * 2 == img_dat.size() - img_dat_off:
		# 16 bit, no pallete
		print_rich("[color=green]AGI: GREY + PAL (16 bit)[/color]")
		var tga_hdr: PackedByteArray = ComFuncs.makeTGAHeader(false, 2, 32, 16, f_w, f_h)
		var img: PackedByteArray = img_dat.slice(img_dat_off)
		img = ComFuncs.convert_palette16_bgr_to_rgb(img)
		tga_hdr.append_array(img)
		return tga_hdr
		
	elif (f_w * f_h) + img_dat_off == img_size:
		# 8 bit, 0x400 palette
		print_rich("[color=green]GREY + PAL (8 bit)[/color]")
		var tga_hdr: PackedByteArray = ComFuncs.makeTGAHeader(true, 1, 32, 8, f_w, f_h)
		pal = ComFuncs.unswizzle_palette(img_dat.slice(img_size), 32)
		pal = ComFuncs.rgba_to_bgra(pal)
		if remove_alpha:
			for i in range(0, pal.size(), 4):
				pal.encode_u8(i + 3, 0xFF)
		tga_hdr.append_array(pal)
		tga_hdr.append_array(img_dat.slice(img_dat_off, -0x400))
		return tga_hdr
	else:
		print_rich("[color=red]AGI: Unknown image bpp as width * height != image size.")
		return PackedByteArray()


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
	
	
func decompress_lz(input_data: PackedByteArray, comp_size: int) -> PackedByteArray:
	# todo: A very small amount of images decompress incorrectly in Galaxy Angel 2. Look at this later
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
	var dec_flag: int = -1
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
			dec_flag = 0  # Decrypt only
		elif (byte_3 + 0x9F) & 0xFF < 0x06:
			dec_flag = 0   # Decrypt only
	# Alternate check if byte_0 is a space (0x20)
	if byte_0 == 0x20:
		if byte_1 == 0x33 and byte_2 == 0x3B:
			# Validate byte 3 in alternate case
			if (byte_3 + 0xD0) & 0xFF < 0x0A:
				dec_flag = 1   # Decompress + decrypt
			elif (byte_3 + 0x9F) & 0xFF < 0x06:
				dec_flag = 1  # Decompress + decrypt
	# Combine the next 4 bytes into a single value for further validation
	var combined_value: int = (
		(header[7] << 24) |
		(header[6] << 16) |
		(header[5] << 8) |
		header[4]
		)
		
	if combined_value <= 0:
		push_error("An error likely occured during decompression")
		return input_data
		#dec_flag = 0  # Decrypt only
	if comp_size >= output_size:
		dec_flag = 0  # Decrypt only
		
	if dec_flag == 0:
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
		
	elif dec_flag == 1:
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
				if v1 >= input_data.size():
					return output_buffer
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
	
	# return input data as this is not compressed or encrypted
	return input_data


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
