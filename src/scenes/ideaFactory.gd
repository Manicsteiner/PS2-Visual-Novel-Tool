extends Control

@onready var file_load_uni: FileDialog = $FILELoadUNI
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var remove_alpha: bool = true


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extract_uni()
		selected_files.clear()
		chose_file = false
		chose_folder = false


func extract_uni() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var f_id: int
	var f_offset: int
	var last_f: int
	var f_name: String
	var f_size: int
	var f_ext: String
	var hdr_pos: int
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		match selected_files[file].get_extension().to_lower():
			"uni":
				in_file.seek(0)
				if in_file.get_buffer(4).get_string_from_ascii() != "UNI2":
					f_offset = 0xA000
					last_f = f_offset
					hdr_pos = 0
					while true:
						in_file.seek(hdr_pos)
						f_id = in_file.get_16()
						f_name = "%05d" % f_id
						f_size = in_file.get_16() * 0x800
						if f_size == 0: 
							break
							
						hdr_pos += 4
						f_offset = last_f
						
						in_file.seek(f_offset)
						buff = in_file.get_buffer(f_size)
						last_f = in_file.get_position()
						
						if buff.slice(0, 4).get_string_from_ascii() == "ART2":
							f_name += "_%s" % ComFuncs.convert_jis_packed_byte_array(buff.slice(0x10, 0x20), shift_jis_dic).get_string_from_utf8()
							
							var png: Image = make_image(buff)
							if png.get_width() == 1:
								f_name += ".ART"
								out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
								out_file.store_buffer(buff)
								out_file.close()
								buff.clear()
								
								print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
								continue
							png.save_png(folder_path + "/%s" % f_name + ".PNG")
							
							print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
							continue
						elif buff.slice(0, 8).get_string_from_ascii() == "IECSsreV":
							f_name += ".HD"
						elif buff.slice(0, 0x10).get_string_from_ascii() == "":
							f_name += ".BD"
						else:
							f_name += ".BIN"
						
						out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						buff.clear()
						
						print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
				else:
					in_file.seek(4)
					var unk1: int = in_file.get_32()
					var num_files: int = in_file.get_32()
					var unk2: int = in_file.get_32()
					var init_off: int = in_file.get_32() * 0x800
					hdr_pos = 0x800
					for i in range(num_files):
						in_file.seek(hdr_pos)
						f_id = in_file.get_32()
						f_name = "%05d" % f_id
						f_offset = (in_file.get_32() * 0x800) + init_off
						var f_sec_size: int = in_file.get_32() * 0x800
						f_size = in_file.get_32()
						if f_size == 0:
							break
							
						hdr_pos += 0x10
						
						in_file.seek(f_offset)
						buff = in_file.get_buffer(f_size)
						
						if buff.slice(0, 4).get_string_from_ascii() == "ART2":
							f_name += "_%s" % ComFuncs.convert_jis_packed_byte_array(buff.slice(0x10, 0x20), shift_jis_dic).get_string_from_utf8()
							
							var png: Image = make_image(buff)
							if png.get_width() == 1:
								f_name += ".ART"
								out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
								out_file.store_buffer(buff)
								out_file.close()
								buff.clear()
								
								print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
								continue
							png.save_png(folder_path + "/%s" % f_name + ".PNG")
							
							print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
							continue
						else:
							f_name += ".BIN"
						
						out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						buff.clear()
						
						print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
			"vbg":
				in_file.seek(0)
				var num_files: int = in_file.get_16()
				hdr_pos = 6
				while true:
					in_file.seek(hdr_pos)
					f_size = in_file.get_32()
					f_offset = in_file.get_32()
					f_id = in_file.get_16()
					f_name = "%05d.ADPCM" % f_id
					if f_size == 0: 
						break
					
					hdr_pos += 10
					
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_size)
					
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					buff.clear()
					
					print("%05d " % f_id, "%08X " % f_offset + "%08X " % f_size + "%s" % folder_path + "/%s" % f_name)
	
	print_rich("[color=green]Finished![/color]")
			
			
func make_image(data: PackedByteArray) -> Image:
	var bpp: int = data.decode_u8(4)
	var image_width: int = data.decode_u32(0x8)
	var image_height: int = data.decode_u32(0xC)
	var img_size: int = image_width * image_height
	var palette_size: int
	var palette_offset: int
	
	if bpp == 4:
		img_size /= 2
		palette_size = 0x40
	elif bpp == 8:
		palette_size = 0x400
	elif bpp == 16:
		img_size <<= 1
		palette_size = 0x800 # ?
		print_rich("[color=red]Image bpp 16 not supported yet.[/color]")
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	else:
		print_rich("[color=red]Unknown bpp %02X![/color]" % bpp)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
		
	palette_offset = img_size + 0x20
	var palette: PackedByteArray = PackedByteArray()
	if bpp == 8 or bpp == 16:
		for i in range(0, palette_size):
			palette.append(data.decode_u8(palette_offset + i))
		palette = unswizzle_palette(palette, palette_size, 4)
		if remove_alpha:
			for i in range(0, palette_size, 4):
				palette.encode_u8(i + 3, 255)
	else:
		for i in range(0, palette_size, 2):
			var bgr555: int = data.decode_u16(palette_offset + i)
			var r: int = ((bgr555 >> 10) & 0x1F) * 8
			var g: int = ((bgr555 >> 5) & 0x1F) * 8
			var b: int = (bgr555 & 0x1F) * 8
			palette.append(r)
			palette.append(g)
			palette.append(b)
			palette.append(255)  # Fully opaque alpha

	# Extract raw pixel data
	var image_data_offset: int = 0x20
	var pixel_data: PackedByteArray = data.slice(image_data_offset, image_data_offset + img_size)

	# Create the image object
	var image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)

	# Process the pixel data and apply the palette
	if bpp == 8 or bpp == 16:
		for y in range(image_height):
			for x in range(image_width):
				var pixel_index: int = pixel_data[x + y * image_width]
				var r: int = palette[pixel_index * 4 + 0]
				var g: int = palette[pixel_index * 4 + 1]
				var b: int = palette[pixel_index * 4 + 2]
				var a: int = palette[pixel_index * 4 + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	else:
		for y in range(image_height):
			for x in range(0, image_width, 2):  # Two pixels per byte
				var byte_index: int  = (x + y * image_width) / 2
				var byte_value: int  = pixel_data[byte_index]

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
				if x + 1 < image_width:
					var r2: int = palette[pixel_index_2 * 4 + 0]
					var g2: int = palette[pixel_index_2 * 4 + 1]
					var b2: int = palette[pixel_index_2 * 4 + 2]
					var a2: int = palette[pixel_index_2 * 4 + 3]
					image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	return image


func unswizzle_palette(pal_buffer: PackedByteArray, pal_size: int, nbpp: int) -> PackedByteArray:
	# TODO: move to comfuncs later
	
	var pal: PackedByteArray
	var pos: int
	
	pal.resize(pal_size)
	for p in range(256):
		pos = ((p & 231) + ((p & 8) << 1) + ((p & 16) >> 1))
		for i in range(nbpp):
			pal[pos * nbpp + i] = pal_buffer[p * nbpp + i]
	return pal
	
	
func _on_load_uni_pressed() -> void:
	file_load_uni.show()


func _on_file_load_uni_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	chose_file = true
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
