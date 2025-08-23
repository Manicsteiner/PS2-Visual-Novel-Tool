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
						
						var png: Image = convert_rgb555_to_image(buff.slice(0x14), width, height, true)
						png.save_png(folder_path + "/%s" % f_name + "_%04d" % files + ".png")
					elif image_type == 9:
						# 16 bit palette 0x200 size
						var pal: PackedByteArray = buff.slice(0x14, 0x214)
						var img_dat: PackedByteArray = buff.slice(0x220)
						
						var num_colors: int = buff.decode_u16(0x210)
						width = buff.decode_u16(0x21C) * 2
						height = buff.decode_u16(0x21E)
						
						# Create the image object
						var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
						var palette: PackedByteArray
						for i in range(0, pal.size(), 2):
							var bgr555: int = pal.decode_u16(i)
							var b: int = ((bgr555 >> 10) & 0x1F) * 8
							var g: int = ((bgr555 >> 5) & 0x1F) * 8
							var r: int = (bgr555 & 0x1F) * 8
							palette.append(r)
							palette.append(g)
							palette.append(b)
							palette.append(255)
						for y in range(height):
							for x in range(width):
								var pixel_index: int = img_dat[x + y * width]
								var r: int = palette[pixel_index * 4 + 0]
								var g: int = palette[pixel_index * 4 + 1]
								var b: int = palette[pixel_index * 4 + 2]
								var a: int = palette[pixel_index * 4 + 3]
								image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
						image.save_png(folder_path + "/%s" % f_name + "_%04d" % files + ".png")
					elif image_type == 8:
						var pal: PackedByteArray = buff.slice(0x14, 0x34)
						var img_dat: PackedByteArray = buff.slice(0x40)
						
						width = buff.decode_u16(0x3C) * 4
						height = buff.decode_u16(0x3E)
						
						# Create the image object
						var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
						var palette: PackedByteArray
						for i in range(0, pal.size(), 2):
							var bgr555: int = pal.decode_u16(i)
							var b: int = ((bgr555 >> 10) & 0x1F) * 8
							var g: int = ((bgr555 >> 5) & 0x1F) * 8
							var r: int = (bgr555 & 0x1F) * 8
							palette.append(r)
							palette.append(g)
							palette.append(b)
							palette.append(255)
						for y in range(height):
							for x in range(0, width, 2):  # Two pixels per byte
								var byte_index: int  = (x + y * width) / 2
								var byte_value: int  = img_dat[byte_index]

								# Extract two 4-bit indices (little-endian order)
								var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
								var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

								# Set first pixel
								var r1: int = palette[pixel_index_1 * 4 + 0]
								var g1: int = palette[pixel_index_1 * 4 + 1]
								var b1: int = palette[pixel_index_1 * 4 + 2]
								var a1: int = palette[pixel_index_1 * 4 + 3]
								image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

								# Set second pixel (only if within bounds)
								if x + 1 < width:
									var r2: int = palette[pixel_index_2 * 4 + 0]
									var g2: int = palette[pixel_index_2 * 4 + 1]
									var b2: int = palette[pixel_index_2 * 4 + 2]
									var a2: int = palette[pixel_index_2 * 4 + 3]
									image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
						image.save_png(folder_path + "/%s" % f_name + "_%04d" % files + ".png")
					else:
						push_error("Unknown image type 0x%X in %s_%04d (size 0x%08X)." % [image_type, f_name, files, dec_size])
				else:
					push_error("Unknown image bit depth 0x%X in %s_%04d" % [bit_depth, f_name, files])
				
				
				if out_decomp:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % files + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				buff.clear()
				print("%08X " % f_offset + "%08X " % dec_size + folder_path + "/%s" % f_name + "_%04d" % files)
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
			elif f_name.contains("SONG") or f_name.contains("SOUND") or f_name.contains("VOICE") or f_name.contains("MU_") or f_name.contains("SE_") or f_name.contains("BGM") or f_name.contains("_V") or f_name.contains("_S"):
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
				if f_size > 0x200000: break
				
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
	
	
func convert_rgb555_to_image(input_buffer: PackedByteArray, width: int, height: int, swap_color_order: bool) -> Image: ## RGBA5551
	# Create a blank Image object
	var img: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	
	# Ensure the input buffer size matches the image dimensions
	if input_buffer.size() != width * height * 2:
		push_error("Input buffer size does not match image dimensions!")
		return img
	
	# Loop through the input buffer and set pixels
	var idx: int = 0
	for y in range(height):
		for x in range(width):
			# Read a 16-bit value (2 bytes per pixel)
			var pixel_16: int = input_buffer.decode_u16(idx)
			idx += 2

			# Extract RGBA values from RGBA5551 format
			var r: int = ((pixel_16 >> 10) & 0x1F) * 8
			var g: int = ((pixel_16 >> 5) & 0x1F) * 8
			var b: int = (pixel_16 & 0x1F) * 8

			# Swap color order if requested
			if swap_color_order:
				var temp: int = r
				r = b
				b = temp

			# Set pixel color
			var color: Color = Color(r / 255.0, g / 255.0, b / 255.0, 255.0)
			img.set_pixel(x, y, color)

	return img
	
	
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
