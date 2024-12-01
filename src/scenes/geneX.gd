extends Control

@onready var gene_load_bin: FileDialog = $GENELoadBIN
@onready var gene_load_folder: FileDialog = $GENELoadFOLDER

var chose_folder:bool = false
var folder_path:String

var chose_bin:bool = false
var selected_files: PackedStringArray

var out_decomp: bool = false


func _process(_delta: float) -> void:
	if chose_bin and chose_folder:
		extractBin()
		chose_folder = false
		chose_bin = false
		selected_files.clear()
		
		
func extractBin() -> void:
	var f_name: String
	var f_offset: int
	var f_size: int
	var in_file: FileAccess
	var out_file: FileAccess
	var num_files: int
	var dec_size: int
	var buff: PackedByteArray
	var width: int
	var height: int
	var bit_depth: int
	var pos: int
	var image_type: int
	var zsize: int
	
	for usr_files in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[usr_files], FileAccess.READ)
		f_name = selected_files[usr_files].get_file()
		
		num_files = in_file.get_16()
		if num_files > 0x400:
			OS.alert("num_files greater than 0x400 in %s. Likely invalid BIN loaded." % f_name)
			continue
			
		pos = 2
		
		for files in range(0, num_files):
			if (
				f_name.contains("CG0") or 
				f_name.contains("BG0") or 
				f_name.contains("CHARA") or 
				f_name.contains("ALBUM") or
				f_name.contains("CHSEL") or
				f_name.contains("GMENU") or
				#f_name.contains("HIST") or
				#f_name.contains("MEMO") or
				f_name.contains("FACE") or
				f_name.contains("OPTION") or
				f_name.contains("SAVLD") or
				f_name.contains("STEST") or
				f_name.contains("SYSCMN") or
				f_name.contains("TITLE") or
				f_name.contains("WINFONT") or
				f_name.contains("DDI") or
				f_name.contains("_G") or
				f_name == "JUN.BIN" or 
				f_name == "KAORI.BIN" or 
				f_name == "MAYUKO.BIN" or 
				f_name == "NANAMI.BIN" or 
				f_name == "YUKINA.BIN"
				):
				
				in_file.seek((files * 4) + pos)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				in_file.seek(f_offset)
				
				zsize = f_size - f_offset
				buff = in_file.get_buffer(zsize)
				
				dec_size = buff.decode_u32(0)
				
				# Hooligan
				if Main.game_type == Main.HOOLIGAN or Main.game_type == Main.SWEETLEGACY:
					buff = decompLZSS2(buff.slice(4), zsize - 4, dec_size)
				else:
					buff = ComFuncs.decompLZSS(buff.slice(4), zsize - 4, dec_size)
				
				bit_depth = buff.decode_s32(0)
				image_type = buff.decode_s32(4)
				
				if bit_depth == 0x10:
					if image_type == 2:
						width = buff.decode_u16(0x10)
						height = buff.decode_u16(0x12)
						
						var png: Image = ComFuncs.convert_rgb555_to_image(buff.slice(0x14), width, height, true)
						png.save_png(folder_path + "/%s" % f_name + "_%04d" % files + ".png")
					elif image_type == 9:
						# 16 bit palette 0x200 size
						var pal: PackedByteArray = buff.slice(0x14, 0x214)
						var img_dat: PackedByteArray = buff.slice(0x220)
						var final_img: PackedByteArray
						var swap: PackedByteArray
						
						pal = ComFuncs.convert_palette16_bgr_to_rgb(pal)
						
						var num_colors: int = buff.decode_u16(0x210)
						width = buff.decode_u16(0x21C) * 2
						height = buff.decode_u16(0x21E)
						
						var tga_hdr: PackedByteArray = ComFuncs.makeTGAHeader(true, 1, 16, 8, width, height)
						
						final_img.append_array(tga_hdr)
						final_img.append_array(pal)
						final_img.append_array(img_dat)
						
						out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".TGA", FileAccess.WRITE)
						out_file.store_buffer(final_img)
						out_file.close()
						
						final_img.clear()
						pal.clear()
						img_dat.clear()
						tga_hdr.clear()
					#elif image_type == 8:
						# 8 bit palette 0x20 size.
						# TGA unsupported?
						#
						#var pal: PackedByteArray = buff.slice(0x14, 0x34)
						#var img_dat: PackedByteArray = buff.slice(0x40)
						#var final_img: PackedByteArray
						#var swap: PackedByteArray
						#
						#pal = ComFuncs.convert_palette16_bgr_to_rgb(pal)
						#
						#var num_colors: int = buff.decode_u16(0x10)
						#width = buff.decode_u16(0x3C) * 2
						#height = buff.decode_u16(0x3E)
						#
						#var tga_hdr: PackedByteArray = makeTGAHeader(1, 1, 0, num_colors, 8, width, height, 8)
						#
						#final_img.append_array(tga_hdr)
						#final_img.append_array(pal)
						#final_img.append_array(img_dat)
						#
						#out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".TGA", FileAccess.WRITE)
						#out_file.store_buffer(final_img)
						#out_file.close()
						#
						#final_img.clear()
						#pal.clear()
						#img_dat.clear()
						#tga_hdr.clear()
					else:
						push_error("Unknown image type 0x%X in %s_%04d (size 0x%08X)." % [image_type, f_name, files, dec_size])
				else:
					push_error("Unknown image bit depth 0x%X in %s_%04d" % [bit_depth, f_name, files])
				
				
				if out_decomp:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				buff.clear()
				print("0x%08X " % f_offset + "0x%08X " % dec_size + folder_path + "/%s" % f_name + "_%04d" % files)
			elif f_name.contains("SCRIPT"):
				in_file.seek((files * 4) + pos)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				in_file.seek(f_offset)
				
				zsize = f_size - f_offset
				buff = in_file.get_buffer(zsize)
				
				dec_size = buff.decode_u32(0)
				
				if Main.game_type == Main.HOOLIGAN or Main.game_type == Main.SWEETLEGACY:
					buff = decompLZSS2(buff.slice(4), zsize - 4, dec_size)
				else:
					buff = ComFuncs.decompLZSS(buff.slice(4), zsize - 4, dec_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
					
				buff.clear()
				print("0x%08X " % f_offset + "0x%08X " % dec_size + folder_path + "/%s" % f_name + "_%04d" % files)
			elif f_name.contains("SONG") or f_name.contains("SOUND") or f_name.contains("VOICE") or f_name.contains("MU_") or f_name.contains("SE_") or f_name.contains("BGM") or f_name.contains("_V"):
				in_file.seek((files * 4) + pos)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				in_file.seek(f_offset)
				
				buff = in_file.get_buffer(f_size - f_offset)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
					
				buff.clear()
				print("0x%08X " % f_offset + "0x%08X " % (f_size - f_offset) + folder_path + "/%s" % f_name + "_%04d" % files)
			else:
				# Assume compressed
				
				in_file.seek((files * 4) + pos)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				in_file.seek(f_offset)
				
				zsize = f_size - f_offset
				buff = in_file.get_buffer(zsize)
				
				dec_size = buff.decode_u32(0)
				
				if Main.game_type == Main.HOOLIGAN or Main.game_type == Main.SWEETLEGACY:
					buff = decompLZSS2(buff.slice(4), zsize - 4, dec_size)
				else:
					buff = ComFuncs.decompLZSS(buff.slice(4), zsize - 4, dec_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
					
				buff.clear()
				print("0x%08X " % f_offset + "0x%08X " % dec_size + folder_path + "/%s" % f_name + "_%04d" % files)
		
	print_rich("[color=green]Finished![/color]")
	
	
func makeTGAHeader(color_map_type: int, image_type: int, color_entry_start:int, num_colors: int, color_map_depth: int, width: int, height: int, pixel_depth: int) -> PackedByteArray:
	# https://en.wikipedia.org/wiki/Truevision_TGA#Header
	
	var header: PackedByteArray
	
	header.resize(0x12)
	
	header.encode_u8(1, image_type)
	header.encode_u8(2, image_type)
	header.encode_u16(3, color_entry_start)
	header.encode_u16(5, num_colors)
	header.encode_u8(7, color_map_depth)
	header.encode_u16(0xC, width)
	header.encode_u16(0xE, height)
	header.encode_u8(0x10, pixel_depth)
	header.encode_u8(0x11, 0x28)
	return header
	
	
func rgb555_to_image(input_buffer: PackedByteArray, width: int, height: int, palette_type: String) -> Image:
	# Define palette properties based on the type
	var palette_offset: int = 0
	var palette_size: int = 0x200  # Default size (512 bytes for 32 entries)
	var data_offset: int = palette_offset + palette_size

	if input_buffer.size() < data_offset:
		push_error("Input buffer size too small for palette and image data.")
		return null

	# Decode the palette
	var palette: Array = []
	if palette_type == "16bit":
		# 16-bit palette (RGB555 format)
		for i in range(256):  # 256 entries in the palette
			var idx: int = palette_offset + i * 2
			if idx + 1 >= input_buffer.size():
				push_error("Palette index out of bounds for 16-bit palette.")
				return null

			# Decode RGB555 to RGBA8
			var rgb555: int = input_buffer.decode_u16(idx)
			var r: float = ((rgb555 >> 10) & 0x1F) * 255.0 / 31.0
			var g: float = ((rgb555 >> 5) & 0x1F) * 255.0 / 31.0
			var b: float = (rgb555 & 0x1F) * 255.0 / 31.0
			var color: Color = Color(r / 255.0, g / 255.0, b / 255.0, 1.0)  # Opaque
			palette.append(color)

	elif palette_type == "32bit":
		# 32-bit palette (BGRA format)
		for i in range(32):  # 32 entries in the palette
			var idx: int = palette_offset + i * 4
			if idx + 3 >= input_buffer.size():
				push_error("Palette index out of bounds for 32-bit palette.")
				return null

			# Decode BGRA to RGBA
			var color: Color
			color.r = input_buffer[idx + 2] / 255.0
			color.g = input_buffer[idx + 1] / 255.0
			color.b = input_buffer[idx] / 255.0
			color.a = input_buffer[idx + 3] / 255.0
			palette.append(color)

	else:
		push_error("Unsupported palette type: " + palette_type)
		return null

	# Create the image and load raw data
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Decode the RGB555 data using the palette
	for y in range(height):
		for x in range(width):
			var pixel_idx: int = y * width + x
			var data_idx: int = data_offset + pixel_idx * 2
			if data_idx + 1 >= input_buffer.size():
				push_error("Data index out of bounds while reading image data.")
				return null

			# Get RGB555 value
			var rgb555: int = input_buffer.decode_u16(data_idx)
			var palette_idx: int = (rgb555 >> 10) & 0x1F  # Top 5 bits for the palette index
			if palette_idx < palette.size():
				image.set_pixel(x, y, palette[palette_idx])

	return image


func decompLZSS2(buffer: PackedByteArray, zsize: int, size: int) -> PackedByteArray:
	var dec: PackedByteArray
	var dict: PackedByteArray
	var in_off: int = 0
	var out_off: int = 0
	var dic_off: int = 0x7DE  # Different dictionary offset
	var mask: int = 0
	var cb: int = 0
	var byte: int = 0

	dict.resize(0x800)  # Different dictionary size
	dec.resize(size)
	while out_off < size:
		# Ensure we have at least one byte for cb
		if in_off >= zsize:
			return dec

		if mask == 0:
			cb = buffer[in_off]
			in_off += 1
			mask = 1

		if (mask & cb):
			# Ensure we have one byte to read
			if in_off >= zsize:
				return dec

			byte = buffer[in_off]
			dec[out_off] = byte
			dict[dic_off] = byte

			out_off += 1
			in_off += 1
			dic_off = (dic_off + 1) & 0x7FF  # Dictionary wrap-around
		else:
			# Ensure we have at least two bytes to read
			if in_off + 1 >= zsize:
				return dec

			var b1: int = buffer[in_off]
			var b2: int = buffer[in_off + 1]
			var len: int = (b2 & 0x1F) + 3  # Length calculation is different
			var loc: int = ((b2 & 0xE0) << 3) | b1  # Different location calculation b1| ((b2 & 0xf0) << 4)

			for b in range(len):
				byte = dict[(loc + b) & 0x7FF]
				if out_off + b >= size:
					return dec
				dec[out_off + b] = byte
				dict[(dic_off + b) & 0x7FF] = byte
			dic_off = (dic_off + len) & 0x7FF
			in_off += 2
			out_off += len

		mask = (mask << 1) & 0xFF

	return dec


func _on_load_bin_pressed() -> void:
	gene_load_bin.visible = true
		
		
func _on_gene_load_bin_files_selected(paths: PackedStringArray) -> void:
	gene_load_bin.visible = false
	gene_load_folder.visible = true
	selected_files = paths
	chose_bin = true


func _on_gene_load_folder_dir_selected(dir: String) -> void:
	gene_load_folder.visible = false
	folder_path = dir
	chose_folder = true
	
func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp
