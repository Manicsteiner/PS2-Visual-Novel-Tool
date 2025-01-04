extends Control

@onready var file_load_pak: FileDialog = $FILELoadPAK
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var debug_out: bool = false
var tiled_output: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractPak()
		selected_files.clear()
		chose_file = false
		chose_folder = false
		
		
func extractPak() -> void:
	
	for i in range(0, selected_files.size()):
		var in_file: FileAccess = FileAccess.open(selected_files[i], FileAccess.READ)
		var header_buff: PackedByteArray = in_file.get_buffer(8)
		var header_str: String = header_buff.get_string_from_ascii()
		var num_files: int = ComFuncs.swap32(in_file.get_32())
		
		if header_str == "PAKFILE":
			for file in range(0, num_files):
				in_file.seek((file * 0x40) + 0x10)
				var name_buff: PackedByteArray = in_file.get_buffer(0x38)
				var f_name: String = name_buff.get_string_from_ascii()
				var f_offset: int = ComFuncs.swap32(in_file.get_32()) * 0x800
				var f_size: int = ComFuncs.swap32(in_file.get_32())
				
				in_file.seek(f_offset)
				var bytes: int = ComFuncs.swap32(in_file.get_32())
				var fl_bytes: int = 0x464C0000 #FL
				
				if bytes == fl_bytes:
					var png_arr: Array[Image]
					var final_png: Image
					
					var num_parts: int = in_file.get_32()
					var img_size: int = in_file.get_32() # Same as file size
					var unk32: int = in_file.get_32()
					# DAT information for num_files * 0x10, currently unknown what they relate to so we skip them for now
					var img_pos: int = (num_parts * 0x10) + in_file.get_position()
					for part in range(0, num_parts):
						in_file.seek(img_pos)
						var PVRT_bytes: PackedByteArray = in_file.get_buffer(4)
						var PVRT: String = PVRT_bytes.get_string_from_ascii()
						if PVRT != "PVRT":
							push_error("Image doesn't have a 'PVRT' header in file %s part %04d!" % [f_name, part])
							break
						
						var unk16_1: int = in_file.get_16() # Number of bits?
						var unk16_2: int = in_file.get_16() # img type? ex: 3 = RGB
						var unk32_1: int = in_file.get_32()
						var t_w: int = in_file.get_16()
						var t_h: int = in_file.get_16()
						
						var buff: PackedByteArray
						var png: Image
						
						if part == num_parts - 1:
							# Probably a better way at doing this, but I didn't see where this is happening in the header.
							buff = in_file.get_buffer((t_w * t_h) * 3)
							png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, buff)
							if tiled_output:
								png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
								
							var new_w: int = t_w / 2
							var xy: Rect2i = Rect2i(0, 0, new_w, t_h)
							var png_cut: Image = png.get_region(xy)
							png_arr.append(png_cut)
							#png_cut.save_png(folder_path + "/%s" % f_name + "_%04d" % part + "_1" + ".png")
							
							xy = Rect2i(new_w, 0, new_w, t_h)
							png_cut = png.get_region(xy)
							png_arr.append(png_cut)
							#png_cut.save_png(folder_path + "/%s" % f_name + "_%04d" % part + "_2" + ".png")
							final_png = tile_images_by_pair(png_arr)
							final_png.save_png(folder_path + "/%s" % f_name + ".png")
							break
						else:
							buff = in_file.get_buffer((t_w * t_h) * 3)
							png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, buff)
							
						png_arr.append(png)
						img_pos = in_file.get_position()
						if tiled_output:
							png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
							
					final_png = tile_images_by_pair(png_arr)
					final_png.save_png(folder_path + "/%s" % f_name + ".png")
					
				if debug_out:
					in_file.seek(f_offset)
					var buff: PackedByteArray = in_file.get_buffer(f_size)
					
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					buff.clear()
				
				print("0x%08X 0x%08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
		else:
			OS.alert("Invalid pak file in %s!" % selected_files[i])
			continue
		
	print_rich("[color=green]Finished![/color]")
	

func tile_images_by_pair(images: Array[Image]) -> Image:
	# Ensure there is at least one image
	if images.is_empty():
		return null

	# Determine the dimensions of the final image
	var total_width: int = 0
	var max_pair_height: int = 0
	var total_pairs: int = ceil(images.size() / 2.0)
	
	for i in range(total_pairs):
		var img1 = images[i * 2]
		var img2 = images[i * 2 + 1] if (i * 2 + 1 < images.size()) else null

		# Add the width of the first image in the pair to total width
		total_width += max(img1.get_width(), img2.get_width() if img2 else 0)

		# Calculate the height for the pair
		var pair_height = img1.get_height()
		if img2:
			pair_height += img2.get_height()
		max_pair_height = max(max_pair_height, pair_height)

	# Create an empty image with the computed dimensions
	var combined_image: Image = Image.create_empty(total_width, max_pair_height, false, images[0].get_format())
	combined_image.fill(Color(0, 0, 0, 0)) # Optional: Fill with transparency

	# Tile images by pairs
	var x_offset: int = 0
	for i in range(total_pairs):
		var img1 = images[i * 2]
		var img2 = images[i * 2 + 1] if (i * 2 + 1 < images.size()) else null

		# Place the first image in the pair
		for y in range(img1.get_height()):
			for x in range(img1.get_width()):
				combined_image.set_pixel(x + x_offset, y, img1.get_pixel(x, y))
		
		# Place the second image below the first one, if it exists
		if img2:
			for y in range(img2.get_height()):
				for x in range(img2.get_width()):
					combined_image.set_pixel(x + x_offset, y + img1.get_height(), img2.get_pixel(x, y))
		
		# Update the horizontal offset for the next pair
		x_offset += max(img1.get_width(), img2.get_width() if img2 else 0)

	return combined_image
	
	
func _on_load_pak_pressed() -> void:
	file_load_pak.visible = true


func _on_file_load_pak_files_selected(paths: PackedStringArray) -> void:
	file_load_pak.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir
