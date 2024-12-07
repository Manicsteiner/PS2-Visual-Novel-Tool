extends Control

@onready var file_load_dat: FileDialog = $FILELoadDAT
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var remove_alpha_button: CheckBox = $VBoxContainer/removeAlphaButton

var folder_path:String
var selected_files: PackedStringArray
var chose_files: bool = false
var chose_folder: bool = false
var out_decomp: bool = false
var remove_alpha: bool = false

func _ready() -> void:
	if Main.game_type == Main.OUKA:
		remove_alpha_button.visible = true
	else:
		remove_alpha_button.visible = false
		
		
func _process(_delta: float) -> void:
	if chose_files and chose_folder:
		extract()
		selected_files.clear()
		chose_files = false
		chose_folder = false


func extract() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var png: Image
	var offset: int
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		f_name = selected_files[i].get_file()
		
		
		buff = in_file.get_buffer(in_file.get_length())
		
		if Main.game_type == Main.OUKA:
			var width: int = buff.decode_u16(0x12)
			var height: int = buff.decode_u16(0x16)
			var bpp: int = buff.decode_u16(0x1C)

			if bpp == 24:
				buff = decompressBmp(buff)
				png = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buff)
			elif bpp == 32:
				buff = decompressBmp(buff)
				png = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
			elif bpp == 8:
				# Not compressed. Just change the header to BM for BMP
				buff.encode_u8(0, 0x42)
				buff.encode_u8(1, 0x4D)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				#print("0x%08X 0x%08X %s/%s" % [offset, buff.size(), folder_path, f_name])
				print("0x%08X %s/%s" % [buff.size(), folder_path, f_name])
				in_file.close()
				continue
			else:
				print("Unknown BPP %02d in %s" % [bpp, f_name])
				in_file.close()
				
				if out_decomp:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
					in_file.seek(0)
					in_file.get_length()
					out_file.store_buffer(buff)
					out_file.close()
					
				continue
			
			#print("0x%08X 0x%08X %s/%s" % [offset, buff.size(), folder_path, f_name])
			print("0x%08X %s/%s" % [buff.size(), folder_path, f_name])
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			
			if out_decomp:
				out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
				in_file.seek(0)
				in_file.get_length()
				out_file.store_buffer(buff)
				out_file.close()
		else:
			pass
			
		buff.clear()
		in_file.close()
		
	print_rich("[color=green]Finished![/color]")

func decompressBmp(compressed_data: PackedByteArray) -> PackedByteArray:
	# Read the BMP file header information
	var width: int = compressed_data.decode_u16(0x12)  # Offset 0x12: Width
	var height: int = compressed_data.decode_u16(0x16)  # Offset 0x16: Height
	var bpp: int = compressed_data.decode_u16(0x1C)  # Offset 0x1C: Bits Per Pixel
	
	# Prepare buffers for decompression
	var decompressed_data = PackedByteArray()

	# Check if the image is 24bpp
	#if bpp != 24 or bpp != 32:
		#print("Only 24bpp BMP supported!")
		#return PackedByteArray()

	# Calculate bytes per pixel and padded row size
	var bytes_per_pixel: int = bpp / 8  # 3 bytes for 24bpp
	var row_size: int = width * bytes_per_pixel  # Width of the row without padding
	var padded_row_size: int = (row_size + 3) & ~3  # Align row size to a 4-byte boundary

	var read_pos: int = 0x36  # Start of pixel data
	var write_pos: int = 0  # Start writing at the top of the image
	
	if bpp == 24:
		decompressed_data.resize(height * padded_row_size)
		
		# Decompress image data (top to bottom)
		while read_pos < compressed_data.size():
			var control_byte: int = compressed_data[read_pos]
			read_pos += 1

			if control_byte & 0x80 == 0:  # Literal data
				for i in range(control_byte):
					if write_pos + bytes_per_pixel > decompressed_data.size():
						print("Write position exceeds buffer size!")
						return decompressed_data
					
					for j in range(bytes_per_pixel):
						if read_pos < compressed_data.size():
							decompressed_data.encode_u8(write_pos + j, compressed_data[read_pos])
							read_pos += 1
					write_pos += bytes_per_pixel
			else:  # Repeated data
				var repeat_count: int = control_byte & 0x7F
				var repeat_color: PackedByteArray = compressed_data.slice(read_pos, read_pos + bytes_per_pixel)
				read_pos += bytes_per_pixel

				for i in range(repeat_count):
					if write_pos + bytes_per_pixel > decompressed_data.size():
						print("Write position exceeds buffer size!")
						return decompressed_data
					
					for j in range(bytes_per_pixel):
						decompressed_data.encode_u8(write_pos + j, repeat_color[j])
					write_pos += bytes_per_pixel
	elif bpp == 32:
		decompressed_data.resize(height * padded_row_size)
		
		# Decompress image data (top to bottom)
		while read_pos < compressed_data.size():
			var control_byte: int = compressed_data[read_pos]
			read_pos += 1

			if control_byte & 0x80 == 0:  # Literal data
				for i in range(control_byte):
					if write_pos + bytes_per_pixel > decompressed_data.size():
						print("Write position exceeds buffer size!")
						return decompressed_data
					if read_pos >= compressed_data.size():
						push_warning("Read position exceeds compressed buffer size! (data should be fine?)")
						break
						
					# Read ABGR color components
					var a: int = compressed_data[read_pos]
					var r: int = compressed_data[read_pos + 1]
					var g: int = compressed_data[read_pos + 2]
					var b: int = compressed_data[read_pos + 3]
					read_pos += 4

					if remove_alpha:
						a = 255
					else:
						# Special alpha handling
						if a == 0xFF:
							a = 0x80
						elif a == 0x01:
							a = 0x01
						else:
							a = a >> 1

					# Write in RGBA order
					decompressed_data.encode_u8(write_pos, r)
					decompressed_data.encode_u8(write_pos + 1, g)
					decompressed_data.encode_u8(write_pos + 2, b)
					decompressed_data.encode_u8(write_pos + 3, a)
					write_pos += 4
			else:  # Repeated data
				var repeat_count: int = control_byte & 0x7F
				var a: int = compressed_data[read_pos]
				var r: int = compressed_data[read_pos + 1]
				var g: int = compressed_data[read_pos + 2]
				var b: int = compressed_data[read_pos + 3]
				read_pos += 4

				if remove_alpha:
					a = 255
				else:
					# Special alpha handling
					if a == 0xFF:
						a = 0x80
					elif a == 0x01:
						a = 0x01
					else:
						a = a >> 1

				for i in range(repeat_count):
					decompressed_data.encode_u8(write_pos, r)
					decompressed_data.encode_u8(write_pos + 1, g)
					decompressed_data.encode_u8(write_pos + 2, b)
					decompressed_data.encode_u8(write_pos + 3, a)
					write_pos += 4
	#elif bpp == 8:
		## Just change the header to BM for BMP
		#compressed_data.encode_u8(0, 0x42)
		#compressed_data.encode_u8(1, 0x4D)
		#return compressed_data
	else:
		print("Unknown BPP %02d!" % bpp)
		return decompressed_data
		
	# Flip the image vertically
	for row in range(height / 2):
		# Calculate starting indices of the rows to swap
		var top_row_start: int = row * padded_row_size
		var bottom_row_start: int = (height - 1 - row) * padded_row_size

		# Swap rows
		for col in range(padded_row_size):
			var temp: int = decompressed_data.decode_u8(top_row_start + col)
			decompressed_data.encode_u8(top_row_start + col, decompressed_data.decode_u8(bottom_row_start + col))
			decompressed_data.encode_u8(bottom_row_start + col, temp)

	# Return the vertically flipped buffer
	return decompressed_data


func _on_load_dat_pressed() -> void:
	file_load_dat.visible = true


func _on_file_load_dat_files_selected(paths: PackedStringArray) -> void:
	file_load_dat.visible = false
	file_load_folder.visible = true
	chose_files = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true


func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
