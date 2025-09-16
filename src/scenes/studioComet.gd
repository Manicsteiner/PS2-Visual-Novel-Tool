extends Control

@onready var file_load_bins: FileDialog = $FILELoadBINS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_exe: FileDialog = $FILELoadEXE

var selected_files: PackedStringArray = []
var exe_path: String = ""
var folder_path: String = ""

#TODO: Missing other exe offsets to files? Seems like some TIM2 files are in the single files still

func _ready() -> void:
	file_load_exe.filters = ["SLPS_255.40"]
	file_load_bins.filters = ["
	A00A, A00B, A00C, A00D,
	A00E, A003, A005, A001,
	A002, A003, A004, A005,
	A006, A007, A008"]
	


func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract()
		selected_files.clear()
		folder_path = ""
		
		
func extract() -> void:
	const PACKED_FILES: PackedStringArray = ["A00A", "A00C", "A00E", "A002", "A006"]
	const EXE_FILES: PackedStringArray = ["A005"]
	
	for file in range(0, selected_files.size()):
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		var base_dir: String = "%s/%s" % [folder_path, arc_name]
		
		var f_len: int = in_file.get_length()
		if arc_name in PACKED_FILES:
			var offsets: Array[int] = []
			var pos: int = 0
			while pos + 4 <= f_len:
				in_file.seek(pos)
				var off: int = in_file.get_32()
				if off == 0:
					break
				offsets.append(off)
				if pos > 0 and pos == offsets[0]:
					offsets.append(f_len)
					break
				pos += 4
				
			for i in range(offsets.size() - 1):
				var f_off: int = offsets[i]
				var end_: int = offsets[i + 1]
				var f_size: int = end_ - f_off
				if f_size <= 0 or f_size > 0xFFFFFFFF or f_off < 0 or f_off > 0xFFFFFFFF or end_ > f_len:
					continue
				
				in_file.seek(f_off)
				var buff: PackedByteArray = decompress(in_file.get_buffer(f_size))
				var ext: String = ".BIN"
				if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					ext = ".TM2"
					
				var f_name: String = "%s_%04d%s" % [arc_name, i, ext]
				
				var out_path: String = folder_path.path_join(f_name)
				var out_file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
				if out_file:
					print("%08X %08X %s" % [f_off, buff.size(), out_path])
					
					var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, true)
					for png_i in range(pngs.size()):
						var png: Image = pngs[png_i]
						png.save_png("%s_%04d.PNG" % [out_path, png_i])
					out_file.store_buffer(buff)
					out_file.close()
		if arc_name in EXE_FILES:
			if !exe_path:
				OS.alert("Exe needs to be loaded for file %s" % arc_name)
				continue
				
			var tbl_start: int = 0
			var tbl_end: int = 0
			if arc_name == "A005":
				tbl_start = 0x305020
				tbl_end = 0x3072D8
				
			var exe_file: FileAccess = FileAccess.open(exe_path, FileAccess.READ)
			var id: int = 0
			for pos in range(tbl_start, tbl_end, 8):
				#if id != 480:
					#id += 1
					#continue
				exe_file.seek(pos)
				var f_off: int = exe_file.get_32()
				var f_size: int = exe_file.get_32()
				
				in_file.seek(f_off)
				var buff: PackedByteArray = decompress(in_file.get_buffer(f_size))
				var ext: String = ".BIN"
				if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					ext = ".TM2"
					
				var f_name: String = "%s_%04d%s" % [arc_name, id, ext]
				
				var out_path: String = folder_path.path_join(f_name)
				var out_file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
				if out_file:
					print("%08X %08X %s" % [f_off, buff.size(), out_path])
					
					var pngs: Array[Image] = load_tim2_images_mod(buff, true)
					for png_i in range(pngs.size()):
						var png: Image = pngs[png_i]
						png.save_png("%s_%04d.PNG" % [out_path, png_i])
					out_file.store_buffer(buff)
					out_file.close()
				id += 1
		else:
			in_file.seek(0)
			var buff: PackedByteArray = decompress(in_file.get_buffer(in_file.get_length()))
			var ext: String = ".BIN"
			if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
				ext = ".TM2"
				
			var f_name: String = "%s_%s" % [arc_name, ext]
			var out_path: String = folder_path.path_join(f_name)
			var out_file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
			if out_file:
				print("%08X %s" % [buff.size(), out_path])
				
				var pngs: Array[Image] = load_tim2_images_mod(buff, true)
				for png_i in range(pngs.size()):
					var png: Image = pngs[png_i]
					png.save_png("%s_%04d.PNG" % [out_path, png_i])
				out_file.store_buffer(buff)
				out_file.close()
	
	
func load_tim2_images_mod(data: PackedByteArray, fix_alpha: bool = true) -> Array[Image]:
	var images: Array[Image] = []

	# Check magic
	if data.slice(0, 4).get_string_from_ascii() != "TIM2":
		push_error("Not a TIM2 file")
		return images

	var tm2_version: int = data.decode_u8(5)
	if tm2_version > 1:
		push_error("Unknown TIM2 version %02X" % tm2_version)
		return images
		
	var picture_count: int = data.decode_u16(6)
	if picture_count <= 0:
		push_error("No pictures found")
		return images
		
	var unswizzle_palette_tm2: Callable = func (pal_buffer: PackedByteArray, nbpp: int, pal_size: int = pal_buffer.size()) -> PackedByteArray:
		var num_colors: int = pal_size / nbpp
		var pal: PackedByteArray
		pal.resize(pal_size)

		if num_colors > 256:
			# Handle multiple 256-color banks separately
			var banks: int = num_colors / 256
			for b in range(banks):
				for p in range(256):
					var pos: int = (p & 231) + ((p & 8) << 1) + ((p & 16) >> 1)
					if pos < 256:
						for i in range(nbpp):
							var src: int = (b * 256 + p) * nbpp + i
							var dst: int = (b * 256 + pos) * nbpp + i
							pal[dst] = pal_buffer[src]
		else:
			# Normal single-bank swizzle
			for p in range(num_colors):
				var pos: int = (p & 231) + ((p & 8) << 1) + ((p & 16) >> 1)
				if pos < num_colors:
					for i in range(nbpp):
						pal[pos * nbpp + i] = pal_buffer[p * nbpp + i]
		return pal

	var pic_offset: int = 0x10
	for p in range(picture_count):
		if tm2_version == 1: pic_offset += 0x70
		var total_size: int = data.decode_u32(pic_offset)
		var clut_size: int = data.decode_u32(pic_offset + 4)
		var img_size: int = data.decode_u32(pic_offset + 8)
		var header_size: int = data.decode_u16(pic_offset + 0x0C)
		var clut_colors: int = data.decode_u16(pic_offset + 0x0E)
		var pic_format: int = data.decode_u8(pic_offset + 0x10)
		var mipmap_count: int = data.decode_u8(pic_offset + 0x11)
		var clut_color_type: int = data.decode_u8(pic_offset + 0x12)
		var img_color_type: int = data.decode_u8(pic_offset + 0x13)
		var width: int = data.decode_u16(pic_offset + 0x14)
		var height: int = data.decode_u16(pic_offset + 0x16)

		var img_data_offset: int = pic_offset + header_size
		var clut_data_offset: int = img_data_offset + img_size

		# --- Palette (CLUT) ---
		var palette: Array[Color] = []
		if clut_size > 0:
			var pal_bytes: PackedByteArray = data.slice(clut_data_offset, clut_data_offset + clut_size)
			#if is_swizzled and clut_colors == 256:
			if clut_color_type & 128 == 0 and (clut_colors == 256 or clut_colors == 512):
				var nbpp: int = 4
				if clut_size == clut_colors * 2: nbpp = 2
				pal_bytes = unswizzle_palette_tm2.call(pal_bytes, nbpp)
				
			# Apply alpha correction ONLY for indexed formats
			if fix_alpha:
				if clut_size == clut_colors * 4:
					for j in range(3, pal_bytes.size(), 4):
						var a: int = int((pal_bytes.decode_u8(j) / 128.0) * 255.0)
						pal_bytes.encode_u8(j, a)
						
			# RGBA5551 palette (16-bit entries)
			if clut_size == clut_colors * 2:
				for i in range(clut_colors):
					var px: int = pal_bytes.decode_u16(i * 2)
					var r5: int = (px >> 0) & 0x1F
					var g5: int = (px >> 5) & 0x1F
					var b5: int = (px >> 10) & 0x1F
					var a1: int = (px >> 15) & 0x01

					# expand to 8-bit
					var r: int = (r5 << 3) | (r5 >> 2)
					var g: int = (g5 << 3) | (g5 >> 2)
					var b: int = (b5 << 3) | (b5 >> 2)
					var a: int = 255 if a1 else 0

					palette.append(Color8(r, g, b, a))
			elif clut_size == 128 and clut_colors == 16:
				for i in range(clut_colors):
					var r: int = pal_bytes.decode_u8(i * 4 + 0)
					var g: int = pal_bytes.decode_u8(i * 4 + 1)
					var b: int = pal_bytes.decode_u8(i * 4 + 2)
					var a: int = pal_bytes.decode_u8(i * 4 + 3)
					palette.append(Color8(r, g, b, a))
			# Standard 32-bit RGBA8 palette
			elif clut_size == clut_colors * 4:
				for i in range(clut_colors):
					var r: int = pal_bytes.decode_u8(i * 4 + 0)
					var g: int = pal_bytes.decode_u8(i * 4 + 1)
					var b: int = pal_bytes.decode_u8(i * 4 + 2)
					var a: int = pal_bytes.decode_u8(i * 4 + 3)
					palette.append(Color8(r, g, b, a))
			else:
				push_error("Unexpected CLUT size %d for %d colors" % [clut_size, clut_colors])

		# --- Image decode ---
		var img: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)

		match img_color_type:
			1: 
				# 1: 16-bit A1B5G5R5  (bits: R=0..4, G=5..9, B=10..14, A=15)
				for y in range(height):
					for x in range(width):
						var idx: int = (y * width + x) * 2
						var px: int = data.decode_u16(img_data_offset + idx)
						var a1: int = (px >> 15) & 1
						var r5: int = (px >> 0) & 0x1F
						var g5: int = (px >> 5) & 0x1F
						var b5: int = (px >> 10) & 0x1F
						# expand 5->8 bits (better than <<3):
						var r: int = (r5 << 3) | (r5 >> 2)
						var g: int = (g5 << 3) | (g5 >> 2)
						var b: int = (b5 << 3) | (b5 >> 2)
						var a: int = 255 if a1 else 0
						img.set_pixel(x, y, Color8(r, g, b, a))
			2:  # 24-bit RGB888 -> bytes [R, G, B] per pixel
				for y in range(height):
					for x in range(width):
						var idx: int = (y * width + x) * 3
						var r: int = data.decode_u8(img_data_offset + idx + 0)
						var g: int = data.decode_u8(img_data_offset + idx + 1)
						var b: int = data.decode_u8(img_data_offset + idx + 2)
						var a: int = 255
						img.set_pixel(x, y, Color8(r, g, b, a))
			3:  # 32-bit A8B8G8R8  -> bytes [R, G, B, A] in stream (little-endian)
				for y in range(height):
					for x in range(width):
						var col: int = data.decode_u32(img_data_offset + (y * width + x) * 4)
						var r: int =  col        & 0xFF
						var g: int = (col >> 8)  & 0xFF
						var b: int = (col >> 16) & 0xFF
						var a: int = (col >> 24) & 0xFF
						if fix_alpha: 
							a = int((a / 128.0) * 255.0)
						img.set_pixel(x, y, Color8(r, g, b, a))
			4:  # 4-bit indexed
				for y in range(height):
					for x in range(width):
						var byte: int = data.decode_u8(img_data_offset + ((y * width + x) >> 1))
						var idx: int = (byte & 0x0F) if (x & 1) == 0 else ((byte >> 4) & 0x0F)
						if idx < palette.size():
							img.set_pixel(x, y, palette[idx])
						else:
							img.set_pixel(x, y, Color(0, 0, 0, 1))
			5:  # 8-bit indexed
				if clut_colors > 256:
					# Multi bank palettes. The user will have to choose what parts are correct.
					# There doesn't seem to currently be a way to blend these into one final image.
					var banks: int = clut_colors / 256
					for chosen_bank in range(banks):
						var img_multi_bank: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
						var bank_offset: int = chosen_bank * 256
						for y in range(height):
							for x in range(width):
								var idx: int = data.decode_u8(img_data_offset + y * width + x)
								var pal_idx: int = bank_offset + idx
								if pal_idx < palette.size():
									img_multi_bank.set_pixel(x, y, palette[pal_idx])
								else:
									img_multi_bank.set_pixel(x, y, Color(0, 0, 0, 1))
						images.append(img_multi_bank)
				else:
					for y in range(height):
						for x in range(width):
							var idx: int = data.decode_u8(img_data_offset + y * width + x)
							if idx < palette.size():
								img.set_pixel(x, y, palette[idx])
							else:
								img.set_pixel(x, y, Color(0, 0, 0, 1))
			_:
				push_error("Unsupported TIM2 image color type: %d" % img_color_type)

		images.append(img)

		# Move to next picture block
		pic_offset += total_size

	return images
	
	
func decompress(data: PackedByteArray) -> PackedByteArray:
	var expected_size: int = 0
	for i in range(3):
		expected_size = (expected_size << 8) | data.decode_u8(i)

	var out := PackedByteArray()
	out.resize(expected_size)

	var src: int = 3  # compressed stream starts after the 3-byte header
	var dst: int = 0

	while dst < expected_size and src < data.size():
		var ctrl_byte: int = data.decode_u8(src)
		src += 1

		if (ctrl_byte & 0x80) == 0:
			# literal run: copy (ctrl + 1) bytes
			var count: int = ctrl_byte + 1
			for i in range(count):
				if src >= data.size():
					print("decompress: input overrun during literal run")
					break
				if dst >= expected_size:
					break
				out[dst] = data.decode_u8(src)
				src += 1
				dst += 1
		else:
			# backreference:
			# length = ((ctrl & 0x7C) >> 2) + 3
			# offset = ((ctrl & 0x03) << 8) | next_byte
			var length: int = ((ctrl_byte & 0x7C) >> 2) + 3
			var offset: int = ((ctrl_byte & 0x03) << 8)
			if src >= data.size():
				print("decompress: missing offset byte for backreference")
				break
			offset |= data.decode_u8(src)
			src += 1

			var ref_pos: int = dst - offset - 1
			if ref_pos < 0:
				ref_pos = 0

			for i in range(length):
				if dst >= expected_size:
					break
				var read_index := ref_pos + i
				if read_index >= out.size():
					print("decompress: invalid backref read_index", read_index)
					break
				out[dst] = out[read_index]
				dst += 1
	return out


func _on_load_bin_pressed() -> void:
	file_load_bins.show()


func _on_file_load_bins_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path
