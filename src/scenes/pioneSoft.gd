extends Control

@onready var pione_load_folder: FileDialog = $PIONELoadFOLDER
@onready var pione_load_saf: FileDialog = $PIONELoadSAF
@onready var load_exe: Button = $HBoxContainer/LoadEXE
@onready var pione_load_exe: FileDialog = $PIONELoadEXE


var chose_file: bool = false
var chose_folder: bool = false
var folder_path: String
var chose_saf: bool = false
var usr_files: PackedStringArray
var fix_alpha: bool = true
var out_decomp: bool = false
var exe_path: String = ""

func _ready() -> void:
	if Main.game_type == Main.ORANGEPOCKET:
		load_exe.visible = true
	else:
		load_exe.visible = false
		
	
func _process(_delta):
	if chose_saf and chose_folder:
		makeFiles()
		usr_files.clear()
		chose_folder = false
		chose_saf = false
		exe_path = ""
	elif exe_path and chose_folder:
		extractFromExe()
		usr_files.clear()
		chose_folder = false
		chose_saf = false
		exe_path = ""
		
	
func makeFiles() -> void:
	var file: FileAccess
	var new_file: FileAccess
	var file_name: String
	var img_type: int
	var img_bpp_type: int
	var buff: PackedByteArray
	var num_files: int
	var f_name: String
	var f_size: int
	var f_offset: int
	var dec_size: int
	var unk32: int
	var out_file: FileAccess
	var saf_type: int
	var saf_file_tbl_size: int
	var ext: String
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	# TODO: Proper zlib decompression.
	
	for i in range(0, usr_files.size()):
		file = FileAccess.open(usr_files[i], FileAccess.READ)
		file_name = usr_files[i].get_file()
		if file.get_32() != 0x30464153:
			OS.alert("Invalid SAF archive %s" % file_name)
			file.close()
			continue
			
		saf_type = file.get_32()
		if saf_type == 1:
			saf_file_tbl_size = 0x20
		elif saf_type == 2:
			saf_file_tbl_size = 0x30
		else:
			OS.alert("Unknown SAF type %04X" % saf_type)
			file.close()
			continue
			
		file.seek(0xC)
		num_files = file.get_32()
		for saf_files in range(0, num_files):
			file.seek((saf_files * saf_file_tbl_size) + 0x10)
			unk32 = file.get_32()
			f_offset = file.get_32()
			f_size = file.get_32()
			dec_size = file.get_32()
			f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(file, 0)[1], shift_jis_dic).get_string_from_utf8()
			
			file.seek(f_offset)
			if f_size != dec_size:
				buff = ComFuncs.decompress_raw_zlib(file.get_buffer(f_size))
			else:
				buff = file.get_buffer(f_size)
			
			# for images
			if buff.decode_u16(0) == 0x3254:
				if out_decomp:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				img_bpp_type = buff.decode_u8(2)
				img_type = buff.decode_u8(3)
				
				var png: Image = make_image(buff)
				png.save_png(folder_path + "/%s" % f_name + ".PNG")
				
				print("%08X " % f_offset, "%08X " % dec_size + "%02X " % img_bpp_type + "%02X " % img_type + "%s" % folder_path + "/%s" % f_name)
			else:
				if buff.decode_u32(0) == 0x324D4954:
					ext = ".TM2"
					var pngs: Array[Image] = load_tim2_images_mod(buff, false)
					for p in range(pngs.size()):
						var png: Image = pngs[p]
						png.save_png(folder_path + "/%s" % f_name + ext + "_%04d.PNG" %  p)
				elif buff.decode_u32(0) == 0x30464153:
					ext = ".SAF"
				else:
					ext = ".BIN"
					
				out_file = FileAccess.open(folder_path + "/%s" % f_name + ext, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				buff.clear()
			
				print("%08X " % f_offset, "%08X " % dec_size + "%s" % folder_path + "/%s" % f_name)
		
		
	print_rich("[color=green]Finished![/color]")


func extractFromExe() -> void:
	# Extract unused scripts that is likely from another game
	
	var script_saf_name: String = "SCRIPT.SAF"
	var saf_off: int = 0x0013A6A0
	var out_file: FileAccess
	var file: FileAccess
	var saf_size: int
	var buff: PackedByteArray
	
	file = FileAccess.open(exe_path, FileAccess.READ)
	
	file.seek(saf_off + 0x8)
	saf_size = file.get_32()
	file.seek(saf_off)
	buff = file.get_buffer(saf_size)
	
	file.close()
	
	out_file = FileAccess.open(folder_path + "/%s" % script_saf_name, FileAccess.WRITE)
	out_file.store_buffer(buff)
	out_file.close()
	buff.clear()
	
	print("%08X " % saf_off, "%08X " % saf_size + "%s" % folder_path + "/%s" % script_saf_name)
	print_rich("[color=green]Finished![/color]")
	
	
func make_image(data: PackedByteArray) -> Image:
	var img_bpp_type: int = data.decode_u8(2)
	var img_type: int = data.decode_u8(3)
	var image_width: int = data.decode_u16(0xC) & 0xFFF
	var image_height: int = data.decode_u16(0xE) & 0xFFF
	var palette_size: int

	if img_type == 0x13:
		image_width = (image_width + 7) >> 3 << 19 >> 16
	elif img_type == 0x14:
		image_width = (image_width + 0xF) >> 4 << 20 >> 16
	elif img_type == 2:
		image_width = (image_width + 3) >> 2 << 18 >> 16

	if img_bpp_type & 1 == 1:
		palette_size = 0x400
		if img_bpp_type & 2 == 0: 
			palette_size = 0x40

	var palette_offset: int = 0x10
	var palette: PackedByteArray = PackedByteArray()
	for i in range(palette_size):
		palette.append(data.decode_u8(palette_offset + i))

	if img_type == 0x13:
		palette = ComFuncs.unswizzle_palette(palette, 32)

	if fix_alpha and (img_type == 0x13 or img_type == 0x14):
		for i in range(0, palette_size, 4):
			palette.encode_u8(i + 3, int((palette.decode_u8(i + 3) / 128.0) * 255.0))

	var image_data_offset: int = palette_offset + palette_size
	var pixel_data: PackedByteArray = data.slice(image_data_offset)

	var image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)

	if img_type == 0x13 or img_type == 2:
		# 8-bit image
		for y in range(image_height):
			for x in range(image_width):
				var pixel_index: int = pixel_data[x + y * image_width]
				var r: int = palette[pixel_index * 4 + 0]
				var g: int = palette[pixel_index * 4 + 1]
				var b: int = palette[pixel_index * 4 + 2]
				var a: int = palette[pixel_index * 4 + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	elif img_type == 0x14:
		# 4-bit image
		var row_bytes: int = (image_width + 1) >> 1  # Bytes per row
		for y in range(image_height):
			var row_start: int = y * row_bytes
			for bx in range(row_bytes):
				var byte_value: int = pixel_data[row_start + bx]
				# Left pixel
				var x1: int = bx * 2
				var pixel_index_1 = byte_value & 0xF
				var r1: int = palette[pixel_index_1 * 4 + 0]
				var g1: int = palette[pixel_index_1 * 4 + 1]
				var b1: int = palette[pixel_index_1 * 4 + 2]
				var a1: int = palette[pixel_index_1 * 4 + 3]
				image.set_pixel(x1, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

				# Right pixel, only if within width
				var x2: int = x1 + 1
				if x2 < image_width:
					var pixel_index_2 = (byte_value >> 4) & 0xF
					var r2: int = palette[pixel_index_2 * 4 + 0]
					var g2: int = palette[pixel_index_2 * 4 + 1]
					var b2: int = palette[pixel_index_2 * 4 + 2]
					var a2: int = palette[pixel_index_2 * 4 + 3]
					image.set_pixel(x2, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	else:
		push_error("Unknown img_type")

	return image
	
	
func load_tim2_images_mod(data: PackedByteArray, fix_alpha: bool = true) -> Array[Image]:
	# Don't move + 16 after next picture
	
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
		# pal_size = total bytes in palette
		# nbpp     = bytes per palette entry (2 for RGBA5551, 4 for RGBA8888, etc.)
		var num_colors: int = pal_size / nbpp
		var pal: PackedByteArray
		pal.resize(pal_size)
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
			if clut_color_type & 128 == 0 and clut_colors == 256:
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
	
	
func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp


func _on_load_saf_pressed() -> void:
	pione_load_saf.visible = true
	
	
func _on_pione_load_folder_dir_selected(dir):
	folder_path = dir
	chose_folder = true
	
	
func _on_pione_load_saf_files_selected(paths):
	pione_load_saf.visible = false
	pione_load_folder.visible = true
	usr_files = paths
	chose_saf = true


func _on_load_exe_pressed() -> void:
	pione_load_exe.visible = true


func _on_pione_load_exe_file_selected(path: String) -> void:
	pione_load_exe.visible = false
	pione_load_folder.visible = true
	exe_path = path


func _on_fix_alpha_toggled(_toggled_on: bool) -> void:
	fix_alpha = !fix_alpha
