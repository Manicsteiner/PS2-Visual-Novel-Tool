extends Control

@onready var file_load_pak: FileDialog = $FILELoadPAK
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var debug_out: bool = false
var tiled_output: bool = false

#TODO: FACE.PAK images still suck

func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractPak()
		selected_files.clear()
		chose_file = false
		chose_folder = false
		
		
func extractPak() -> void:
	for i in range(0, selected_files.size()):
		var in_file: FileAccess = FileAccess.open(selected_files[i], FileAccess.READ)
		var arc_name: String = selected_files[i].get_file().get_basename()
		var header_str: String = in_file.get_buffer(8).get_string_from_ascii()
		var num_files: int = ComFuncs.swap32(in_file.get_32())
		
		if header_str == "PAKFILE":
			for file in range(0, num_files):
				in_file.seek((file * 0x40) + 0x10)
				var f_name: String = in_file.get_buffer(0x38).get_string_from_ascii()
				#if f_name != "dg002.dat":
					#continue
				var f_offset: int = ComFuncs.swap32(in_file.get_32()) * 0x800
				var f_size: int = ComFuncs.swap32(in_file.get_32())
				
				print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
				
				in_file.seek(f_offset)
				var buff: PackedByteArray = in_file.get_buffer(f_size)
				if buff.slice(0, 4).get_string_from_ascii() == "Lzs3":
					f_size = buff.decode_u32(4)
					buff = ComFuncs.decompLZSS(buff.slice(12), buff.size() - 12, f_size)
				elif buff.slice(0, 4).get_string_from_ascii() == "Lzs1":
					push_error("%s uses Lzs1 compression TODO" % f_name)
					
				if debug_out:
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				if buff.slice(0, 4).get_string_from_ascii() == "FL":
					# DAT information for num_files * 0x10, currently unknown what they relate to.
					# 0x00 "DAT/00"
					# 0x04 unk32
					# 0x08 unk16_1 0x10 for vertical sort, 0x20 for horizontal sort
					# 0x0A img type
					# 0x0C image part start 32
					
					var png_arr: Array[Image]
					var final_png: Image
					var img_type: int
					
					
					var num_parts: int = buff.decode_u32(4)
					var img_size: int = buff.decode_u32(8) # Same as file size
					var unk32: int = buff.decode_u32(12)
						
					var h_v_sort: int = buff.decode_u16(0x18)
					var img_pos: int = buff.decode_u32(0x1C)
					var hdr_str: String = buff.slice(img_pos, img_pos + 4).get_string_from_ascii()
					if hdr_str != "PVRT" and hdr_str != "GBIX": # if first part of image is blank or 1?
						img_pos = buff.decode_u32(0x2C)
						h_v_sort = buff.decode_u16(0x28)
						num_parts -= 1
					for part in range(0, num_parts):
						hdr_str = buff.slice(img_pos, img_pos + 4).get_string_from_ascii()
						if hdr_str == "GBIX":
							# Skip GBIX header
							img_pos += 0x10
							hdr_str = buff.slice(img_pos, img_pos + 4).get_string_from_ascii()
						if hdr_str == "PVRT":
							var unk16_1: int = buff.decode_u16(img_pos + 4) # Number of bits?
							img_type = buff.decode_u16(img_pos + 6) # ex: 3 = RGB
							var unk32_1: int = buff.decode_u32(img_pos + 8)
							var t_w: int = buff.decode_u16(img_pos + 12)
							var t_h: int = buff.decode_u16(img_pos + 14)
							img_pos += 0x10
							
							var tile_buff: PackedByteArray
							var size_mod: int
							var png: Image
							
							if num_parts > 1 and part == num_parts - 1 and h_v_sort == 0x10:
								# Probably a better way at doing this, but I didn't see where this is happening in the header.
								if img_type == 2:
									size_mod = (t_w * t_h) * 2
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_LA8, tile_buff)
								elif img_type == 4:
									size_mod = (t_w * t_h) * 4
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGBA8, tile_buff)
									png.convert(Image.FORMAT_RGB8)
								else:
									size_mod = (t_w * t_h) * 3
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, tile_buff)
									
								if tiled_output:
									png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
									
								var split_png: Array[Image] = split_image(png)
								png_arr.append(split_png[0])
								png_arr.append(split_png[1])
								break
							elif !arc_name == "FACE" and num_parts > 1 and part in range(num_parts - 2, num_parts) and h_v_sort == 0x20:
								if img_type == 2:
									size_mod = (t_w * t_h) * 2
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_LA8, tile_buff)
								elif img_type == 4:
									size_mod = (t_w * t_h) * 4
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGBA8, tile_buff)
									png.convert(Image.FORMAT_RGB8)
								else:
									size_mod = (t_w * t_h) * 3
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, tile_buff)
									
								if tiled_output:
									png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
									
								if part == num_parts - 2:
									# Split a two part image. Stacks the right image under the left.
									var split_png: Image = split_image_stack_vertical(png)
									png_arr.append(split_png)
									img_pos += size_mod
									continue
								elif part == num_parts - 1:
									var split_png: Image = split_image_stack_vertical(png)
									png_arr.append(split_png)
									break
							else:
								if img_type == 2:
									size_mod = (t_w * t_h) * 2
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_LA8, tile_buff)
								elif img_type == 4:
									size_mod = (t_w * t_h) * 4
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGBA8, tile_buff)
									png.convert(Image.FORMAT_RGB8)
								else:
									size_mod = (t_w * t_h) * 3
									tile_buff = buff.slice(img_pos, img_pos + size_mod)
									png = Image.create_from_data(t_w, t_h, false, Image.FORMAT_RGB8, tile_buff)
								
							if part < 8 and f_name == "panoep04.dat":
								png_arr.append(png)
							else:
								png_arr.append(png)
								
							img_pos += size_mod
							if tiled_output:
								png.save_png(folder_path + "/%s" % f_name + "_%04d" % part + ".png")
						else:
							push_error("Image doesn't have a 'PVRT' or 'GBIX' header in file %s part %04d! Skipping." % [f_name, part])
							continue
							
					if h_v_sort == 0x10:
						# Tile columns of 2 vertically
						final_png = tile_images_by_pair(png_arr)
					elif h_v_sort == 0x20:
						# Tile columns of 2 horizontally
						if arc_name == "FACE": # not correct
							final_png = tile_images_by_pair(png_arr)
						else:
							final_png = tile_images_by_pair_hor_vert_right(png_arr)
					else:
						push_error("Image h_v sort is unknown in %s! Image output may be wrong." % f_name)
						final_png = tile_images_by_pair(png_arr)
						
					if final_png != null:
						final_png.save_png(folder_path + "/%s" % f_name + ".png")
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
	
func tile_images_by_pair_hor_vert_left(images: Array[Image]) -> Image:
	# Places the last two images vertically to the left, while the rest are horizontal
	 # Ensure an even number of images
	if images.size() % 2 != 0:
		push_error("The images array must contain an even number of images.")
		return null

	var count = images.size()
	var last_idx = count - 2
	# Prepare main pairs (all except last two)
	var main_pairs = []
	for i in range(0, last_idx, 2):
		main_pairs.append([images[i], images[i+1]])

	# Final column pair
	var col1_img1 = images[last_idx]
	var col1_img2 = images[last_idx + 1]

	# Calculate dimensions
	var col_width = max(col1_img1.get_width(), col1_img2.get_width())
	var col_height = col1_img1.get_height() + col1_img2.get_height()

	var main_width = 0
	var main_height = 0
	var main_dims = []
	for pair in main_pairs:
		var w = pair[0].get_width() + pair[1].get_width()
		var h = max(pair[0].get_height(), pair[1].get_height())
		main_width = max(main_width, w)
		main_height += h
		main_dims.append(Vector2(w, h))

	# Final canvas dimensions
	var final_width = col_width + main_width
	var final_height = max(col_height, main_height)

	var final_image = Image.create_empty(final_width, final_height, false, images[0].get_format())

	# Draw left column images vertically
	var y_off_col = 0
	for img in [col1_img1, col1_img2]:
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				final_image.set_pixel(x, y_off_col + y, img.get_pixel(x, y))
		y_off_col += img.get_height()

	# Draw main pairs to the right of the column
	var y_off_main = 0
	for idx in range(main_pairs.size()):
		var pair = main_pairs[idx]
		var dims = main_dims[idx]
		var img1 = pair[0]
		var img2 = pair[1]
		# img1
		for y in range(img1.get_height()):
			for x in range(img1.get_width()):
				final_image.set_pixel(col_width + x, y_off_main + y, img1.get_pixel(x, y))
		# img2
		for y in range(img2.get_height()):
			for x in range(img2.get_width()):
				final_image.set_pixel(col_width + img1.get_width() + x, y_off_main + y, img2.get_pixel(x, y))
		y_off_main += dims.y

	return final_image
	
	
func tile_images_by_pair_hor_vert_right(images: Array[Image]) -> Image:
	# Places the last two images vertically to the right, while the rest are horizontal
	# Ensure an even number of images
	if images.size() % 2 != 0:
		push_error("The images array must contain an even number of images.")
		return null

	var count = images.size()
	var last_idx = count - 2

	# Prepare main pairs (all except last two)
	var main_pairs = []
	for i in range(0, last_idx, 2):
		main_pairs.append([images[i], images[i+1]])

	# Final column pair for the right side
	var col_img1 = images[last_idx]
	var col_img2 = images[last_idx + 1]

	# Calculate dimensions
	var col_width = max(col_img1.get_width(), col_img2.get_width())
	var col_height = col_img1.get_height() + col_img2.get_height()

	var main_width = 0
	var main_height = 0
	var main_dims = []
	for pair in main_pairs:
		var w = pair[0].get_width() + pair[1].get_width()
		var h = max(pair[0].get_height(), pair[1].get_height())
		main_width = max(main_width, w)
		main_height += h
		main_dims.append(Vector2(w, h))

	# Final canvas dimensions: main section first, then column on the right
	var final_width = main_width + col_width
	var final_height = max(main_height, col_height)

	var final_image = Image.create_empty(final_width, final_height, false, images[0].get_format())

	# Draw main pairs on the left
	var y_off_main = 0
	for idx in range(main_pairs.size()):
		var pair = main_pairs[idx]
		var dims = main_dims[idx]
		var img1 = pair[0]
		var img2 = pair[1]
		# Left image of pair
		for y in range(img1.get_height()):
			for x in range(img1.get_width()):
				final_image.set_pixel(x, y_off_main + y, img1.get_pixel(x, y))
		# Right image of pair
		for y in range(img2.get_height()):
			for x in range(img2.get_width()):
				final_image.set_pixel(img1.get_width() + x, y_off_main + y, img2.get_pixel(x, y))
		y_off_main += dims.y

	# Draw column images on the right
	var y_off_col = 0
	for img in [col_img1, col_img2]:
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				final_image.set_pixel(main_width + x, y_off_col + y, img.get_pixel(x, y))
		y_off_col += img.get_height()

	return final_image


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
	
	
func split_image_stack_vertical(png: Image) -> Image:
	# original dimensions
	var w: int = png.get_width()      # e.g. 256
	var h: int = png.get_height()     # e.g. 256
	var half_w: int = w / 2           # 128

	# extract the two halves
	var left_half: Image = png.get_region(Rect2i(0, 0, half_w, h))
	var right_half: Image = png.get_region(Rect2i(half_w, 0, half_w, h))

	# create output image twice as tall
	var out: Image = Image.create_empty(half_w, h * 2, false, png.get_format())

	# blit left into top (dest at 0,0)
	out.blit_rect(left_half,  Rect2i(0, 0, half_w, h), Vector2i(0, 0))
	# blit right into bottom (dest at 0,h)
	out.blit_rect(right_half, Rect2i(0, 0, half_w, h), Vector2i(0, h))

	return out
	
	
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
