extends Node

@onready var regista_load_spc: FileDialog = $REGISTALoadSPC
@onready var regista_load_folder: FileDialog = $REGISTALoadFOLDER


var chose_file:bool = false
var chose_folder:bool = false
var folder_path:String

var chose_spc:bool = false
var selected_files:PackedStringArray

var out_decomp:bool = false
	
	
func _process(_delta):
	if chose_spc and chose_folder:
		makeSpcFiles()
		chose_folder = false
		chose_spc = false
		selected_files.clear()
	
	
func _on_load_spc_pressed():
	regista_load_spc.visible = true
	
	
func _on_regista_load_folder_dir_selected(dir):
	folder_path = dir
	chose_folder = true
	
	
func _on_decomp_button_toggled(_toggled_on):
	out_decomp = !out_decomp
	
	
func _on_regista_load_spc_files_selected(paths):
	regista_load_spc.visible = false
	regista_load_folder.visible = true
	selected_files = paths
	chose_spc = true
	
	
func makeSpcFiles() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var file_size: int
	var file_name: String
	var image_type: int
	var width: int
	var height: int
	var header_start: int
	var tile_size: int = 128
	
	for a in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[a], FileAccess.READ)
		file_name = selected_files[a].get_file()
		
		in_file.seek(0)
		file_size = in_file.get_32()
		
		buff = ComFuncs.decompLZSS(in_file.get_buffer(in_file.get_length()), in_file.get_length(), file_size)
		
		if out_decomp:
			out_file = FileAccess.open(folder_path + "/%s" % file_name + ".DEC", FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
		header_start = buff.decode_u32(0)
		
		if header_start > file_size:
			print("Header is larger than file size in file %s. Skipping." % file_name)
			continue
			
		width = buff.decode_u16(header_start + 4)
		height = buff.decode_u16(header_start + 6)
		image_type = buff.decode_u8(header_start + 0xC)
		
		if image_type == 3:
			buff = buff.slice(header_start + 0x10)
			var image: Image = ComFuncs.create_tiled_image_vertically(buff, width, height, tile_size)
			image.save_png(folder_path + "/%s" % file_name + ".png")
		elif image_type == 5:
			#don't know yet. tile size is 128.
			buff = buff.slice(header_start + 0x10)
			var tga:PackedByteArray = ComFuncs.makeTGAHeader(true, 1, 8, 8, width, height)
			var pal_dat: PackedByteArray = ComFuncs.unswizzle_palette(buff.slice(0, 0x400), 32)
			tga.append_array(pal_dat)
			tga.append_array(buff.slice(0x400))
			out_file = FileAccess.open(folder_path + "/%s" % file_name + ".TGA", FileAccess.WRITE)
			out_file.store_buffer(tga)
			out_file.close()
			#buff = buff.slice(header_start + 0x10)
			#var swapped_buff: PackedByteArray = buff.slice(0x400)
			#swapped_buff.append_array(buff.slice(0, 0x400))
			#var image: Image = ComFuncs.processImg(swapped_buff, 0, width, height, 8, swapped_buff.size() - 0x400)
			#image.save_png(folder_path + "/%s" % file_name + ".png")
		else:
			push_error("Unknown image type '%X' in '%s'. Skipping." % [image_type, file_name])
			buff.clear()
			continue
			
		buff.clear()
		print("0x%08X " % file_size + folder_path + "/%s" % file_name)
	
	print_rich("[color=green]Finished![/color]")
	
	
func create_tiled_image_vertically_grey(image_data: PackedByteArray, final_width: int, final_height: int, tile_size: int) -> PackedByteArray:
	# Calculate the number of tiles along width and height
	var tiles_x:int = final_width / tile_size
	var tiles_y:int = final_height / tile_size
	
	# Expected bytes per tile (each tile is tile_size * tile_size pixels, 1 byte per pixel for greyscale)
	var tile_data_size:int = tile_size * tile_size  # 1 byte per pixel for greyscale (L8)
	
	# Create a new PackedByteArray to store the final image data
	var final_image_data:PackedByteArray = PackedByteArray()
	
	# Loop through each tile and place it in the final image
	for x in range(tiles_x):  # Loop through columns first for vertical tiling
		for y in range(tiles_y):  # Then loop through rows
			# Calculate the offset in the data for the current tile
			var tile_index:int = (x * tiles_y + y) * tile_data_size
				
			# Ensure we don't exceed the length of the data
			if tile_index + tile_data_size > image_data.size():
				push_error("Data size is smaller than expected for the given tile dimensions.")
				return final_image_data
				
			var tile_data:PackedByteArray = image_data.slice(tile_index, tile_index + tile_data_size)
			
			# Append the tile data directly to the final image data in the correct position
			for ty in range(tile_size):
				for tx in range(tile_size):
					if tx < tile_size and ty < tile_size:
						# Append the grayscale pixel value (which is already in the correct format)
						final_image_data.append(tile_data[ty * tile_size + tx])
						
	# Return the final PackedByteArray containing the greyscale pixel data
	return final_image_data


func create_tiled_image_vertically(image_data: PackedByteArray, final_width: int, final_height: int, tile_size: int) -> Image:
	# Calculate the number of tiles along width and height
	var tiles_x:int = final_width / tile_size
	var tiles_y:int = final_height / tile_size
	
	# Expected bytes per tile for RGBA8 format
	var tile_data_size:int = tile_size * tile_size * 4  # 4 bytes per pixel for RGBA8 format
	
	# Create the final image with the specified width and height
	var final_image:Image = Image.create_empty(final_width, final_height, false, Image.FORMAT_RGBA8)
	
	# Loop through each tile and place it in the final image
	for x in range(tiles_x):  # Loop through columns first for vertical tiling
		for y in range(tiles_y):  # Then loop through rows
			# Calculate the offset in the data for the current tile
			var tile_index:int = (x * tiles_y + y) * tile_data_size
				
			# Ensure we don't exceed the length of the data
			if tile_index + tile_data_size > image_data.size():
				push_error("Data size is smaller than expected for the given tile dimensions.")
				return final_image
				
			var tile_data:PackedByteArray = image_data.slice(tile_index, tile_index + tile_data_size)
			
			# Create an image for the tile and populate it with the raw data
			var tile_image:Image = Image.create_from_data(tile_size, tile_size, false, Image.FORMAT_RGBA8, tile_data)
			
			# Copy the tile into the correct position in the final image
			for ty in range(tile_size):
				for tx in range(tile_size):
					if tx < tile_image.get_width() and ty < tile_image.get_height():
						var color:Color = tile_image.get_pixel(tx, ty)
						final_image.set_pixel(x * tile_size + tx, y * tile_size + ty, color)
			
	return final_image
	
	
func processImg(data:PackedByteArray, imgdat_off:int, w:int, h:int, bpp:int, pal_pos:int) -> Image:
	# Original function by Irdkwia from Python script
	
	var imgdat:PackedByteArray = data.slice(imgdat_off, pal_pos)
	imgdat = tobpp(imgdat, bpp)
	
	var paldat:PackedByteArray = data.slice(pal_pos)
	
	for x in range(0, len(paldat), 4):
		paldat[x+3] = min(255, paldat[x+3]*2)
		
	var resdata:PackedByteArray
	for y in range(h):
		for x in range(w):
			var index:int = imgdat[y * w + x] * 4
			var end_index:int = index + 4
			resdata.append_array(paldat.slice(index, end_index))
			
	var png:Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, resdata)
	
	return png
	
func tobpp(data:PackedByteArray, bpp:int) -> PackedByteArray:
	# Original function by Irdkwia from Python script
	
	var out:PackedByteArray
	var p:int
	
	if bpp not in [1, 2, 4, 8]:
		push_error("Unsupported BPP %s " % bpp)
		
	var m:int = (1<<bpp)-1
	for b in data:
		for x in range(8/bpp):
			if bpp==8:
				var swizzle:int = b&m
				p = (swizzle&0xE7)|((swizzle&0x10)>>1)|((swizzle&0x8)<<1)
			else:
				p = b&m
			out.append(p)
			b>>=bpp
			
	return out
