extends Control

@onready var interlude_load_pak = $InterludeLoadPAK
@onready var interlude_load_folder = $InterludeLoadFOLDER
@onready var remove_alpha_button: CheckBox = $VBoxContainer/removeAlphaButton
@onready var output_combined: CheckBox = $VBoxContainer/outputCombined
@onready var png_out_toggle: CheckBox = $VBoxContainer/pngOutToggle
@onready var out_debug_button: CheckBox = $VBoxContainer/outDebugButton

var chose_folder: bool = false
var folder_path: String
var selected_files: PackedStringArray

var out_png: bool = true
var output_combined_image: bool = true
var remove_alpha: bool = false
var debug_out: bool = false

# XOR keys for width and height of images in Interlude and Sentimental Prelude

const width_key: int = 0x4355
const height_key: int = 0x5441

# Lookup table for other Cybelle compression format

var lookup_table: PackedByteArray

func _ready() -> void:
	if Main.game_type != Main.INTERLUDE or Main.game_type != Main.SENTIMENTALPRELUDE:
		make_lookup_tables()
		remove_alpha_button.hide()
		output_combined.hide()
		png_out_toggle.hide()
		out_debug_button.show()
	else:
		out_debug_button.hide()
		

func _process(_delta):
	if Main.game_type == Main.INTERLUDE or Main.game_type == Main.SENTIMENTALPRELUDE:
		if selected_files and chose_folder:
			interludeMakeFiles()
			chose_folder = false
			selected_files.clear()
	else:
		if selected_files and chose_folder:
			cybellePakExtract()
			chose_folder = false
			selected_files.clear()
	
	
func interludeMakeFiles() -> void:
	var file: FileAccess
	var file_data001: FileAccess
	var file_data002: FileAccess
	var new_file: FileAccess
	var header_file: FileAccess
	var file_name: String
	var start_off: int
	var file_size: int
	var mem_file: PackedByteArray
	var mem_file_len: int
	var k: int
	var byte: int
	var initial_key: int
	var key_1_lower: int
	var key_1: int
	var key_2: int
	var key_3: int
	var max_size: int
	var png_out: Image
	var ogg_bytes: int
	var archive_id: String
	var png_buffer: PackedByteArray
	var width: int
	var height: int
	var unk_bytes: int
	var mem_file_off: int
	
	max_size = 0x3CA00 # Max header size to assume.
	for usr_file in selected_files.size():
		file = FileAccess.open(selected_files[usr_file], FileAccess.READ)
		file_name = selected_files[usr_file].get_file()
		if file_name == "DATA.IMG":
			file_data001 = FileAccess.open(selected_files[usr_file].get_basename() + ".001", FileAccess.READ)
			file_data002 = FileAccess.open(selected_files[usr_file].get_basename() + ".002", FileAccess.READ)
			if (file_data001 == null) or (file_data002 == null):
				OS.alert("DATA.001 and DATA.002 must be in the same directory as DATA.IMG")
				continue
		
		initial_key = 0x6E86CC2E
		key_1 = initial_key
		mem_file.resize(max_size) # Assumed header size.
		
		for j in range(0, max_size):
			file.seek(j)
			byte = file.get_8()
			key_1_lower = key_1 & 0xFF
			key_2 = (key_1 << 1) & 0xFFFFFFFF
			key_3 = (key_1 >> 31) & 0xFFFFFFFF
			key_1 = key_2 | key_3
			byte = byte + key_1_lower
			mem_file.encode_s8(j, byte)
			if j & 0x5 != 0:
				#Unsure how to determine header end
				if (file.get_32()) == 0:
					mem_file_len = file.get_position() - 4
					mem_file.resize(mem_file_len)
					break
				key_2 = key_1 << 1
				key_3 = key_1 >> 31
				key_1 = key_2 | key_3
		
		header_file = FileAccess.open(folder_path + "/%s" % file_name + ".HED", FileAccess.WRITE_READ)
		header_file.store_buffer(mem_file)
		mem_file.clear()
		
		k = 0
		while k < mem_file_len:
			header_file.seek(k)
			file_name = header_file.get_line()
			if file_name == "":
				print("Assumed header ending at 0x%X" % header_file.get_position())
				break
			header_file.seek(k + 0xC)
			start_off = header_file.get_32()
			header_file.seek(k + 0x10)
			file_size = header_file.get_32()
			
			mem_file.resize(file_size)
			
			#DATA.IMG
			if (file_size & 0xFF000000) == 0x00000000:
				archive_id = selected_files[usr_file]
				file_size &= 0x00FFFFFF
				file.seek(start_off)
				mem_file = file.get_buffer(file_size)
			#DATA.001
			elif (file_size & 0xFF000000) == 0x01000000:
				archive_id = "DATA.001"
				file_size &= 0x00FFFFFF
				file_data001.seek(start_off)
				mem_file = file_data001.get_buffer(file_size)
			#DATA.002
			elif (file_size & 0xFF000000) == 0x02000000:
				archive_id = "DATA.002"
				file_size &= 0x00FFFFFF
				file_data002.seek(start_off)
				mem_file = file_data002.get_buffer(file_size)
			
			if file_name.get_extension() == "VTV" and out_png: # Check for type 1 image formats with vorbis headers
				ogg_bytes = mem_file.decode_u32(0)
				if ogg_bytes == 0x5367674F: #OggS
					# Begin checks for multiple images
					var png_images: Array[Image]
					
					mem_file_off = 0xA8 #always start of first image
					width = mem_file.decode_u16(mem_file_off) ^ width_key
					height = mem_file.decode_u16(mem_file_off + 2) ^ height_key
					unk_bytes = mem_file.decode_u32(mem_file_off + 4)
					png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
					png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
					if !output_combined_image:
						png_out.save_png(folder_path + "/%s" % file_name + ".0" + ".PNG")
					png_images.append(png_out)
					png_buffer.clear()
					
					#check for second file
					if mem_file.decode_u32(0x9C) != 0:
						mem_file_off = mem_file.decode_u32(0x98) + 0xA8 #get first image ending
						width = mem_file.decode_u16(mem_file_off) ^ width_key
						height = mem_file.decode_u16(mem_file_off + 2) ^ height_key
						unk_bytes = mem_file.decode_u32(mem_file_off + 4)
						png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
						png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
						if !output_combined_image:
							png_out.save_png(folder_path + "/%s" % file_name + ".1" + ".PNG")
						png_images.append(png_out)
						png_buffer.clear()
						
					#check for third file
					if mem_file.decode_u32(0xA0) != 0:
						mem_file_off = (mem_file.decode_u32(0x98) + 0xA8) + mem_file.decode_u32(0x9C)
						width = mem_file.decode_u16(mem_file_off) ^ width_key
						height = mem_file.decode_u16(mem_file_off + 2) ^ height_key
						unk_bytes = mem_file.decode_u32(mem_file_off + 4)
						png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
						png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
						if !output_combined_image:
							png_out.save_png(folder_path + "/%s" % file_name + ".2" + ".PNG")
						png_images.append(png_out)
						png_buffer.clear()
						
					#check for forth file
					if mem_file.decode_u32(0xA4) != 0:
						mem_file_off = ((mem_file.decode_u32(0x98) + 0xA8) + mem_file.decode_u32(0x9C)) + mem_file.decode_u32(0xA0)
						width = mem_file.decode_u16(mem_file_off) ^ width_key
						height = mem_file.decode_u16(mem_file_off + 2) ^ height_key
						unk_bytes = mem_file.decode_u32(mem_file_off + 4)
						png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
						png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
						if !output_combined_image:
							png_out.save_png(folder_path + "/%s" % file_name + ".3" + ".PNG")
						png_images.append(png_out)
						png_buffer.clear()
					
					if output_combined_image and png_images.size() > 1:
						 # Store the last element
						var last_entry: Image = png_images[png_images.size() - 1]
						# Shift all elements down by one
						for i in range(png_images.size() - 1, 0, -1):
							png_images[i] = png_images[i - 1]
						# Move the last element to the first position
						png_images[0] = last_entry
						png_out = ComFuncs.combine_images_vertically(png_images)
						png_out.save_png(folder_path + "/%s" % file_name + ".FULL" + ".PNG")
					else:
						png_out = png_images[0]
						png_out.save_png(folder_path + "/%s" % file_name + ".FULL" + ".PNG")
						
				elif mem_file.decode_u32(0) == mem_file.size() - 0x10: #type 2 format where 0x0 is file size
					mem_file_off = 0x10
					width = mem_file.decode_u16(mem_file_off)
					height = mem_file.decode_u16(mem_file_off + 2)
					unk_bytes = mem_file.decode_u32(mem_file_off + 4)
					png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
					png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
					png_out.save_png(folder_path + "/%s" % file_name + ".PNG")
					png_buffer.clear()
					
							
			elif file_name.ends_with(".GCD") and out_png:
				if file_name == "REGION.GCD":
					printerr("Skipping REGION.GCD as it causes the decompresser to screw up for some reason")
				else:
					mem_file_off = 0
					width = mem_file.decode_u16(0x0)
					height = mem_file.decode_u16(0x2)
					unk_bytes = mem_file.decode_u32(0x4)
					
					png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
							
					png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
					png_out.save_png(folder_path + "/%s" % file_name + ".PNG")
					png_buffer.clear()
					
			elif file_name.get_extension() == "AVT" and out_png: #for Sentimental Prelude
					mem_file_off = 0xA8
					width = mem_file.decode_u16(mem_file_off) ^ width_key
					height = mem_file.decode_u16(mem_file_off + 2) ^ height_key
					unk_bytes = mem_file.decode_u32(mem_file_off + 4)
					png_buffer = interludeDecodeImage(mem_file, width, height, unk_bytes, mem_file_off)
					
					png_out = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, png_buffer)
					png_out.save_png(folder_path + "/%s" % file_name + ".PNG")
					png_buffer.clear()
				
			print("0x%08X " % start_off, "0x%08X " % file_size, "%s " % archive_id, "%s " % file_name)
			
			new_file = FileAccess.open(folder_path + "/%s" % file_name, FileAccess.WRITE)
			new_file.store_buffer(mem_file)
			mem_file.clear()
			new_file.close()
			k += 0x14
			
		header_file.close()
		file.close()
		
	print_rich("[color=green]Finished![/color]")
	

func cybellePakExtract() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var pak_name: String
	var f_name: String
	var buff: PackedByteArray
	var pak_size: int
	var f_offset: int
	var f_size: int
	var file_tbl: int
	var num_files: int
	var sector_align: bool = false
	var width: int
	var height: int
	var decomp_type: int = 0
	
	# TODO: Sangoku Renseki:
	# OTHCG.PAK_0176.BIN - OTHCG.PAK_0178.BIN huge multi image files
	# Check for names in some paks
	# RBB extraction (song loop info in exe)
	# Compression type 1 at 0x001032f0 in Sangoku Renseki (cCbsd::fastEx())
	
	if debug_out:
		out_file = FileAccess.open(folder_path + "/!lookup.tbl", FileAccess.WRITE)
		out_file.store_buffer(lookup_table)
				
	for usr_file in selected_files.size():
		in_file = FileAccess.open(selected_files[usr_file], FileAccess.READ)
		pak_name = selected_files[usr_file].get_file()
		var pak_len: int = in_file.get_length()
		
		in_file.seek(0)
		num_files = in_file.get_32()
		pak_size = in_file.get_32()
		if pak_size != pak_len:
			file_tbl = 4
		else:
			file_tbl = 8
		
		var pos: int = file_tbl
		for file in num_files:
			in_file.seek(pos)
			f_offset = in_file.get_32()
			
			if pak_size != pak_len:
				sector_align = false
				pos = in_file.get_position()
				f_size = in_file.get_32()
				f_size -= f_offset
			else:
				sector_align = true
				f_size = in_file.get_32()
				pos = in_file.get_position()
				
			#if file != 0:
				#continue
				
			in_file.seek(f_offset)
			var bytes: int = in_file.get_32()
			var bytes_2: int = in_file.get_32()
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			# Check for ADPCM bytes
			if bytes == 512:
				f_name = pak_name + "_%04d" % file + ".ADPCM"
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				
				print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
				continue
				
			if sector_align:
				# Images are loaded into memory with sector padded bytes, rather than just base size. This is needed for decompression.
				buff.resize(((f_size + 0x7FF) / 0x800 ) * 0x800)
			
			if debug_out:
				f_name = pak_name + "_%04d" % file + ".COMP"
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				
			f_name = pak_name + "_%04d" % file + ".BIN"
			
			if bytes_2 == 0:
				width = buff.decode_u16(0)
				height = buff.decode_u16(2)
				decomp_type = buff.decode_u8(9)
				if buff.decode_u8(9) == 1 and !debug_out:
					push_error("File %s uses old compression format! Skipping." % f_name)
					print_rich("[color=red]File %s uses old compression format! Skipping.[/color]" % f_name)
					print("%08X %08X %02X /%s/%s" % [f_offset, f_size, decomp_type, folder_path, f_name])
					continue
				elif buff.decode_u8(9) > 3 and !debug_out:
					push_error("File %s has unknown compression type %02X!" % [f_name, decomp_type])
					print_rich("[color=red]File %s has unknown compression type %02X![/color]" % [f_name, decomp_type])
					print("%08X %08X %02X /%s/%s" % [f_offset, f_size, decomp_type, folder_path, f_name])
					#continue
			else:
				width = buff.decode_u16(bytes_2)
				height = buff.decode_u16(bytes_2 + 2)
				decomp_type = buff.decode_u8(bytes_2 + 9)
				if buff.decode_u8(bytes_2 + 9) == 1 and !debug_out:
					push_error("File %s uses old compression format! Skipping." % f_name)
					print_rich("[color=red]File %s uses old compression format! Skipping.[/color]" % f_name)
					print("%08X %08X %02X /%s/%s" % [f_offset, f_size, decomp_type, folder_path, f_name])
					continue
				elif buff.decode_u8(bytes_2 + 9) > 3:
					push_error("File %s has unknown compression type %02X!" % [f_name, decomp_type])
					print_rich("[color=red]File %s has unknown compression type %02X![/color]" % [f_name, decomp_type])
					print("%08X %08X %02X /%s/%s" % [f_offset, f_size, decomp_type, folder_path, f_name])
					continue
				
			# TODO: If flag at 0x1F in header, has a palette? If flag is 4, seems to have a compressed palette
			if bytes_2 and buff.decode_u8(bytes_2 + 10) == 0xC:
				var pal: PackedByteArray = buff.slice(bytes_2 + 0x20, bytes_2 + 0x420)
				#pal = ComFuncs.rgba_to_bgra(pal)
				pal = ComFuncs.unswizzle_palette(pal, 32)
				buff = cCbsd(buff)
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
				
				buff = convert_rgb555_with_palette(buff, width, height, pal)
				
				f_name += ".PNG"
				var png: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buff)
				png.save_png(folder_path + "/%s" % f_name)
			elif buff.decode_u8(10) == 0xC:
				var pal: PackedByteArray = buff.slice(bytes_2 + 0x20, bytes_2 + 0x420)
				#pal = ComFuncs.rgba_to_bgra(pal)
				pal = ComFuncs.unswizzle_palette(pal, 32)
				buff = cCbsd(buff)
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
				
				buff = convert_rgb555_with_palette(buff, width, height, pal)
				
				f_name += ".PNG"
				var png: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
				png.save_png(folder_path + "/%s" % f_name)
			else:
				buff = cCbsd(buff)
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					
				f_name += ".PNG"
				var png: Image = ComFuncs.convert_rgb555_to_image(buff, width, height, true)
				png.save_png(folder_path + "/%s" % f_name)
			
			print("%08X %08X %02X /%s/%s" % [f_offset, f_size, decomp_type, folder_path, f_name])
	
	print_rich("[color=green]Finished![/color]")
	
	
func convert_rgb555_with_palette(image_data: PackedByteArray, width: int, height: int, palette_data: PackedByteArray) -> PackedByteArray:
	var output_data = PackedByteArray()
	
	# Process each pixel in the image
	for y in range(height):
		for x in range(width):
			# Get the 16-bit greyscale value (RGB555 format)
			var pixel_index = (y * width + x) * 2
			var grey_value = image_data.decode_u16(pixel_index)
			
			# Calculate the palette index (top 8 bits of the 16-bit value)
			var palette_index = grey_value >> 8
			
			# Lookup the corresponding RGB values in the palette (ignoring alpha)
			var r = palette_data[palette_index * 4]
			var g = palette_data[palette_index * 4 + 1]
			var b = palette_data[palette_index * 4 + 2]
			var a = palette_data[palette_index * 4 + 3]
			a = int((a / 128.0) * 255.0)
			
			# Append the RGB values to the output
			output_data.append(r)
			output_data.append(g)
			output_data.append(b)
			output_data.append(a)
	
	return output_data
	
	
func make_lookup_tables() -> void:
	var table: PackedByteArray = PackedByteArray()
	table.resize(1024)  # Allocate 1024 bytes for both tables (512 bytes each)

	for i in range(512):  # Loop through 512 values
		var a2: int = 0
		var a3: int = 0

		# Calculate a2 and a3 based on bitwise conditions
		if (i & 1) == 0:  # Least significant bit is 0
			a3 = 0x01
			a2 = 0x00
		elif (i & 2) == 0:  # Second least significant bit is 0
			a3 = 0x03
			a2 = ((i >> 2) & 0x01) + 0x01
		elif (i & 4) == 0:  # Third least significant bit is 0
			a3 = 0x05
			a2 = ((i >> 3) & 0x03) + 0x03
		elif (i & 8) == 0:  # Fourth least significant bit is 0
			a3 = 0x07
			a2 = ((i >> 4) & 0x07) + 0x07
		else:  # Otherwise
			a3 = 0x09
			a2 = ((i >> 4) & 0x1F) + 0x0F

		table[i + 512] = a3
		table[i] = a2
		
	lookup_table = table
	
	var table_2: PackedByteArray = PackedByteArray()
	table_2.resize(512)  # Allocate 512 bytes for the two tables combined

	for i in range(256):  # Loop through 256 values
		var v1: int = 0
		var a2: int = 0
		
		# Logic to calculate v1 and a2
		if (i & 1) == 0:  # Least significant bit is 0
			v1 = 0x01
			a2 = 0x01
		elif (i & 2) == 0:  # Second least significant bit is 0
			v1 = 0x02
			a2 = 0x02
		elif (i & 4) == 0:  # Third least significant bit is 0
			v1 = 0x03
			a2 = 0x03
		elif (i & 8) == 0:  # Fourth least significant bit is 0
			v1 = 0x04
			a2 = 0x04
		else:  # Otherwise
			v1 = 0x00
			a2 = 0x05

		table_2[i + 256] = v1
		table_2[i] = a2
		
	lookup_table.append_array(table_2)
	
	var table_3: PackedByteArray = PackedByteArray()
	table_3.resize(0x4000)

	var t6: int = 0x000F
	var t5: int = 0x0010
	var t4: int = 0x0020
	var t3: int = 0x0040
	var t2: int = 0x0080
	var t1: int = 0x0100
	var t0: int = 0x0200
	var a3: int = 0x0400
	var a2: int = 0x0800
	var a1: int = 0x1000
	
	var v0: int = 0
	var v1: int = 0  # Loop counter

	while v1 < 0x2000:  # Loop through 8,192 entries
		var value: int = 0

		# Logic for assigning values based on v1
		v0 = v1 & 0xF
		v0 = v0 < 0xF
		if v0 == 1:
			value = t6
		elif (v1 & 0x0010) == 0:
			value = t5
		elif (v1 & 0x0020) == 0:
			value = t4
		elif (v1 & 0x0040) == 0:
			value = t3
		elif (v1 & 0x0080) == 0:
			value = t2
		elif (v1 & 0x0100) == 0:
			value = t1
		elif (v1 & 0x0200) == 0:
			value = t0
		elif (v1 & 0x0400) == 0:
			value = a3
		elif (v1 & 0x0800) == 0:
			value = a2
		elif (v1 & 0x1000) == 0:
			value = a1

		# Write the value to the table as 2 bytes (short)
		table_3.encode_u16(v1 * 2, value)

		# Increment the counter
		v1 += 1
		
	lookup_table.append_array(table_3)
	return
	
	
func cCbsd(input: PackedByteArray) -> PackedByteArray:
	# This decompression function and related lookups is absurdly complex.
	# Based on offsets from Sangoku Renseki.
	# TODO: decomp_type 1 (these just seem like entire black / white images)
	
	var out: PackedByteArray
	var temp_buff: PackedByteArray
	var fill_size: int
	var v0:int
	var v1:int
	var a0:int
	var a1:int
	var a2:int
	var a3:int
	var t0:int 
	var t1:int
	var t2:int
	var t3:int
	var t4:int
	var t5:int
	var t6:int
	var t7:int
	var t8:int
	var t9: int
	var s1: int
	var s2: int
	var width:int
	var height:int
	var start_off: int 
	var out_size: int
	var mem_01A922B0: int
	var mem_01A922BC: int
	var mem_01A922C4: int
	var mem_01A922C8: int
	var mem_01A922CC: int
	var mem_01A922D0: int
	var mem_01A92350: int
	var mem_01A92354: int
	var mem_01A92358: int
	var mem_01A9235C: int
	var comp_type: int
	
	#if input.decode_u8(9) == 1:
		#push_error("File uses old RLE format! Skipping")
		#return PackedByteArray()
		
	# Older header check (Canvas)
	start_off = input.decode_u32(0x4)
	if start_off != 0:
		input = input.slice(start_off)
	else:
		start_off = 0x20
		
	comp_type = input.decode_u8(9)
	# Determine start of bytes to decode
	a1 = 0
	a2 = 0
	v1 = input.decode_u8(10)
	if v1 == 0xA:
		a1 = 0x200
	elif v1 == 0xC:
		a1 = 0x400
	elif v1 == 0xD:
		a1 = 0x40
	elif v1 == 0xF:
		# Encrypted / compressed palettes?
		v0 = input.decode_u16(0x1E)
		a1 = v0 << 1
		
	a0 = input.decode_u32(0x10)
	v1 = (a2 + a1) + start_off
	start_off = v1 # New start off
	a0 <<= 1
	a0 = v1 + a0
	
	width = input.decode_u16(0)
	height = input.decode_u16(2)
	
	fill_size = (width << 4) + 0x10
	mem_01A922B0 = 0 # Part size when one pass finishes decompression?
	mem_01A922BC = fill_size # ending of fill bytes
	mem_01A922C4 = a0 # First section of bytes to decode
	mem_01A922C8 = start_off
	mem_01A922CC = input.decode_u8(0x1C)
	mem_01A92350 = 0
	mem_01A92354 = 0
	mem_01A92358 = 0x00014C80 # Seems to be part size for decompression. 
	mem_01A9235C = 0 # Header start address of input buffer
	mem_01A922D0 = input.decode_u8(0x1D)
	
	a3 = 0
	t0 = 0x1E
	temp_buff.resize((t0 + 1) << 2)
	while t0 != -1:
		# These create wrap around bytes for seeking to memory addresses.
		# These bytes later when read would normally wrap around the lowest 32 bits of a register value
		v1 = mem_01A922C4
		t0 -= 1
		a2 = width
		a1 = v1 + 1
		a0 = input.decode_u8(v1)
		mem_01A922C4 = a1
		v1 += 2
		a0 -= 8 & 0xFFFFFFFF
		v0 = input.decode_u8(a1)
		mem_01A922C4 = v1
		v0 -= 8 & 0xFFFFFFFF
		v0 = v0 * a2
		v0 = (v0 + a0) & 0xFFFFFFFF
		temp_buff.encode_s32(a3, v0)
		a3 += 4
		
	# Combine fill bytes and out buffer into one. 
	out_size = (width * height) * 2 # * 2 = 16 bit color components
	out.resize(fill_size + out_size)
	
	v0 = (width << 3) + 8
	#fill_buff.resize(v0)
	t1 = mem_01A9235C
	a1 = 0
	if v0 < 0x7FFFFFFF:
		s1 = 0 # Start address of out buffer where fill bytes start
		while v0 != 0:
			# Create fill buffer based on bytes at 0xC in the header of the image
			v1 = a1 << 1
			a1 += 1
			a0 = input.decode_u16(t1 + 0xC)
			v1 += s1
			out.encode_s16(v1, a0)
			v0 = (width << 3) + 8
			v0 = a1 < v0
			t1 = mem_01A9235C
			
	if comp_type == 3:
		var final_size: int = fill_size + out_size
		var goto: String = "init"
		while true:
			match goto:
				"init":
					# Simulates function re-entry
					t2 = 0 # temp_buff start offset
					v0 = mem_01A92358
					a2 = mem_01A922BC # out buffer offset
					t6 = final_size # Think this is correct
					v0 <<= 1
					v0 = a2 + v0
					t9 = a2
					v1 = v0 < t6
					t7 = v0
					if v1 == 0:
						t7 = t6
					t1 = mem_01A922C4
					v0 = a2 < t7
					a3 = mem_01A92354
					t4 = mem_01A92350
					# 00104010
					t5 = mem_01A922C8
					if v0 == 0:
						goto = "00104670"
					else:
						t8 = mem_01A922D0
						s1 = 0 # Points to start of lookup_table
						s2 = 0x200 # Points to next 0x200 of lookup table
						t3 = 0xFFFFFFFF
						v1 = input.decode_u8(t1 + 1)
						goto = "start"
				"start":
					v0 = input.decode_u8(t1)
					v1 <<= 8
					v0 = v0 | v1
					v0 = v0 >> a3
					v0 &= 0x1FF
					v1 = v0 + s2
					v0 += s1
					a0 = lookup_table.decode_u8(v1)
					t0 = lookup_table.decode_u8(v0)
					a3 += a0
					v0 = a3 >> 3
					a3 &= 7
					t1 += v0
					a1 = input.decode_u8(t1 + 3)
					v1 = input.decode_u8(t1 + 2)
					a0 = input.decode_u8(t1 + 1)
					a1 = (a1 << 24) & 0xFFFFFFFF
					v0 = input.decode_u8(t1)
					v1 = (v1 << 16) & 0xFFFFFFFF
					a0 = (a0 << 8) & 0xFFFFFFFF
					v1 = v1 | a0
					v0 = v0 | a1
					v0 = v0 | v1
					v1 = v0 >> a3
					if t0 != t8:
						goto = "00104118"
					else:
						v0 = v1 & 1
						if v0 != 0:
							goto = "001040D8"
							a0 = mem_01A922CC
						else:
							v0 = t4 << 1
							t4 += 1
							v0 = v0 + t5
							a3 += 1
							a0 = input.decode_u16(v0)
							v1 = a3 >> 3
							t1 = t1 + v1
							a3 &= 7
							out.encode_s16(a2, a0)
							goto = "00104664"
							a2 += 2
				"001040D8":
					v0 = 1
					v1 >>= 1
					v0 <<= a0
					a0 = a3 + a0
					v0 = (v0 - 1) & 0xFFFFFFFF
					a3 = a0 + 1
					v1 &= v0
					a0 = a3 >> 3
					v1 = (t4 - v1) & 0xFFFFFFFF
					t1 = t1 + a0
					v1 <<= 1
					a3 &= 7
					v1 += t5
					goto = "0010420C"
					v0 = input.decode_u16(v1 - 2)
				"00104118":
					v0 = v1 & 1
					if v0 != 0:
						v0 = v1 & 2
						goto = "00104150"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						a3 += 1
						v0 = v0 + t2
						a0 = a3 >> 3
						v1 = temp_buff.decode_u32(v0)
						t1 = t1 + a0
						a3 &= 7
						v1 = (v1 << 1) & 0xFFFFFFFF
						v1 = (a2 + v1) & 0xFFFFFFFF
						goto = "0010420C"
						v0 = out.decode_u16(v1)
				"00104150":
					if v0 == 0:
						v0 = v1 & 4
						v0 = (t0 << 2) & 0xFFFFFFFF
						a3 += 2
						v0 += t2
						a0 = a3 >> 3
						v1 = temp_buff.decode_u32(v0)
						t1 += a0
						a3 &= 7
						v1 = (v1 << 1) & 0xFFFFFFFF
						goto = "001041FC"
						v1 = (a2 + v1) & 0xFFFFFFFF
					else:
						# 00104180
						v0 = v1 & 4
						if v0 == 0:
							v0 = v1 & 8
							v0 = (t0 << 2) & 0xFFFFFFFF
							a3 += 3
							v0 += t2
							a0 = a3 >> 3
							v1 = temp_buff.decode_u32(v0)
							t1 += a0
							a3 &= 7
							v1 = (v1 << 1) & 0xFFFFFFFF
							goto = "001041EC"
							v1 = (a2 + v1) & 0xFFFFFFFF
						else:
							v0 = v1 & 8
							# 001041B0
							if v0 != 0:
								v0 = v1 & 0x10
								goto = "00104218"
							else:
								# v0 = v1 & 0x10
								v0 = (t0 << 2) & 0xFFFFFFFF
								a3 += 4
								v0 = (v0 + t2) & 0xFFFFFFFF
								a0 = a3 >> 3
								v1 = temp_buff.decode_u32(v0)
								t1 += a0
								a3 &= 7
								v1 = (v1 << 1) & 0xFFFFFFFF
								v1 = (a2 + v1) & 0xFFFFFFFF
								v0 = out.decode_u16(v1)
								v1 += 2
								out.encode_s16(a2, v0)
								a2 += 2
								# 001041EC
								v0 = out.decode_u16(v1)
								v1 += 2
								out.encode_s16(a2, v0)
								a2 += 2
								# 001041FC
								v0 = out.decode_u16(v1)
								out.encode_s16(a2, v0)
								a2 += 2
								v0 = out.decode_u16(v1 + 2)
								goto = "0010420C"
				"001041EC":
					v1 &= 0xFFFFFFFF
					v0 = out.decode_u16(v1)
					v1 += 2
					out.encode_s16(a2, v0)
					a2 += 2
					# 001041FC
					v0 = out.decode_u16(v1)
					out.encode_s16(a2, v0)
					a2 += 2
					v0 = out.decode_u16(v1 + 2)
					goto = "0010420C"
				"001041FC":
					v1 &= 0xFFFFFFFF
					v0 = out.decode_u16(v1)
					out.encode_s16(a2, v0)
					a2 += 2
					v0 = out.decode_u16(v1 + 2)
					goto = "0010420C"
				"0010420C":
					out.encode_s16(a2, v0)
					goto = "00104664"
					a2 += 2
				"00104218":
					if v0 != 0:
						v0 = v1 & 0x20
						goto = "001042D0"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 5
						v0 += t2
						a1 = v1 & 3
						a0 = temp_buff.decode_u32(v0)
						a3 += 7
						v1 = a3 >> 3
						a3 &= 7
						a0 = (a0 << 1) & 0xFFFFFFFF
						a1 = (a1 - 1) & 0xFFFFFFFF
						a0 = (a2 + a0) & 0xFFFFFFFF
						t1 += v1
						v0 = out.decode_u16(a0)
						a0 += 2
						out.encode_s16(a2, v0)
						a2 += 2
						v0 = out.decode_u16(a0)
						a0 += 2
						out.encode_s16(a2, v0)
						a2 += 2
						v0 = out.decode_u16(a0)
						a0 += 2
						out.encode_s16(a2, v0)
						a2 += 2
						v0 = out.decode_u16(a0)
						a0 += 2
						out.encode_s16(a2, v0)
						a2 += 2
						v0 = out.decode_u16(a0)
						a0 += 2
						out.encode_s16(a2, v0)
						a2 += 2
						if a1 == t3:
							goto = "00104664"
						else:
							v1 = 0xFFFFFFFF
							while a1 != v1:
								a0 &= 0xFFFFFFFF
								v0 = out.decode_u16(a0)
								a0 += 2
								a1 = (a1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"001042D0":
					if v0 != 0:
						v0 = v1 & 0x40
						goto = "00104338"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 6
						v0 += t2
						a3 += 9
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 7
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 8
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								a0 &= 0xFFFFFFFF
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"00104338":
					if v0 != 0:
						v0 = v1 & 0x80
						goto = "001043A0"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 7
						v0 += t2
						a3 += 0xB
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0xF
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x10
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								a0 &= 0xFFFFFFFF
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"001043A0":
					if v0 != 0:
						v0 = v1 & 0x100
						goto = "00104408"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 8
						v0 += t2
						a3 += 0xD
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0x1F
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x20
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								a0 &= 0xFFFFFFFF
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"00104408":
					if v0 != 0:
						v0 = v1 & 0x200
						goto = "00104470"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 9
						v0 += t2
						a3 += 0xF
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0x3F
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x40
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								a0 &= 0xFFFFFFFF
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"00104470":
					if v0 != 0:
						v0 = v1 & 0x400
						goto = "001044D8"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 10
						v0 += t2
						a3 += 0x11
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0x7F
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x80
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"001044D8":
					if v0 != 0:
						v0 = v1 & 0x800
						goto = "00104540"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 11
						v0 += t2
						a3 += 0x13
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0xFF
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x100
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"00104540":
					if v0 != 0:
						v0 = v1 & 0x1000
						goto = "001045A8"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 12
						v0 += t2
						a3 += 0x15
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0x1FF
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x200
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"001045A8":
					if v0 != 0:
						goto = "00104610"
					else:
						v0 = (t0 << 2) & 0xFFFFFFFF
						v1 >>= 13
						v0 += t2
						a3 += 0x17
						a0 = temp_buff.decode_u32(v0)
						v0 = a3 >> 3
						v1 &= 0x3FF
						t1 += v0
						a0 = (a0 << 1) & 0xFFFFFFFF
						v1 += 0x400
						a0 = (a2 + a0) & 0xFFFFFFFF
						a3 &= 7
						if v1 == t3:
							goto = "00104664"
						else:
							a1 = 0xFFFFFFFF
							while a1 != v1:
								v0 = out.decode_u16(a0)
								a0 += 2
								v1 = (v1 - 1) & 0xFFFFFFFF
								out.encode_s16(a2, v0)
								a2 += 2
							goto = "00104668"
							v0 = a2 < t7
				"00104610":
					v1 >>= 14
					v0 += t2
					a3 += 0x19
					a0 = temp_buff.decode_u32(v0)
					v0 = a3 >> 3
					v1 &= 0x7FF
					t1 += v0
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 += 0x800
					a0 = (a2 + a0) & 0xFFFFFFFF
					a3 &= 7
					if v1 == t3:
						goto = "00104664"
					else:
						a1 = 0xFFFFFFFF
						while a1 != v1:
							v0 = out.decode_u16(a0)
							a0 += 2
							v1 = (v1 - 1) & 0xFFFFFFFF
							out.encode_s16(a2, v0)
							a2 += 2
						goto = "00104668"
						v0 = a2 < t7
				"00104664":
					v0 = a2 < t7
					if v0 != 0: # 00104668
						goto = "start"
						v1 = input.decode_u8(t1 + 1)
					else:
						goto = "00104670"
				"00104668":
					if v0 != 0:
						goto = "start"
						v1 = input.decode_u8(t1 + 1)
					else:
						goto = "00104670"
				"00104670":
					v1 = mem_01A922B0
					v0 = (a2 - t9) & 0xFFFFFFFF
					v0 >>= 1
					a0 = a2 < t6
					v1 += v0
					mem_01A922C4 = t1
					mem_01A92354 = a3
					mem_01A92350 = t4
					mem_01A922B0 = v1
					mem_01A922BC = a2
					if a0 == 0:
						v0 = 0xFFFFFFFF
						mem_01A922B0 = v0
						v1 = t6 < a2
						if v1 == 0:
							goto = "001046B8"
						else:
							push_error("cCbsd::newEx() overrun!!!!!")
							return out.slice(fill_size)
					else:
						goto = "001046B8"
				"001046B8":
						v0 = mem_01A922B0
						if v0 == 0xFFFFFFFF:
							return out.slice(fill_size)
						else:
							goto = "init"
	elif comp_type == 2:
		var final_size: int = fill_size + out_size
		var pc: int = 0
		while true:
			match pc:
				0:
					t2 = 0 # temp_buff start offset
					v0 = mem_01A92358
					a2 = mem_01A922BC # out buffer offset $000c(s0)
					t4 = final_size # Think this is correct
					v0 = (v0 << 1) & 0xFFFFFFFF
					v0 = (a2 + v0) & 0xFFFFFFFF
					t8 = a2
					v1 = v0 < t4
					t5 = v0
					if v1 == 0:
						t5 = t4
					t1 = mem_01A922C4 #$0014(s0)
					v0 = a2 < t5
					t0 = mem_01A92354 #$00a4(s0)
					#t4 = mem_01A92350 #$00a0(s0)
					#mem_01A922B0 $0000(s0) v1
					t7 = mem_01A922C8 #$0018(s0)
					if v0 == 0:
						pc = 0x00103f60
						continue
					else:
						t6 = mem_01A922D0 #0020(s0)
						t9 = 0 # Points to start of lookup_table
						s1 = 0x200 # Points to next 0x200 of lookup table
						t3 = 0xFFFFFFFF
						v1 = input.decode_u8(t1 + 1)
					pc = 0x00103968
					continue
				0x00103968:
					v0 = input.decode_u8(t1)#load_byte_unsigned(t1 + 0x0000)
					v1 = (v1 << 8) & 0xFFFFFFFF
					v0 = v0 | v1 # or                v0, v0, v1
					v0 = v0 >> t0 # srav              v0, v0, t0
					v0 = v0 & 511
					v1 = (v0 + s1) & 0xFFFFFFFF
					v0 = v0 + t9
					a0 = lookup_table.decode_u8(v1)#load_byte_unsigned(v1 + 0x0000)
					a3 = lookup_table.decode_u8(v0)#load_byte_unsigned(v0 + 0x0000)
					t0 = t0 + a0
					v0 = t0 >> 3  # arithmetic shift
					t0 = t0 & 7
					t1 = (t1 + v0) & 0xFFFFFFFF
					a1 = input.decode_u8(t1 + 3)#load_byte_unsigned(t1 + 0x0003)
					v1 = input.decode_u8(t1 + 2)#load_byte_unsigned(t1 + 0x0002)
					a0 = input.decode_u8(t1 + 1)#load_byte_unsigned(t1 + 0x0001)
					a1 = (a1 << 24) & 0xFFFFFFFF
					v0 = input.decode_u8(t1)#load_byte_unsigned(t1 + 0x0000)
					v1 = (v1 << 16) & 0xFFFFFFFF
					a0 = (a0 << 8) & 0xFFFFFFFF
					v1 = v1 | a0# or                v1, v1, a0
					v0 = v0 | a1# or                v0, v0, a1
					v0 = v0 | v1# or                v0, v0, v1
					a0 = v0 >> t0 # srav              a0, v0, t0
					if a3 != t6:
						pc = 0x00103a08
						continue
					v1 = mem_01A922CC #load_word(s0 + 0x001c)
					v0 = 0 + 1
					v0 = (v0 << v1) & 0xFFFFFFFF # sllv              v0, v0, v1
					t0 = (t0 + v1) & 0xFFFFFFFF
					v0 = (v0 + -1) & 0xFFFFFFFF
					v1 = t0 >> 3  # arithmetic shift
					v0 = a0 & v0 # and               v0, a0, v0
					t1 = (t1 + v1) & 0xFFFFFFFF
					v0 = (v0 << 1) & 0xFFFFFFFF
					t0 = t0 & 7
					v0 = (v0 + t7) & 0xFFFFFFFF
					v1 = input.decode_u16(v0)# lhu               v1, $0000(v0)
					out.encode_s16(a2, v1)# sh                v1, $0000(a2)
					a2 = a2 + 2
					pc = 0x00103f54
					continue
				0x00103A08:
					v0 = a0 & 1
					if v0 != 0:
						v0 = a0 & 2
						pc = 0x00103a40
						continue
					v0 = (a3 << 2) & 0xFFFFFFFF
					t0 = t0 + 1
					v0 = (v0 + t2) & 0xFFFFFFFF
					a0 = t0 >> 3  # arithmetic shift
					v1 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					t1 = (t1 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					v1 = (v1 << 1) & 0xFFFFFFFF
					v1 = (v1 + a2) & 0xFFFFFFFF
					v0 = out.decode_u16(v1) # lhu               v0, $0000(v1)
					pc = 0x00103afc
					continue
				0x00103A40:
					if v0 != 0:
						v0 = a0 & 4
						pc = 0x00103a70
						continue
					v0 = a0 & 4
					v0 = (a3 << 2) & 0xFFFFFFFF
					t0 = t0 + 2
					v0 = (v0 + t2) & 0xFFFFFFFF
					a0 = t0 >> 3  # arithmetic shift
					v1 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					t1 = (t1 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					v1 = (v1 << 1) & 0xFFFFFFFF
					v1 = (a2 + v1) & 0xFFFFFFFF
					pc = 0x00103aec
					continue
				0x00103A70:
					if v0 != 0:
						v0 = a0 & 8
						pc = 0x00103aa0
						continue
					v0 = a0 & 8
					v0 = (a3 << 2) & 0xFFFFFFFF
					t0 = t0 + 3
					v0 = (v0 + t2) & 0xFFFFFFFF
					a0 = t0 >> 3  # arithmetic shift
					v1 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					t1 = (t1 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					v1 = (v1 << 1) & 0xFFFFFFFF
					v1 = (a2 + v1) & 0xFFFFFFFF
					pc = 0x00103adc
					continue
				0x00103AA0:
					if v0 != 0:
						v0 = a0 & 16
						pc = 0x00103b08
						continue
					v0 = a0 & 16
					v0 = (a3 << 2) & 0xFFFFFFFF
					t0 = t0 + 4
					v0 = (v0 + t2) & 0xFFFFFFFF
					a0 = t0 >> 3  # arithmetic shift
					v1 = temp_buff.decode_u32(v0) #load_word(v0 + 0x0000)
					t1 = (t1 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					v1 = (v1 << 1) & 0xFFFFFFFF
					v1 = (a2 + v1) & 0xFFFFFFFF
					v0 = out.decode_u16(v1)# lhu               v0, $0000(v1)
					v1 = v1 + 2
					out.encode_s16(a2, v0)# sh                v0, $0000(a2)
					a2 = a2 + 2
					pc = 0x00103ADC
					continue
				0x00103ADC:
					v0 = out.decode_u16(v1) # lhu               v0, $0000(v1)
					v1 = v1 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					pc = 0x00103AEC
					continue
				0x00103AEC:
					v0 = out.decode_u16(v1) # lhu               v0, $0000(v1)
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					v0 = out.decode_u16(v1 + 2) # lhu               v0, $0002(v1)
					pc = 0x00103AFC
					continue
				0x00103AFC:
					out.encode_s16(a2, v0)# sh                v0, $0000(a2)
					a2 = a2 + 2
					pc = 0x00103f54
					continue
				0x00103B08:
					if v0 != 0:
						v0 = a0 & 32
						pc = 0x00103bc0
						continue
					v0 = a0 & 32
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 5
					v0 = (v0 + t2) & 0xFFFFFFFF
					a1 = v1 & 3
					a0 = temp_buff.decode_u32(v0) #load_word(v0 + 0x0000)
					t0 = t0 + 7
					v1 = t0 >> 3  # arithmetic shift
					t0 = t0 & 7
					a0 = (a0 << 1) & 0xFFFFFFFF
					a1 = (a1 + -1) & 0xFFFFFFFF
					a0 = (a2 + a0) & 0xFFFFFFFF
					t1 = (t1 + v1) & 0xFFFFFFFF
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					v0 = out.decode_u16(a0)# lhu               v0, $0000(a0)
					a0 = a0 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					a2 = a2 + 2
					if a1 == t3:
						pc = 0x00103f54
						continue
					v1 = 0xFFFFFFFF #0 + -1
					pc = 0x00103B98
					continue
				0x00103B98:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					a1 = (a1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if a1 != v1:
						pc = 0x00103b98
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103BC0:
					if v0 != 0:
						v0 = a0 & 64
						pc = 0x00103c28
						continue
					v0 = a0 & 64
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 6
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 9
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 7
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 8
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#(0 + -1) & 0xFFFFFFFF
					pc = 0x00103C00
					continue
				0x00103C00:
					v0 = out.decode_u16(a0)# lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103c00
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103C28:
					if v0 != 0:
						v0 = a0 & 128
						pc = 0x00103c90
						continue
					v0 = a0 & 128
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 7
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 11
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 15
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 16
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF #(0 + -1) & 0xFFFFFFFF
					pc = 0x00103C68
					continue
				0x00103C68:
					v0 = out.decode_u16(a0)# lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0)# sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103c68
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103C90:
					if v0 != 0:
						v0 = a0 & 256
						pc = 0x00103cf8
						continue
					v0 = a0 & 256
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 8
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 13
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 31
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 32
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					pc = 0x00103CD0
					continue
				0x00103CD0:
					v0 = out.decode_u16(a0)# lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103cd0
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103CF8:
					if v0 != 0:
						v0 = a0 & 512
						pc = 0x00103d60
						continue
					v0 = a0 & 512
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 9
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 15
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 63
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 64
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					pc = 0x00103D38
					continue
				0x00103D38:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103d38
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103D60:
					if v0 != 0:
						v0 = a0 & 1024
						pc = 0x00103dc8
						continue
					v0 = a0 & 1024
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 10
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 17
					a0 = temp_buff.decode_s32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 127
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 128
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					pc = 0x00103DA0
					continue
				0x00103DA0:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103da0
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103DC8:
					if v0 != 0:
						v0 = a0 & 2048
						pc = 0x00103e30
						continue
					v0 = a0 & 2048
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 11
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 19
					a0 = temp_buff.decode_s32(v0) #load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 255
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 256
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					pc = 0x00103E08
					continue
				0x00103E08:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103e08
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103E30:
					if v0 != 0:
						v0 = a0 & 4096
						pc = 0x00103e98
						continue
					v0 = a0 & 4096
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 12
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 21
					a0 = temp_buff.decode_s32(v0) #load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 511
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 512
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					pc = 0x00103E70
					continue
				0x00103E70:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103e70
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103E98:
					if v0 != 0:
						v0 = (a3 << 2) & 0xFFFFFFFF
						pc = 0x00103f00
						continue
					v0 = (a3 << 2) & 0xFFFFFFFF
					v1 = a0 >> 13
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 23
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 1023
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 1024
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					# nop
					pc = 0x00103ED8
					continue
				0x00103ED8:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103ed8
						continue
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103f58
					continue
				0x00103F00:
					v1 = a0 >> 14
					v0 = (v0 + t2) & 0xFFFFFFFF
					t0 = t0 + 25
					a0 = temp_buff.decode_u32(v0)#load_word(v0 + 0x0000)
					v0 = t0 >> 3  # arithmetic shift
					v1 = v1 & 2047
					t1 = (t1 + v0) & 0xFFFFFFFF
					a0 = (a0 << 1) & 0xFFFFFFFF
					v1 = v1 + 2048
					a0 = (a2 + a0) & 0xFFFFFFFF
					t0 = t0 & 7
					if v1 == t3:
						pc = 0x00103f54
						continue
					a1 = 0xFFFFFFFF#0 + -1
					# nop
					pc = 0x00103F38
					continue
				0x00103F38:
					v0 = out.decode_u16(a0) # lhu               v0, $0000(a0)
					a0 = a0 + 2
					v1 = (v1 + -1) & 0xFFFFFFFF
					out.encode_s16(a2, v0) # sh                v0, $0000(a2)
					# nop
					a2 = a2 + 2
					if v1 != a1:
						pc = 0x00103f38
						continue
					pc = 0x00103F54
					continue
				0x00103F54:
					v0 = 1 if a2 < t5 else 0
					pc = 0x00103F58
					continue
				0x00103F58:
					if v0 != 0:
						v1 = input.decode_u8(t1 + 1)#load_byte_unsigned(t1 + 0x0001)
						pc = 0x00103968
						continue
					pc = 0x00103F60
					continue
				0x00103F60:
					v1 = mem_01A922B0 #load_word(s0 + 0x0000)
					v0 = (a2 - t8) & 0xFFFFFFFF  # unsigned
					v0 = v0 >> 1  # arithmetic shift
					a0 = 1 if a2 < t4 else 0
					v1 = (v1 + v0) & 0xFFFFFFFF
					mem_01A922C4 = t1 #store_word(s0 + 0x0014, t1)
					mem_01A92354 = t0 #store_word(s0 + 0x00a4, t0)
					mem_01A922B0 = v1 #$store_word(s0 + 0x0000, v1)
					mem_01A922BC = a2 #store_word(s0 + 0x000c, a2)
					if a0 != 0:
						pc = 0x00103fa4
						continue
					v0 = 0xFFFFFFFF#0 + -1
					v1 = 1 if t4 < a2 else 0
					mem_01A922B0 = v0 #store_word(s0 + 0x0000, v0)
					if v1 == 0:
						pc = 0x00103fa4
						continue
					# lui               a0, $0037
					# jal               $001053f0
					push_error("cCbsd::idxEx() overrun!!!!!")
					return out.slice(fill_size)
					#pc = 0x00103FA4
				0x00103FA4:
					v0 = mem_01A922B0
					if v0 == 0xFFFFFFFF:
						return out.slice(fill_size)
					else:
						pc = 0
						continue
						
							
	return out.slice(fill_size)
	
	
func interludeDecodeImage(buffer:PackedByteArray, dimension_x:int, dimension_y:int, unk_bytes:int, off:int) -> PackedByteArray:
	var out_buffer:PackedByteArray
	var v0:int
	var v1:int
	var a0:int
	var a1:int
	var a2:int
	var a3:int
	var t0:int 
	var t1:int
	var t2:int
	var t3:int
	var t4:int
	var t5:int
	var t6:int
	var size:int
	var width:int
	var height:int
	var unk:int
	var start_off:int
	
	start_off = off
	
	width = dimension_x
	height = dimension_y
	unk = unk_bytes #not needed for anything?
	size = (width * height) << 2
	
	out_buffer.resize(size)
	
	a0 = start_off + 0x8 #buffer off
	a1 = 0 #out buffer offset
	a2 = size
	t3 = buffer.decode_s32(a0)
	v0 = buffer.decode_s8(a0 - 4) & 0xFF
	a3 = v0 & 0x0F
	t2 = v0 & 0x80
	v0 = 1
	t1 = a0 + 4
	v0 <<= a3
	t0 = 0xFFFF
	v1 = v0 - 1
	v0 = a0 + t3
	if t2 > 0:
		t6 = v1
	else:
		t6 = 0xFFFFFFFF
		
	if a2 <= 0:
		return out_buffer
		
	t2 = 0xFFFF0000
	t3 = 0xFFFF
	while a2 > 0:
		if t0 == t3:
			a0 = buffer.decode_s16(t1) & 0xFFFFFFFF
			t0 = a0 | t2 & 0xFFFFFFFF
			t1 += 2
		a0 = t0 & 1
		if a0 != 0:
			a0 = buffer.decode_u8(v0)
			a2 -= 1
			out_buffer.encode_s8(a1, a0)
			a1 += 1
			v0 += 1
			t0 >>= 1
			continue
		
		a0 = buffer.decode_u16(t1)
		t5 = a0 & v1
		a0 >>= a3
		t1 += 2
		if a0 == 0:
			a0 = buffer.decode_u16(t1)
			t1 += 2
		t4 = a1 - a0 & 0xFFFFFFFF
		if t5 == t6:
			a0 = buffer.decode_u8(v0)
			t5 = a0 + t6
			v0 += 1
		t5 += 3
		a0 = t5 & 1
		a2 -= t5
		if a0 != 0:
			a0 = out_buffer.decode_u8(t4)
			t5 -= 1
			out_buffer.encode_s8(a1, a0)
			t4 += 1
			a1 += 1
		t5 >>= 1
		if t5 <= 0:
			t0 >>= 1
			continue
		while t5 > 0:
			a0 = out_buffer.decode_u8(t4)
			t5 -= 1
			out_buffer.encode_s8(a1, a0)
			a0 = out_buffer.decode_u8(t4 + 1)
			out_buffer.encode_s8(a1 + 1, a0)
			t4 += 2
			a1 += 2
		t0 >>= 1
			
	#null transparent byte for png output
	if out_png and remove_alpha:
		a0 = 0
		while a0 < size:
			out_buffer.encode_u8(a0 + 3, 0xFF)
			a0 += 4
			
	return out_buffer
	
	
func canvasDecodeHeader(header:PackedByteArray) -> PackedInt32Array:
	# TODO: figure out this decompression routine one day that covers several PS2 games https://tcrf.net/Category:Games_developed_by_Cybelle
	
	var header_vars: PackedInt32Array #0 decode 1 offset, 1 decode 2 offset
	var i:int = 0
	var v0:int
	var v1:int
	var a0:int = 0 #always zero?
	var a1:int
	var a2:int = 0 #always zero?
	var a3:int
	var t0:int 
	var t1:int
	var t2:int
	var t3:int
	var t4:int
	var t5:int
	var t6:int
	var s1:int = 0
	var s2:int = 0
	var s3:int
	var gp_8880:int
	
	#func 001075B8
	#s2 = + 0x20 from header
	s2 = 0x20
	v0 = header.decode_s32(s2 + 0x10)
	v1 = a0 + s2
	v1 += 0x20
	v0 <<= 1
	v0 = v1 + v0
	header_vars.append(v0) #buffer start
	header_vars.append(v1) #compressed data offset
	return header_vars
	
func canvasDecodeImage(header_vars:PackedInt32Array) -> void:
	# TODO: figure out this decompression routine one day that covers several PS2 games https://tcrf.net/Category:Games_developed_by_Cybelle
	
	var v0:int
	var v1:int
	var a0:int = 0 #always zero?
	var a1:int
	var a2:int = 0 #always zero?
	var a3:int
	var t0:int = 0 #out buffer 1
	var t1:int
	var t2:int
	var t3:int
	var t4:int
	var t5:int
	var t6:int = 0 #out buffer 2
	var t9:int = 0x00011800 #read buffer
	var s1:int = 0
	var s2:int = 0
	var s3:int
	
	
	s1 = t0
	a0 = 0 #lw       a3, $0514(s0) unk
	t2 = header_vars[0]


func _on_interlude_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
	
	
func _on_load_interlude_file_pressed():
	interlude_load_pak.visible = true
	
	
func _on_interlude_load_pak_files_selected(paths):
	interlude_load_pak.visible = false
	interlude_load_folder.visible = true
	selected_files = paths
	
	
func _on_png_out_toggle_toggled(_toggled_on):
	out_png = !out_png


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_output_combined_toggled(_toggled_on: bool) -> void:
	output_combined_image = !output_combined_image


func _on_out_debug_button_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
