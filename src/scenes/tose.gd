extends Control

@onready var load_exe: FileDialog = $LoadEXE
@onready var load_pig: FileDialog = $LoadPIG
@onready var load_folder: FileDialog = $LoadFOLDER

var exe_path: String
var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var remove_alpha: bool = true
var combine_images: bool = false
var debug_out: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extract_pig()
		chose_folder = false
		chose_file = false
		selected_files.clear()


func extract_pig() -> void:
	var entry_point: int = 0xFFF80
	var in_file: FileAccess
	var out_file: FileAccess
	var exe_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var f_offset: int
	var f_size: int
	var tbl_start: int
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		if in_file.get_buffer(4).get_string_from_ascii() == "Wpbb":
			in_file.seek(4)
			var num_files: int = in_file.get_32()
			var pos: int = 0x8
			for i in range(0, num_files):
				in_file.seek(pos)
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				f_name = "%08d" % i
				
				in_file.seek(f_offset)
				if in_file.get_buffer(4).get_string_from_ascii() == "ILD":
					f_name += ".ILD"
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				pos += 8
			
		else:
			if selected_files[file].get_file() == "PIG2.BIN":
				tbl_start = 0x0019D600 - entry_point
			elif selected_files[file].get_file() == "PIG.BIN":
				tbl_start = 0x00195C40 - entry_point
			else:
				OS.alert("Unknown bin file loaded.")
				continue
			
			if exe_path == "":
				OS.alert("Please load SLPM_662.65 first.")
				return
				
			exe_file = FileAccess.open(exe_path, FileAccess.READ)
			var pos: int = tbl_start
			var width: int
			var height: int
			var img_off: int
			var img_type: int
			while true:
				exe_file.seek(pos)
				f_name = exe_file.get_line()
				exe_file.seek(pos + 0x1C)
				f_offset = exe_file.get_32() << 2
				if f_offset >= 0xFFFFFFFF:
					break
					
				in_file.seek(f_offset + 0x20)
				width = 1 << in_file.get_16()
				height = 1 << in_file.get_16()
				img_type = in_file.get_8()
				if img_type < 0x13 or img_type > 0x14:
					push_error("Unknown image type %02X in %s" % [img_type, f_name])
					
				in_file.seek(f_offset + 0x48)
				img_off = in_file.get_32()
				if img_type == 0x13:
					f_size = (width * height) + img_off
				elif img_type == 0x14:
					f_size = ((width * height) >> 1) + img_off
				
				if f_name == "CGM_CLUT": # Contains only palette data
					in_file.seek(f_offset + 0x40)
					var img_pal_off: int = in_file.get_32()
					f_size = img_pal_off + 0x400
					
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_size)
					
					f_name += ".P2I"
					
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					pos += 0x20
					continue
					
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				f_name += ".P2I"
				
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				
				var png: Image = process_p2ig(buff)
				png.save_png(folder_path + "/%s" % f_name + ".PNG")
				
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				pos += 0x20
			
	
	print_rich("[color=green]Finished![/color]")
	
	
func process_p2ig(data: PackedByteArray) -> Image:
	var image_width: int = 1 << data.decode_u16(0x20)
	var image_height: int = 1 << data.decode_u16(0x22)
	var img_type: int = data.decode_u8(0x24)

	var palette_offset: int = data.decode_u32(0x40)
	var palette_size: int = data.decode_u32(0x44)
	var palette: PackedByteArray = PackedByteArray()
	
	for i in range(0, palette_size):
		palette.append(data.decode_u8(palette_offset + i))

	if palette_size == 0x400:
		palette = ComFuncs.unswizzle_palette(palette, 32)
	elif palette_size == 0x40:
		for i in range(0, palette_size, 2):
			var color_16: int = data.decode_u16(palette_offset + i)
			var r: int = (color_16 >> 10) & 0x1F  # Extract red (BGR555 format)
			var g: int = (color_16 >> 5) & 0x1F   # Extract green
			var b: int = (color_16 >> 0) & 0x1F   # Extract blue
			
			# Convert 5-bit color to 8-bit
			palette.append((r << 3) | (r >> 2))
			palette.append((g << 3) | (g >> 2))
			palette.append((b << 3) | (b >> 2))
			palette.append(255)  # Full alpha

	if remove_alpha and palette_size == 0x400:
		for i in range(0, 0x400, 4):
			palette.encode_u8(i + 3, 255)

	var image_data_offset: int = data.decode_u32(0x48)
	var pixel_data: PackedByteArray = data.slice(image_data_offset)

	var image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	if img_type == 0x14:
		for i in range(pixel_data.size()):
			var byte_val: int = pixel_data[i]
			pixel_data[i] = ((byte_val & 0x0F) << 4) | ((byte_val & 0xF0) >> 4)  
			# Swaps high and low nibbles
		for y in range(image_height):
			for x in range(image_width):
				var pixel_index: int = pixel_data[(x + y * image_width) >> 1]  # 2 pixels per byte
				if x % 2 == 0:
					pixel_index = (pixel_index >> 4) & 0xF  # Higher nibble
				else:
					pixel_index = pixel_index & 0xF         # Lower nibble

				var base_index: int = pixel_index * 4
				var r: int = palette[base_index + 0]
				var g: int = palette[base_index + 1]
				var b: int = palette[base_index + 2]
				var a: int = palette[base_index + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		return image
	elif img_type == 0x13:
		for y in range(image_height):
			for x in range(image_width):
				var pixel_index: int = pixel_data[x + y * image_width]
				var r: int = palette[pixel_index * 4 + 0]
				var g: int = palette[pixel_index * 4 + 1]
				var b: int = palette[pixel_index * 4 + 2]
				var a: int = palette[pixel_index * 4 + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		return image
		
	return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	


func _on_load_exe_pressed() -> void:
	load_exe.show()


func _on_load_pig_pressed() -> void:
	load_pig.show()


func _on_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_load_pig_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	chose_file = true
	load_folder.show()


func _on_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
