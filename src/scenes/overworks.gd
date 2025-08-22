extends Control

@onready var file_load_grd: FileDialog = $FILELoadGRD
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_cvm: FileDialog = $FILELoadCVM

var selected_grds: PackedStringArray
var selected_exe: String = ""
var folder_path: String = ""
var tile_output: bool = true

#TODO: Images are an unknown custom Dreamcast PVRT format with swizzeled image data. Header at 0x1C contains a bunch of Vector4 floats for tile positions.

func _ready() -> void:
	file_load_grd.filters = ["*.GRD"]
	

func _process(_delta: float) -> void:
	if selected_grds and folder_path:
		create_grd()
		selected_grds.clear()
		folder_path
		
		
func create_grd() -> void:
	for grd: int in selected_grds.size():
		var in_file: FileAccess = FileAccess.open(selected_grds[grd], FileAccess.READ)
		var arc_name: String = selected_grds[grd].get_file().get_basename()
		
		var buff: PackedByteArray = decompress_lz_variant(in_file.get_buffer(in_file.get_length()))
		print("%08X %s" % [buff.size(), folder_path + "/%s" % arc_name + ".DEC"])
		
		var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + ".DEC", FileAccess.WRITE)
		out_file.store_buffer(buff)
		
		var png: Image = load_htx_tiles_to_image(buff, folder_path + "/%s" % arc_name)
		png.save_png(folder_path + "/%s" % arc_name + ".PNG")
	print_rich("[color=green]Finished![/color]")
	
	
func load_htx_tiles_to_image(data: PackedByteArray, path: String) -> Image:
	# --- Main header ---
	var final_w: int = data.decode_u16(0x4)
	var final_h: int = data.decode_u16(0x6)
	var palette_offset: int = data.decode_u32(0xC)
	var image_header_offset: int = data.decode_u32(0x10)
	var float_section_offset: int = data.decode_u32(0x18)

	# --- Global palette ---
	var pal_buf: PackedByteArray = PackedByteArray()
	if palette_offset < image_header_offset:
		pal_buf = data.slice(palette_offset, image_header_offset)
	if pal_buf.size() > 0:
		pal_buf = ComFuncs.unswizzle_palette(pal_buf, 32)
	var pal_entries: int = max(1, pal_buf.size() / 4)

	# --- Read PVRT tiles ---
	var tiles: Array[Image] = []
	var header_off: int = image_header_offset
	while header_off + 12 <= data.size():
		var tag: String = data.slice(header_off, header_off + 4).get_string_from_ascii()
		var header_size: int = 0

		if tag in ["GBIX", "PVRT"] and header_off + 0x8 + 4 <= data.size():
			header_size = data.decode_u16(header_off + 0x4) + 8
		elif tag in ["HTEX", "HTSF"] and header_off + 0x8 + 4 <= data.size():
			header_size = data.decode_u16(header_off + 0x8)
		if header_size <= 0:
			break

		if tag == "PVRT":
			if header_off + 0x10 > data.size():
				break
			var tile_w: int = data.decode_u16(header_off + 0xC)
			var tile_h: int = data.decode_u16(header_off + 0xE)
			var tile_data_off: int = header_off + 0x10
			var read_size: int = tile_w * tile_h
			if read_size <= 0:
				header_off += header_size
				continue
			
			header_off += read_size
			var idx_buf: PackedByteArray = data.slice(tile_data_off, tile_data_off + read_size)
			idx_buf = unswizzle8(idx_buf, tile_w, tile_h)

			var rgba: PackedByteArray = PackedByteArray()
			rgba.resize(tile_w * tile_h * 4)
			for i in range(tile_w * tile_h):
				var pi: int = 0
				if i < idx_buf.size():
					pi = idx_buf.decode_u8(i)
				if pi >= pal_entries:
					pi = pal_entries - 1
				var pofs: int = pi * 4
				var r:int = 0; var g:int = 0; var b:int = 0; var a:int = 0
				if pofs + 4 <= pal_buf.size():
					r = pal_buf.decode_u8(pofs + 0)
					g = pal_buf.decode_u8(pofs + 1)
					b = pal_buf.decode_u8(pofs + 2)
					a = pal_buf.decode_u8(pofs + 3)
					a = int((a / 128.0) * 255.0)
				var wofs: int = i * 4
				rgba.encode_u8(wofs + 0, r)
				rgba.encode_u8(wofs + 1, g)
				rgba.encode_u8(wofs + 2, b)
				rgba.encode_u8(wofs + 3, a)

			var tile_img: Image = Image.create_from_data(tile_w, tile_h, false, Image.FORMAT_RGBA8, rgba)
			if tile_output:
				tile_img.save_png(path + "_%08d.PNG" % header_off)
			tiles.append(tile_img)

		header_off += header_size

	# --- Final canvas ---
	var final_img: Image = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGBA8)
	final_img.fill(Color(0,0,0,0))

	# --- Float section for sub-tile placement ---
	var slice_idx: int = 0
	var slice_size: int = 64  # typical sub-tile size
	var f_off: int = float_section_offset

	while f_off + 36 <= palette_offset and f_off + 36 <= data.size():
		f_off += 4  # skip 2x16-bit flags

		# Read 8 floats for this slice
		var coords: Array[float] = []
		for j in range(8):
			coords.append(data.decode_float(f_off))
			f_off += 4

		# Calculate destination rect
		var min_x = int(floor(min(coords[0], coords[2], coords[4], coords[6])))
		var min_y = int(floor(min(coords[1], coords[3], coords[5], coords[7])))
		var max_x = int(ceil(max(coords[0], coords[2], coords[4], coords[6])))
		var max_y = int(ceil(max(coords[1], coords[3], coords[5], coords[7])))
		var dst_rect: Rect2i = Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)

		# Determine which PVRT tile this slice comes from
		var slices_per_tile_x = tiles[0].get_width() / slice_size
		var slices_per_tile_y = tiles[0].get_height() / slice_size
		var slices_per_tile = slices_per_tile_x * slices_per_tile_y
		var tile_idx = int(slice_idx / slices_per_tile)
		tile_idx = clamp(tile_idx, 0, tiles.size() - 1)
		var tile_img = tiles[tile_idx]

		# Determine source rect within PVRT tile
		var local_idx = slice_idx % slices_per_tile
		var sx = (local_idx % slices_per_tile_x) * slice_size
		var sy = int(local_idx / slices_per_tile_x) * slice_size
		var src_rect = Rect2i(sx, sy, slice_size, slice_size)

		# Blit slice to final image
		final_img.blit_rect(tile_img, src_rect, dst_rect.position)

		slice_idx += 1

	return final_img
	
	
func print_pvrt(data: PackedByteArray) -> void:
	var off: int = 0

	# --- Main header ---
	var final_width: int = data.decode_u16(0x4)
	var final_height: int = data.decode_u16(0x6)
	var palette_offset: int = data.decode_u32(0xC)
	var image_header_offset: int = data.decode_u32(0x10)
	var unknown_14: int = data.decode_u32(0x14) # placeholder
	var float_section_offset: int = data.decode_u32(0x1C)

	print("Main Header:")
	print("  Width: %d" % final_width)
	print("  Height: %d" % final_height)
	print("  Palette Offset:", palette_offset)
	print("  Image Header Offset:", image_header_offset)
	print("  Unknown @0x14:", unknown_14)
	print("  Float Section Offset:", float_section_offset)

	# --- Jump to image data header ---
	off = image_header_offset
	var magic: String = data.slice(off, off + 4).get_string_from_ascii()
	print("Magic @", off, ":", magic)

	# HTEX
	if magic == "HTEX":
		var image_data_size: int = data.decode_u32(off + 0x4)
		print("HTEX found - Image data size + 0x10:", image_data_size)
		off += 0x10
		magic = data.slice(off, off + 4).get_string_from_ascii()
		print("Next Magic @", off, ":", magic)

	# HTSF
	if magic == "HTSF":
		var tile_size: int = data.decode_u32(off + 0x4)
		print("HTSF found - Tile size + 0x10:", tile_size)
		off += 0x10
		magic = data.slice(off, off + 4).get_string_from_ascii()
		print("Next Magic @", off, ":", magic)

	# GBIX
	if magic == "GBIX":
		print("GBIX found")
		off += 0x10
		magic = data.slice(off, off + 4).get_string_from_ascii()
		print("Next Magic @", off, ":", magic)

	# PVRT
	if magic == "PVRT":
		var pixel_format: int = data.decode_u8(off + 0x8)
		var image_type: int = data.decode_u8(off + 0x9)
		var tile_width: int = data.decode_u16(off + 0xC)
		var tile_height: int = data.decode_u16(off + 0xE)

		print("PVRT found - Pixel format:", pixel_format)
		print("PVRT Image Data Type:", image_type)
		print("PVRT Tile Width:", tile_width)
		print("PVRT Tile Height:", tile_height)

		off += 0x10

	print("Tile data starts at offset:", off)
	return
	
func unswizzle8(data: PackedByteArray, w: int, h: int, swizz: bool = false) -> PackedByteArray:
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
	
	
func split_and_reassemble_tile_bottom_to_top(tile_data: PackedByteArray, outpath: String = "F:/Games/Notes/test/Sakura Taisen/TEST") -> Image:
	var TILE_SIZE := 256
	var BAND_HEIGHT := 64
	
	# Load the raw data into an Image (RGB8 assumed)
	var img := Image.create_from_data(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_L8, tile_data)
	
	# Slice sizes per band row
	var slice_sizes := [
		Vector2i(32, BAND_HEIGHT), Vector2i(32, BAND_HEIGHT),
		Vector2i(32, BAND_HEIGHT), Vector2i(32, BAND_HEIGHT),
		Vector2i(64, BAND_HEIGHT), Vector2i(64, BAND_HEIGHT)
	]
	
	# Create a blank final image
	var final_img := Image.create_empty(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_L8)
	
	# Number of bands vertically in the tile
	var num_bands := TILE_SIZE / BAND_HEIGHT
	var add: int = 0
	for band_index in range(num_bands):
		# Source Y (starting from bottom band in source image)
		var y_src := (num_bands - 1 - band_index) * BAND_HEIGHT
		var x_src := 0
		
		# Destination Y (starting from top in final image)
		var y_dest := band_index * BAND_HEIGHT
		var x_dest := 0
		
		for size in slice_sizes:
			var section: Image = img.get_region(Rect2i(x_src, y_src, size.x, size.y))
			section.save_png("%s_%04d.PNG" % [outpath, add])
			final_img.blit_rect(section, Rect2i(Vector2i.ZERO, size), Vector2i(x_dest, y_dest))
			x_src += size.x
			x_dest += size.x
			add += 1
	
	return final_img
	
	
func decompress_lz_variant(input: PackedByteArray) -> PackedByteArray:
	var a0: int = 0
	var a1: int = 0
	var a2: int = 0
	var a3: int = 0
	var s0: int = 0
	var s1: int = 0
	var s2: int = 0
	var s3: int = 0
	var s4: int = 0
	var s5: int = 0
	var s6: int = 0
	var t0: int = 0
	var t1: int = 0
	var t2: int = 0
	var t3: int = 0
	var t4: int = 0
	var t5: int = 0
	var t6: int = 0
	var t7: int = 0
	var t8: int = 0
	var t9: int = 0
	var v0: int = 0
	var v1: int = 0
	var temp_buff: PackedByteArray
	temp_buff.resize(0x40)
	temp_buff.encode_u8(4, 1) #a0 0x2034 counter
	temp_buff.encode_u8(5, 0) #a0 0x2035 other counter
	temp_buff.encode_u32(0x20, 0x48) #input pos
	temp_buff.encode_u32(0x24, input.decode_u32(0x2C) + 0x38) #input end offset
	temp_buff.encode_u8(0x2C, 0) #a0 0x2C output pos
	var history: PackedByteArray
	history.resize(0x2034)
	var output: PackedByteArray

	var pc: int = 0x0021F890  # starting label
	while true:
		match pc:
			0x0021F890:
				v0 = 0
				a1 = temp_buff.decode_u32(0x2C)
				pc = 0x0021F8BC
				continue
			0x0021F8BC:
				v1 = temp_buff.decode_u8(4)
				pc = 0x0021F8C0
				continue
			0x0021F8C0:
				v1 = v1 + -1
				temp_buff.encode_s8(4, v1) #store_byte(a0 + 0x2034, v1)
				v1 = v1 & 255
				if v1 != 0:
					pc = 0x0021f924
					continue
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0
				if s3 != v1:
					pc = 0x0021f8ec
					continue
				pc = 0x0021f908
				continue
			0x0021F8EC:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				t8 = v1 & 255
				pc = 0x0021F908
				continue
			0x0021F908:
				s3 = 0 + 0
				if s4 != 0:
					pc = 0x0021f918
					continue
				pc = 0x0021f944
				continue
			0x0021F918:
				temp_buff.encode_s8(5, t8)#store_byte(a0 + 0x2035, t8)
				v1 = 0 + 8
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				pc = 0x0021F924
				continue
			0x0021F924:
				# nop
				v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				s3 = 0 + 1
				a2 = (v1 << 24)
				a2 = (a2 >> 24)
				v1 = v1 >> 1
				temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				a2 = a2 & 1
				pc = 0x0021F944
				continue
			0x0021F944:
				if s3 != 0:
					pc = 0x0021f958
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021F958:
				s3 = 0 + 8
				if a2 == 0:
					pc = 0x0021fa48
					continue
				pc = 0x0021F960
				continue
			0x0021F960:
				s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s5 = 0
				if s4 != v1:
					pc = 0x0021f978
					continue
				pc = 0x0021f990
				continue
			0x0021F978:
				v1 = s4 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s5 = 1
				v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				v1 = ~(v1 | 0)
				a3 = v1 & 255
				pc = 0x0021F990
				continue
			0x0021F990:
				v1 = v0 & 8191
				if s5 != 0:
					pc = 0x0021f9a0
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021F9A0:
				v1 = a0 + v1
				v0 = v0 + 1
				history.encode_s8(v1 + 0x0034, a3)#store_byte(v1 + 0x0034, a3)
				output.append(a3)#store_byte(a1 + 0x0000, a3)
				v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				v1 = v1 + -1
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				v1 = v1 & 255
				a1 = a1 + 1
				if v1 != 0:
					pc = 0x0021fa10
					continue
				s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s5 = 0
				if s4 != v1:
					pc = 0x0021f9e0
					continue
				pc = 0x0021f9f8
				continue
			0x0021F9E0:
				v1 = s4 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s5 = 0 + 1
				v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				v1 = ~(v1 | 0)
				t9 = v1 & 255
				pc = 0x0021F9F8
				continue
			0x0021F9F8:
				s4 = 0
				if s5 != 0:
					pc = 0x0021fa08
					continue
				pc = 0x0021fa2c
				continue
			0x0021FA08:
				temp_buff.encode_s8(5, t9)#store_byte(a0 + 0x2035, t9)
				temp_buff.encode_s8(4, s3)#store_byte(a0 + 0x2034, s3)
				pc = 0x0021FA10
				continue
			0x0021FA10:
				v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				s4 = 0 + 1
				t0 = (v1 << 24)
				t0 = (t0 >> 24)
				v1 = v1 >> 1
				temp_buff.encode_s8(5, v1) #store_byte(a0 + 0x2035, v1)
				t0 = t0 & 1
				pc = 0x0021FA2C
				continue
			0x0021FA2C:
				if s4 != 0:
					pc = 0x0021fa40
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FA40:
				if t0 != 0:
					pc = 0x0021f960
					continue
				pc = 0x0021FA48
				continue
			0x0021FA48:
				v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				v1 = v1 + -1
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				v1 = v1 & 255
				if v1 != 0:
					pc = 0x0021faac
					continue
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0
				if s3 != v1:
					pc = 0x0021fa78
					continue
				pc = 0x0021fa90
				continue
			0x0021FA78:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				s0 = v1 & 255
				pc = 0x0021FA90
				continue
			0x0021FA90:
				s3 = 0
				if s4 != 0:
					pc = 0x0021faa0
					continue
				pc = 0x0021facc
				continue
			0x0021FAA0:
				temp_buff.encode_s8(5, s0)#store_byte(a0 + 0x2035, s0)
				v1 = 0 + 8
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				pc = 0x0021FAAC
				continue
			0x0021FAAC:
				v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				s3 = 0 + 1
				t1 = (v1 << 24)
				t1 = (t1 >> 24)
				v1 = v1 >> 1
				temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				t1 = t1 & 1
				pc = 0x0021FACC
				continue
			0x0021FACC:
				if s3 != 0:
					pc = 0x0021fae0
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FAE0:
				if t1 == 0:
					pc = 0x0021fbd8
					continue
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0
				if s3 != v1:
					pc = 0x0021fb00
					continue
				pc = 0x0021fb18
				continue
			0x0021FB00:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				t2 = v1 & 255
				pc = 0x0021FB18
				continue
			0x0021FB18:
				# nop
				if s4 != 0:
					pc = 0x0021fb28
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FB28:
				s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				s3 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				v1 = t2 & 255
				if s4 != s3:
					pc = 0x0021fb40
					continue
				s3 = 0
				pc = 0x0021fb58
				continue
			0x0021FB40:
				t3 = s4 + 1
				temp_buff.encode_s32(0x20, t3)#store_word(a0 + 0x0020, t3)
				s3 = 0 + 1
				t3 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				t3 = ~(t3 | 0)
				t3 = t3 & 255
				pc = 0x0021FB58
				continue
			0x0021FB58:
				s4 = t3 & 255
				if s3 != 0:
					pc = 0x0021fb68
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FB68:
				s3 = s4 | v1 # or                s3, s4, v1
				if s3 == 0:
					s3 = v1 >> 3
					pc = 0x0021fdac
					continue
				s3 = v1 >> 3
				s4 = s4 << 5
				s3 = s4 + s3
				v1 = v1 & 7
				s3 = s3 + -8192
				if v1 == 0:
					pc = 0x0021fb90
					continue
				v1 = v1 + 2
				pc = 0x0021fd60
				continue
			0x0021FB90:
				s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s5 = 0
				if s4 != v1:
					pc = 0x0021fba8
					continue
				pc = 0x0021fbc0
				continue
			0x0021FBA8:
				v1 = s4 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s5 = 0 + 1
				v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				v1 = ~(v1 | 0)
				t4 = v1 & 255
				pc = 0x0021FBC0
				continue
			0x0021FBC0:
				v1 = t4 & 255
				if s5 != 0:
					pc = 0x0021fbd0
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FBD0:
				v1 = v1 + 1
				pc = 0x0021fd60
				continue
			0x0021FBD8:
				v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				v1 = v1 + -1
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				v1 = v1 & 255
				if v1 != 0:
					pc = 0x0021fc3c
					continue
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0
				if s3 != v1:
					pc = 0x0021fc08
					continue
				pc = 0x0021fc20
				continue
			0x0021FC08:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				s1 = v1 & 255
				pc = 0x0021FC20
				continue
			0x0021FC20:
				s3 = 0
				if s4 != 0:
					pc = 0x0021fc30
					continue
				pc = 0x0021fc5c
				continue
			0x0021FC30:
				temp_buff.encode_s8(5, s1)#store_byte(a0 + 0x2035, s1)
				v1 = 0 + 8
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				pc = 0x0021FC3C
				continue
			0x0021FC3C:
				# nop
				v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				s3 = 0 + 1
				t5 = (v1 << 24)
				t5 = (t5 >> 24)
				v1 = v1 >> 1
				temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				t5 = t5 & 1
				pc = 0x0021FC5C
				continue
			0x0021FC5C:
				if s3 != 0:
					pc = 0x0021fc70
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FC70:
				v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				v1 = v1 + -1
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				v1 = v1 & 255
				if v1 != 0:
					pc = 0x0021fcd4
					continue
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0 + 0
				if s3 != v1:
					pc = 0x0021fca0
					continue
				# nop
				pc = 0x0021fcb8
				continue
			0x0021FCA0:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				s2 = v1 & 255
				pc = 0x0021FCB8
				continue
			0x0021FCB8:
				s3 = 0
				if s4 != 0:
					pc = 0x0021fcc8
					continue
				pc = 0x0021fcf4
				continue
			0x0021FCC8:
				temp_buff.encode_s8(5, s2)#store_byte(a0 + 0x2035, s2)
				v1 = 0 + 8
				temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				pc = 0x0021FCD4
				continue
			0x0021FCD4:
				# nop
				v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				s3 = 0 + 1
				t6 = (v1 << 24)
				t6 = (t6 >> 24)
				v1 = v1 >> 1
				temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				t6 = t6 & 1
				pc = 0x0021FCF4
				continue
			0x0021FCF4:
				if s3 != 0:
					pc = 0x0021fd08
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FD08:
				s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				s4 = 0
				if s3 != v1:
					pc = 0x0021fd20
					continue
				pc = 0x0021fd38
				continue
			0x0021FD20:
				v1 = s3 + 1
				temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				s4 = 0 + 1
				v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				v1 = ~(v1 | 0)
				t7 = v1 & 255
				pc = 0x0021FD38
				continue
			0x0021FD38:
				v1 = t5 & 255
				if s4 != 0:
					pc = 0x0021fd48
					continue
				v0 = 0
				pc = 0x0021fdb4
				continue
			0x0021FD48:
				s3 = t7 & 255
				s4 = v1 << 1
				s3 = s3 + -256
				v1 = t6 & 255
				v1 = s4 + v1
				v1 = v1 + 2
				pc = 0x0021FD60
				continue
			0x0021FD60:
				s4 = v1 + 0
				s3 = s3 + v0
				v1 = v1 + -1
				if s4 == 0:
					pc = 0x0021f8bc
					continue
				pc = 0x0021FD70
				continue
			0x0021FD70:
				s4 = s3 & 8191
				s5 = a0 + s4
				s3 = s3 + 1
				s6 = history.decode_u8(s5 + 0x34)#load_byte_unsigned(s5 + 0x0034)
				s4 = v0 & 8191
				v0 = v0 + 1
				s5 = a0 + s4
				history.encode_s8(s5 + 0x34, s6)#store_byte(s5 + 0x0034, s6)
				s4 = v1 + 0
				output.append(s6)#store_byte(a1 + 0x0000, s6)
				v1 = v1 + -1
				a1 = a1 + 1
				if s4 != 0:
					pc = 0x0021fd70
					continue
				v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				pc = 0x0021f8c0
				continue
			0x0021FDAC:
				v0 = 0 + 1
				pc = 0x0021FDB4
				continue
			0x0021FDB4:
				break
	return output


func _on_load_grd_pressed() -> void:
	file_load_grd.show()


func _on_file_load_grd_files_selected(paths: PackedStringArray) -> void:
	selected_grds = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_cv_mtext_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


func _on_file_load_cvm_dir_selected(dir: String) -> void:
	var cvm_name: String = "LAYER0.CVM"
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
	
	var password: String = "tinaandluckandru"
	
	var args: PackedStringArray = ["split", "-p", password, input_path, output_path]
	var output: Array = []
	
	var exit_code: int = OS.execute(exe_path, args, output, true, false)

	print("Exit code: %d" % exit_code)
	print(output)
	print_rich("[color=green]Finished![/color]")


func _on_load_cvm_pressed() -> void:
	file_load_cvm.show()
