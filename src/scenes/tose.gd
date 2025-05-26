extends Control

@onready var load_exe: FileDialog = $LoadEXE
@onready var load_pig: FileDialog = $LoadPIG
@onready var load_folder: FileDialog = $LoadFOLDER
@onready var load_pig_scan: FileDialog = $LoadPIGScan
@onready var load_exe_b: Button = $HBoxContainer/LoadEXE
@onready var file_load_cvm: FileDialog = $FILELoadCVM
@onready var output_debug: CheckBox = $"VBoxContainer/Output Debug"
@onready var cv_mtext: RichTextLabel = $CVMtext
@onready var load_cvm: Button = $HBoxContainer/LoadCVM


var exe_path: String
var folder_path: String
var selected_files: PackedStringArray
var selected_scan_file: String
var remove_alpha: bool = true
var combine_images: bool = false
var debug_out: bool = false


func _ready() -> void:
	if Main.game_type == Main.NATURAL2:
		load_exe_b.hide()
		file_load_cvm.hide()
		cv_mtext.hide()
		load_cvm.hide()
	elif Main.game_type == Main.PRINCESSMAKER5:
		load_exe_b.hide()
		output_debug.hide()
	else:
		file_load_cvm.hide()
		cv_mtext.hide()
		load_cvm.hide()


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_pig()
		folder_path = ""
		selected_files.clear()
		selected_scan_file = ""
	elif selected_scan_file:
		pig_scan(FileAccess.open(selected_scan_file, FileAccess.READ))
		selected_scan_file = ""
		folder_path = ""
		selected_files.clear()


func extract_pig() -> void:
	
	if Main.game_type == Main.CANVAS2:
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
				var tile_type: int
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
					
					in_file.seek(f_offset + 0xC)
					tile_type = in_file.get_16()
					if tile_type > 8:
						# Used in Princess Maker 5, currently don't know tiling order for these
						push_error("Skipping %s as tile type is > 8 (Currently unknown image processing)." % f_name)
						pos += 0x20
						continue
						
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
					
					var png: Image = process_pig(buff)
					png.save_png(folder_path + "/%s" % f_name + ".PNG")
					
					
					print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
					
					pos += 0x20
			
	elif Main.game_type == Main.PRINCESSMAKER5:
		for file in range(selected_files.size()):
			var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
			var arc_name: String = selected_files[file].get_file().get_basename()
			var arc_full_name: String = selected_files[file].get_file()
			var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
			if buff.slice(0, 4).get_string_from_ascii() != "P2IG":
				OS.alert("%s isn't a valid PIG image file!" % arc_full_name)
				continue
				
			var png: Image = process_pig(buff)
			png.save_png(folder_path + "/%s" % arc_name + ".PNG")
			print("Converted %s" % folder_path + "/%s" % arc_name + ".PNG")
			
	print_rich("[color=green]Finished![/color]")
	
	
func pig_scan(in_file: FileAccess) -> void:
	print_rich("[color=yellow]Scanning... please wait[/color]")
	
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	var search_results: PackedInt32Array
	var arc_file: FileAccess = in_file
	var in_file_path: String = arc_file.get_path_absolute()
	
	var pos: int = 0
	var last_pos: int = 0
	var f_id: int = 0
	var entry_count: int = 0
	arc_file.seek(pos)
	
	while arc_file.get_position() < arc_file.get_length():
		arc_file.seek(pos)
		if arc_file.eof_reached():
			break
			
		var p2ig_bytes: int = arc_file.get_32()
		last_pos = arc_file.get_position()
		if p2ig_bytes == 0x47493250:
			search_results.append(last_pos - 4)
			arc_file.seek(last_pos + 0xC)
			var p2ig_name: String = ComFuncs.convert_jis_packed_byte_array(in_file.get_buffer(0x8), shift_jis_dic).get_string_from_utf8()
			
			arc_file.seek(last_pos + 0x44)
			var img_dat_off: int = arc_file.get_32()
			var p2ig_size: int = arc_file.get_32()
			
			print("PIG found at: %08X, with size: %08X" % [last_pos - 4, p2ig_size + img_dat_off])
			
			arc_file.seek(search_results[entry_count])
			var p2ig_buff: PackedByteArray = arc_file.get_buffer(p2ig_size + img_dat_off)
			
			last_pos = arc_file.get_position()
			if !last_pos % 16 == 0:
				last_pos = (last_pos + 15) & ~15
				
			if debug_out:
				var out_file: FileAccess = FileAccess.open(in_file_path + "_%04d_" % entry_count + "%s" % p2ig_name + ".P2I", FileAccess.WRITE)
				out_file.store_buffer(p2ig_buff)
				out_file.close()
				
			var png: Image = process_pig(p2ig_buff)
			png.save_png(in_file_path + "_%04d_" % entry_count + "%s" % p2ig_name + ".PNG")
			
			p2ig_buff.clear()
			
			entry_count += 1
		else:
			if !last_pos % 16 == 0:
				last_pos = (last_pos + 15) & ~15
				
		pos = last_pos
		f_id += 1
	
	var color: String
	if entry_count > 0:
		color = "green"
	else:
		color = "red"
		
	print_rich("[color=%s]Found %d P2IG entries[/color]" % [color, search_results.size()])
	return
	
	
func unswizzle8(data: PackedByteArray, w: int, h: int, swizz: bool) -> PackedByteArray:
	# Original code from: https://github.com/leeao/PS2Textures/blob/583f68411b4f6cca491730fbb18cb064822f1017/PS2Textures.py#L266
	# Unknown license
	
	var out: PackedByteArray = data.duplicate()
	for y in range(h):
		for x in range(w):
			var bs: int = ((y + 2) >> 2 & 1) * 4
			var idx: int = \
				((y & ~0xF) * w) + ((x & ~0xF) * 2) + \
				( ((((y & ~3) >> 1) + (y & 1)) & 7) * w * 2 ) + \
				(((x + bs) & 7) * 4) + \
				(((y >> 1) & 1) + ((x >> 2) & 2))
			if swizz:
				out[idx] = data[y * w + x]
			else:
				out[y * w + x] = data[idx]
	return out
	
	
func process_pig(data: PackedByteArray) -> Image:
	var format: int = data.decode_u16(0xC)
	var image_width: int = 1 << data.decode_u16(0x20)
	var image_height: int = 1 << data.decode_u16(0x22)
	var img_type: int = data.decode_u8(0x24)
	var palette_offset: int = data.decode_u32(0x40)
	var palette_size: int = data.decode_u32(0x44)
	var image_data_offset: int = data.decode_u32(0x48)
	var img_size: int = data.decode_u32(0x4C)
	
	if img_type == 0:
		var image: Image = Image.create_from_data(image_width, image_height, false, Image.FORMAT_RGBA8, data.slice(image_data_offset))
		if remove_alpha:
			image.convert(Image.FORMAT_RGB8)
		return image
		
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

	var pixel_data: PackedByteArray = data.slice(image_data_offset)

	var image: Image = Image.create_empty(image_width, image_height, false, Image.FORMAT_RGBA8)
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
		if format == 0xE: # swizzled image data
			pixel_data = unswizzle8(pixel_data, image_width, image_height, false)
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
	load_folder.show()


func _on_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_load_scan_pig_pressed() -> void:
	load_pig_scan.show()


func _on_load_pig_scan_file_selected(path: String) -> void:
	selected_scan_file = path


func _on_load_cvm_pressed() -> void:
	file_load_cvm.show()


func _on_file_load_cvm_dir_selected(dir: String) -> void:
	var cvm_name: String = "DATA.BIN"
	var exe_path: String = dir + "/cvm_tool.exe"
	var temp: FileAccess = FileAccess.open(exe_path, FileAccess.READ)
	if temp == null:
		OS.alert("Could not open %s" % exe_path)
		return
	
	temp.close()
	var input_path: String = dir + "/%s" % cvm_name
	temp = FileAccess.open(input_path, FileAccess.READ)
	if temp == null:
		OS.alert("Could not open %s" % input_path)
		return
	
	temp.close()
	var output_path: String = dir + "/OUT.ISO"
	temp = FileAccess.open(output_path, FileAccess.WRITE)
	if temp == null:
		OS.alert("Could not open %s for writting" % output_path)
		return
	temp.close()
	
	print_rich("[color=yellow]Converting CVM...")
	
	var password: String = "GAO"
	
	var args: PackedStringArray = ["split", "-p", password, input_path, output_path]
	var output: Array = []
	
	var exit_code: int = OS.execute(exe_path, args, output, true, false)

	print("Exit code: %d" % exit_code)
	print(output)
	print_rich("[color=green]Finished![/color]")


func _on_cv_mtext_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
