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
					var img_type: int
					
					var num_parts: int = in_file.get_32()
					var img_size: int = in_file.get_32() # Same as file size
					var unk32: int = in_file.get_32()
					# DAT information for num_files * 0x10, currently unknown what they relate to.
					# 0x00 "DAT/00"
					# 0x04 unk32
					# 0x08 unk16_1 0x10 for vertical sort, 0x20 for horizontal sort
					# 0x0A img type
					# 0x0C unk16_2 x order?
					# 0x0E unk16_3 y order?
					var dat_buff: PackedByteArray = in_file.get_buffer(num_parts * 0x10)
					var h_v_sort: int = dat_buff.decode_u16(0x8)
						
					var img_pos: int = in_file.get_position()
					for part in range(0, num_parts):
						in_file.seek(img_pos)
						var hdr_bytes: PackedByteArray = in_file.get_buffer(4)
						var hdr_str: String = hdr_bytes.get_string_from_ascii()
						if hdr_str == "GBIX":
							# Skip GBIX header
							in_file.seek(img_pos + 0x10)
							hdr_bytes = in_file.get_buffer(4)
							hdr_str = hdr_bytes.get_string_from_ascii()
						if hdr_str == "PVRT":
							var unk16_1: int = in_file.get_16() # Number of bits?
							img_type = in_file.get_16() # ex: 3 = RGB
							var unk32_1: int = in_file.get_32()
							var t_w: int = in_file.get_16()
							var t_h: int = in_file.get_16()
							
							var buff: PackedByteArray
							var png: Image
							
							if num_parts > 1 and part == num_parts - 1 and h_v_sort == 0x10:
								# Probably a better way at doing this, but I didn't see where this is happening in the header.
								buff = in_file.get_buffer((t_w * t_h) * 3)
								png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, buff)
								if tiled_output:
									png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
									
								var split_png: Array[Image] = split_image(png)
								png_arr.append(split_png[0])
								png_arr.append(split_png[1])
								break
							elif num_parts > 1 and part in range(num_parts - 2, num_parts) and h_v_sort == 0x20:
								# This is silly and doesn't work yet, very likely a better way at doing this.
								buff = in_file.get_buffer((t_w * t_h) * 3)
								png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, buff)
								if tiled_output:
									png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
									
								if part == num_parts - 2:
									var split_png: Array[Image] = split_image_horizontal(png)
									png_arr.append(split_png[0])
									png = split_png[1]
									#png_arr.append(split_png[1])
								elif part == num_parts - 1:
									var split_png: Array[Image] = split_image_horizontal(png)
									png_arr.append(split_png[0])
									png_arr.append(split_png[1])
									break
							else:
								buff = in_file.get_buffer((t_w * t_h) * 3)
								png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, buff)
								
							png_arr.append(png)
							img_pos = in_file.get_position()
							if tiled_output:
								png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
						else:
							push_error("Image doesn't have a 'PVRT' or 'GBIX' header in file %s part %04d! Skipping." % [f_name, part])
							break
							
					if h_v_sort == 0x10:
						# Tile columns of 2 vertically
						final_png = tile_images_by_pair(png_arr)
					elif h_v_sort == 0x20:
						# Tile columns of 2 horizontally
						final_png = tile_images_by_pair_horizontal(png_arr)
					else:
						push_error("Image h_v sort is unknown in %s! Image output may be wrong." % f_name)
						final_png = tile_images_by_pair(png_arr)
						
					if final_png != null:
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
	
	
func tile_images_by_pair_horizontal(images: Array[Image]) -> Image:
	# Ensure the images array has an even number of elements
	if images.size() % 2 != 0:
		push_error("The images array must contain an even number of images.")
		return null

	# Determine the maximum height and total width for each pair of images
	var total_width = 0
	var max_height = 0
	var pair_widths: Array[int] = []
	
	for i in range(0, images.size(), 2):
		var img1 = images[i]
		var img2 = images[i + 1]
		var pair_width = img1.get_width() + img2.get_width()
		var pair_height = max(img1.get_height(), img2.get_height())
		
		# Update global dimensions
		total_width = max(total_width, pair_width)
		max_height += pair_height
		pair_widths.append(pair_width)

	# Create a new Image with the calculated dimensions
	var final_image: Image = Image.create_empty(total_width, max_height, false, images[0].get_format())

	# Tile images horizontally within pairs and arrange pairs vertically
	var y_offset = 0
	for i in range(0, images.size(), 2):
		var img1 = images[i]
		var img2 = images[i + 1]

		# Place the first image of the pair
		for y in range(img1.get_height()):
			for x in range(img1.get_width()):
				final_image.set_pixel(x, y + y_offset, img1.get_pixel(x, y))

		# Place the second image of the pair
		for y in range(img2.get_height()):
			for x in range(img2.get_width()):
				final_image.set_pixel(x + img1.get_width(), y + y_offset, img2.get_pixel(x, y))

		# Update the vertical offset for the next pair
		y_offset += max(img1.get_height(), img2.get_height())

	return final_image
	
	
func split_image(png: Image) -> Array[Image]:
	var png_arr: Array[Image] = []
	var t_w: int = png.get_width()
	var t_h: int = png.get_height()

	# Calculate half width
	var new_w: int = t_w / 2

	# Extract first half
	var xy: Rect2i = Rect2i(0, 0, new_w, t_h)
	var png_cut: Image = png.get_region(xy)
	png_arr.append(png_cut)

	# Extract second half
	xy = Rect2i(new_w, 0, new_w, t_h)
	png_cut = png.get_region(xy)
	png_arr.append(png_cut)

	return png_arr
	
	
func split_image_horizontal(png: Image) -> Array[Image]:
	var png_arr: Array[Image] = []
	var t_w: int = png.get_width()
	var t_h: int = png.get_height()

	# Calculate half width
	var new_h: int = t_h / 2

	# Extract first half
	var xy: Rect2i = Rect2i(0, 0, t_w, new_h)
	var png_cut: Image = png.get_region(xy)
	png_arr.append(png_cut)

	# Extract second half
	xy = Rect2i(t_w, new_h, t_w, new_h)
	png_cut = png.get_region(xy)
	png_arr.append(png_cut)

	return png_arr
	
	
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


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_export_tiled_toggled(_toggled_on: bool) -> void:
	tiled_output = !tiled_output
