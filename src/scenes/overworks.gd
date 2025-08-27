extends Control

@onready var file_load_grd: FileDialog = $FILELoadGRD
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_cvm: FileDialog = $FILELoadCVM
@onready var file_load_mov: FileDialog = $FILELoadMOV
@onready var file_load_exe: FileDialog = $FILELoadEXE

var selected_grds: PackedStringArray
var selected_movs: PackedStringArray
var selected_exe: String = ""
var folder_path: String = ""
var tile_output: bool = false
var debug_out: bool = false


func _ready() -> void:
	file_load_grd.filters = ["*.BX, *.GRD, *.DMY"]
	file_load_mov.filters = ["*.MOV"]
	file_load_exe.filters = ["SLPM_670.03"]
	

func _process(_delta: float) -> void:
	if selected_grds and folder_path:
		create_grd()
		selected_grds.clear()
		folder_path
	elif selected_movs and folder_path:
		create_mov()
		selected_movs.clear()
		
		
func create_mov() -> void:
	var exe_file: FileAccess = FileAccess.open(selected_exe, FileAccess.READ)
	if exe_file == null:
		OS.alert("Could not load EXE")
		return
		
	exe_file.seek(0x31CCDC)
	var keys: PackedByteArray = exe_file.get_buffer(0x604)
	
	for mov: int in selected_movs.size():
		var in_file: FileAccess = FileAccess.open(selected_movs[mov], FileAccess.READ)
		var mov_name: String = selected_movs[mov].get_file()
		var mov_id: int = mov_name.to_int() / 10
		if mov_id == -1 or mov_id == 0:
			print("Invalid MOV id! Skipping %s" % mov_name)
			continue
		
		var mov_buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		var mov_size: int = mov_buff.decode_u32(0x1C) / 0x2000
		var key_offset: int = 0x304
		var mov_offset: int = 0x4000
		mov_id = ((mov_id << 32) << 24) >> 56
		
		var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % mov_name + ".MPG", FileAccess.WRITE)
		
		for _frame in range(mov_size):
			if Performance.get_monitor(Performance.MEMORY_STATIC) == 0x3B9ACA00:
				print("Memory exceeding 1GB, stopping (shouldn't happen).")
				break
			# Pass 1 (0x1F8 forward)
			var result: Array = _decrypt_block(mov_buff, keys, mov_offset, 0x1F8, key_offset, mov_id, true)
			mov_buff = result[0]
			mov_offset = result[1]
			# Pass 2 (0x8 forward)
			result = _decrypt_block(mov_buff, keys, mov_offset, 8, key_offset, mov_id, true)
			mov_buff = result[0]
			mov_offset = result[1]
			# Pass 3 (0x1FF reverse, with movie_id adjustment)
			result = _decrypt_block(mov_buff, keys, mov_offset, 0x1FF, key_offset, mov_id, false)
			mov_buff = result[0]
			mov_offset = result[1]
			mov_id += 1
		out_file.store_buffer(mov_buff)
		print("%s" % folder_path + "/%s" % mov_name + ".MPG")
		
	print_rich("[color=green]Finished![/color]")
	
	
func create_grd() -> void:
	for grd: int in selected_grds.size():
		var in_file: FileAccess = FileAccess.open(selected_grds[grd], FileAccess.READ)
		var arc_name: String = selected_grds[grd].get_file().get_basename()
		var file_name: String = selected_grds[grd].get_file()
		
		var buff: PackedByteArray
		if arc_name == "ADV_BG4138":
			buff = in_file.get_buffer(in_file.get_length())
			buff = buff.slice(0x38) # slice to known header information
		else:
			buff = decompress_lz_variant(in_file.get_buffer(in_file.get_length()))
			
		print("%08X %s" % [buff.size(), folder_path + "/%s" % file_name + ".DEC"])
		
		if debug_out:
			var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % file_name + ".DEC", FileAccess.WRITE)
			out_file.store_buffer(buff)
		if buff.size() > 0 and (not file_name.get_extension().to_lower() == "bx" or not file_name.contains("kao")):
			var png: Image = load_htx_tiles_to_image(buff, folder_path + "/%s" % file_name)
			png.save_png(folder_path + "/%s" % file_name + ".PNG")
			
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
	var pal_entries: int
	if palette_offset < image_header_offset:
		pal_buf = data.slice(palette_offset, image_header_offset)

	if pal_buf.size() == 0x400:
		pal_buf = ComFuncs.unswizzle_palette(pal_buf, 32)
		pal_entries = pal_buf.size() / 4
	elif pal_buf.size() == 0x200:
		# 16-bit BGR5551 palette
		var converted: PackedByteArray = PackedByteArray()
		converted.resize(256 * 4)
		for i in range(256):
			var pixel_16: int = pal_buf.decode_u16(i * 2)
			var b: int = ((pixel_16 >> 10) & 0x1F) * 8
			var g: int = ((pixel_16 >> 5) & 0x1F) * 8
			var r: int = (pixel_16 & 0x1F) * 8
			var a: int = ((pixel_16 >> 15) & 0x1) * 255
			var pofs: int = i * 4
			converted.encode_u8(pofs + 0, r)
			converted.encode_u8(pofs + 1, g)
			converted.encode_u8(pofs + 2, b)
			converted.encode_u8(pofs + 3, a)
		pal_buf = converted
		pal_entries = pal_buf.size() / 4
	else:
		pal_entries = max(1, pal_buf.size() / 4)

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
				var r:int = pal_buf.decode_u8(pofs + 0)
				var g:int = pal_buf.decode_u8(pofs + 1)
				var b:int = pal_buf.decode_u8(pofs + 2)
				var a:int = pal_buf.decode_u8(pofs + 3)
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
	final_img.fill(Color(0, 0, 0, 0))

	final_img = compose_tile_from_floats(tiles, data.slice(float_section_offset, palette_offset))
	return final_img
	
	
func compose_tile_from_floats(tiles: Array[Image], float_data: PackedByteArray) -> Image:
	var entries: Array = []
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF

	# --- Parse float entries ---
	var f_off: int = 0
	while f_off + 0x24 <= float_data.size():
		var tile_id: int = float_data.decode_u16(f_off + 0)
		var flags: int = float_data.decode_u16(f_off + 2)
		var x: float = float_data.decode_float(f_off + 4)
		var y: float = float_data.decode_float(f_off + 8)
		var offset_x: float = float_data.decode_float(f_off + 0x0C)
		var offset_y: float = float_data.decode_float(f_off + 0x10)
		var u0: float = float_data.decode_float(f_off + 0x14)
		var v0: float = float_data.decode_float(f_off + 0x18)
		var u1: float = float_data.decode_float(f_off + 0x1C)
		var v1: float = float_data.decode_float(f_off + 0x20)
		f_off += 0x24

		entries.append({
			"id": tile_id, "x": x, "y": y,
			"offset_x": offset_x, "offset_y": offset_y,
			"u0": u0, "v0": v0, "u1": u1, "v1": v1
		})

		# track min/max for final image bounds
		min_x = min(min_x, x)
		min_y = min(min_y, y)
		max_x = max(max_x, x + offset_x)
		max_y = max(max_y, y + offset_y)

	# --- Final canvas size ---
	var final_w: int = int(max(1.0, max_x - min_x))
	var final_h: int = int(max(1.0, max_y - min_y))
	var final_img: Image = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGBA8)
	final_img.fill(Color(0,0,0,0))

	# --- Place tiles ---
	for e in entries:
		var tile_id: int = e["id"]
		if tile_id < 0 or tile_id >= tiles.size():
			continue
		var tile_img: Image = tiles[tile_id]

		# source rectangle
		var u0: int = int(e["u0"])
		var v0: int = int(e["v0"])
		var u1: int = int(e["u1"])
		var v1: int = int(e["v1"])
		var src_w: int = max(1, u1 - u0)
		var src_h: int = max(1, v1 - v0)

		# create sub-image from tile
		var sub_img: Image = Image.create_empty(src_w, src_h, false, tile_img.get_format())
		for dx in range(src_w):
			for dy in range(src_h):
				var sx: int = clamp(u0 + dx, 0, tile_img.get_width() - 1)
				var sy: int = clamp(v0 + dy, 0, tile_img.get_height() - 1)
				sub_img.set_pixel(dx, dy, tile_img.get_pixel(sx, sy))

		# target size = offset_x/offset_y (if >0), else keep original size
		var target_w: int = int(e["offset_x"]) if e["offset_x"] > 0 else src_w
		var target_h: int = int(e["offset_y"]) if e["offset_y"] > 0 else src_h

		if target_w != src_w or target_h != src_h:
			sub_img.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)

		# final placement
		var dst_x: int = int(e["x"] - min_x)
		var dst_y: int = int(e["y"] - min_y)
		final_img.blit_rect(sub_img, Rect2i(0, 0, sub_img.get_width(), sub_img.get_height()), Vector2i(dst_x, dst_y))

	return final_img
	
	
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
	
	
func _decrypt_block(mem: PackedByteArray, keys: PackedByteArray, offset: int, dec_size: int, key_offset: int, movie_id: int, forward: bool = true) -> Array:
	var v1: int = 3
	if forward:
		for i in range(dec_size):
			var remainder: int = i % v1
			var byte: int = mem.decode_u8(offset + i)
			var key_index: int = (remainder << 8) + byte
			var key_byte: int = keys.decode_u8(key_offset + key_index)
			mem.encode_s8(offset + i, key_byte)
		return [mem, offset + dec_size]
	else:
		var neg_counter: int = 1
		var t0: int = -1
		for _i in range(dec_size):
			var byte2: int = mem.decode_u8((offset - neg_counter) - 1)
			var a2: int = int((t0 << 32) << 24) >> 56
			var byte: int = mem.decode_u8(offset - neg_counter)
			var v1_calc: int = (byte2 + a2 + movie_id) & 0xFF
			mem.encode_s8(offset - neg_counter, byte - v1_calc)
			neg_counter += 1
			t0 -= 1
		return [mem, offset + 0x1E00]
	
	
#func decompress_lz_variant_mips(input: PackedByteArray) -> PackedByteArray:
	#var a0: int = 0
	#var a1: int = 0
	#var a2: int = 0
	#var a3: int = 0
	#var s0: int = 0
	#var s1: int = 0
	#var s2: int = 0
	#var s3: int = 0
	#var s4: int = 0
	#var s5: int = 0
	#var s6: int = 0
	#var t0: int = 0
	#var t1: int = 0
	#var t2: int = 0
	#var t3: int = 0
	#var t4: int = 0
	#var t5: int = 0
	#var t6: int = 0
	#var t7: int = 0
	#var t8: int = 0
	#var t9: int = 0
	#var v0: int = 0
	#var v1: int = 0
	#var temp_buff: PackedByteArray
	#var input_pos: int 
	#var hdr: String = input.slice(0, 4).get_string_from_ascii()
	#
	#if hdr == "EOFC":
		#return PackedByteArray()
	#elif hdr == "APLN":
		#input_pos = input.decode_u32(0x4) + 0x30
	#elif hdr == "FCNK":
		#input_pos = 0x20
	#elif hdr == "AFCE":
		#input_pos = input.decode_u32(0x14) + 0x30
	#else:
		#input_pos = 0xA8
		#
	#temp_buff.resize(0x40)
	#temp_buff.encode_u8(4, 1) #a0 0x2034 counter
	#temp_buff.encode_u8(5, 0) #a0 0x2035 other counter
	#temp_buff.encode_u32(0x20, input_pos) #input pos
	#temp_buff.encode_u32(0x24, input.decode_u32(0x2C) + 0x38) #input end offset
	#temp_buff.encode_u8(0x2C, 0) #a0 0x2C output pos
	#var history: PackedByteArray
	#history.resize(0x2034)
	#var output: PackedByteArray
#
	#var pc: int = 0x0021F890  # starting label
	#while true:
		#match pc:
			#0x0021F890:
				#v0 = 0
				#a1 = temp_buff.decode_u32(0x2C)
				#pc = 0x0021F8BC
				#continue
			#0x0021F8BC:
				#v1 = temp_buff.decode_u8(4)
				#pc = 0x0021F8C0
				#continue
			#0x0021F8C0:
				#v1 = v1 + -1
				#temp_buff.encode_s8(4, v1) #store_byte(a0 + 0x2034, v1)
				#v1 = v1 & 255
				#if v1 != 0:
					#pc = 0x0021f924
					#continue
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0
				#if s3 != v1:
					#pc = 0x0021f8ec
					#continue
				#pc = 0x0021f908
				#continue
			#0x0021F8EC:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#t8 = v1 & 255
				#pc = 0x0021F908
				#continue
			#0x0021F908:
				#s3 = 0 + 0
				#if s4 != 0:
					#pc = 0x0021f918
					#continue
				#pc = 0x0021f944
				#continue
			#0x0021F918:
				#temp_buff.encode_s8(5, t8)#store_byte(a0 + 0x2035, t8)
				#v1 = 0 + 8
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#pc = 0x0021F924
				#continue
			#0x0021F924:
				## nop
				#v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				#s3 = 0 + 1
				#a2 = (v1 << 24)
				#a2 = (a2 >> 24)
				#v1 = v1 >> 1
				#temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				#a2 = a2 & 1
				#pc = 0x0021F944
				#continue
			#0x0021F944:
				#if s3 != 0:
					#pc = 0x0021f958
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021F958:
				#s3 = 0 + 8
				#if a2 == 0:
					#pc = 0x0021fa48
					#continue
				#pc = 0x0021F960
				#continue
			#0x0021F960:
				#s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s5 = 0
				#if s4 != v1:
					#pc = 0x0021f978
					#continue
				#pc = 0x0021f990
				#continue
			#0x0021F978:
				#v1 = s4 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s5 = 1
				#v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				#v1 = ~(v1 | 0)
				#a3 = v1 & 255
				#pc = 0x0021F990
				#continue
			#0x0021F990:
				#v1 = v0 & 8191
				#if s5 != 0:
					#pc = 0x0021f9a0
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021F9A0:
				#v1 = a0 + v1
				#v0 = v0 + 1
				#history.encode_s8(v1 + 0x0034, a3)#store_byte(v1 + 0x0034, a3)
				#output.append(a3)#store_byte(a1 + 0x0000, a3)
				#v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				#v1 = v1 + -1
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#v1 = v1 & 255
				#a1 = a1 + 1
				#if v1 != 0:
					#pc = 0x0021fa10
					#continue
				#s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s5 = 0
				#if s4 != v1:
					#pc = 0x0021f9e0
					#continue
				#pc = 0x0021f9f8
				#continue
			#0x0021F9E0:
				#v1 = s4 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s5 = 0 + 1
				#v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				#v1 = ~(v1 | 0)
				#t9 = v1 & 255
				#pc = 0x0021F9F8
				#continue
			#0x0021F9F8:
				#s4 = 0
				#if s5 != 0:
					#pc = 0x0021fa08
					#continue
				#pc = 0x0021fa2c
				#continue
			#0x0021FA08:
				#temp_buff.encode_s8(5, t9)#store_byte(a0 + 0x2035, t9)
				#temp_buff.encode_s8(4, s3)#store_byte(a0 + 0x2034, s3)
				#pc = 0x0021FA10
				#continue
			#0x0021FA10:
				#v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				#s4 = 0 + 1
				#t0 = (v1 << 24)
				#t0 = (t0 >> 24)
				#v1 = v1 >> 1
				#temp_buff.encode_s8(5, v1) #store_byte(a0 + 0x2035, v1)
				#t0 = t0 & 1
				#pc = 0x0021FA2C
				#continue
			#0x0021FA2C:
				#if s4 != 0:
					#pc = 0x0021fa40
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FA40:
				#if t0 != 0:
					#pc = 0x0021f960
					#continue
				#pc = 0x0021FA48
				#continue
			#0x0021FA48:
				#v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				#v1 = v1 + -1
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#v1 = v1 & 255
				#if v1 != 0:
					#pc = 0x0021faac
					#continue
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0
				#if s3 != v1:
					#pc = 0x0021fa78
					#continue
				#pc = 0x0021fa90
				#continue
			#0x0021FA78:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#s0 = v1 & 255
				#pc = 0x0021FA90
				#continue
			#0x0021FA90:
				#s3 = 0
				#if s4 != 0:
					#pc = 0x0021faa0
					#continue
				#pc = 0x0021facc
				#continue
			#0x0021FAA0:
				#temp_buff.encode_s8(5, s0)#store_byte(a0 + 0x2035, s0)
				#v1 = 0 + 8
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#pc = 0x0021FAAC
				#continue
			#0x0021FAAC:
				#v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				#s3 = 0 + 1
				#t1 = (v1 << 24)
				#t1 = (t1 >> 24)
				#v1 = v1 >> 1
				#temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				#t1 = t1 & 1
				#pc = 0x0021FACC
				#continue
			#0x0021FACC:
				#if s3 != 0:
					#pc = 0x0021fae0
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FAE0:
				#if t1 == 0:
					#pc = 0x0021fbd8
					#continue
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0
				#if s3 != v1:
					#pc = 0x0021fb00
					#continue
				#pc = 0x0021fb18
				#continue
			#0x0021FB00:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#t2 = v1 & 255
				#pc = 0x0021FB18
				#continue
			#0x0021FB18:
				## nop
				#if s4 != 0:
					#pc = 0x0021fb28
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FB28:
				#s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#s3 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#v1 = t2 & 255
				#if s4 != s3:
					#pc = 0x0021fb40
					#continue
				#s3 = 0
				#pc = 0x0021fb58
				#continue
			#0x0021FB40:
				#t3 = s4 + 1
				#temp_buff.encode_s32(0x20, t3)#store_word(a0 + 0x0020, t3)
				#s3 = 0 + 1
				#t3 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				#t3 = ~(t3 | 0)
				#t3 = t3 & 255
				#pc = 0x0021FB58
				#continue
			#0x0021FB58:
				#s4 = t3 & 255
				#if s3 != 0:
					#pc = 0x0021fb68
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FB68:
				#s3 = s4 | v1 # or                s3, s4, v1
				#if s3 == 0:
					#s3 = v1 >> 3
					#pc = 0x0021fdac
					#continue
				#s3 = v1 >> 3
				#s4 = s4 << 5
				#s3 = s4 + s3
				#v1 = v1 & 7
				#s3 = s3 + -8192
				#if v1 == 0:
					#pc = 0x0021fb90
					#continue
				#v1 = v1 + 2
				#pc = 0x0021fd60
				#continue
			#0x0021FB90:
				#s4 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s5 = 0
				#if s4 != v1:
					#pc = 0x0021fba8
					#continue
				#pc = 0x0021fbc0
				#continue
			#0x0021FBA8:
				#v1 = s4 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s5 = 0 + 1
				#v1 = input.decode_s8(s4)#load_byte_signed(s4 + 0x0000)
				#v1 = ~(v1 | 0)
				#t4 = v1 & 255
				#pc = 0x0021FBC0
				#continue
			#0x0021FBC0:
				#v1 = t4 & 255
				#if s5 != 0:
					#pc = 0x0021fbd0
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FBD0:
				#v1 = v1 + 1
				#pc = 0x0021fd60
				#continue
			#0x0021FBD8:
				#v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				#v1 = v1 + -1
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#v1 = v1 & 255
				#if v1 != 0:
					#pc = 0x0021fc3c
					#continue
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0
				#if s3 != v1:
					#pc = 0x0021fc08
					#continue
				#pc = 0x0021fc20
				#continue
			#0x0021FC08:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#s1 = v1 & 255
				#pc = 0x0021FC20
				#continue
			#0x0021FC20:
				#s3 = 0
				#if s4 != 0:
					#pc = 0x0021fc30
					#continue
				#pc = 0x0021fc5c
				#continue
			#0x0021FC30:
				#temp_buff.encode_s8(5, s1)#store_byte(a0 + 0x2035, s1)
				#v1 = 0 + 8
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#pc = 0x0021FC3C
				#continue
			#0x0021FC3C:
				## nop
				#v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				#s3 = 0 + 1
				#t5 = (v1 << 24)
				#t5 = (t5 >> 24)
				#v1 = v1 >> 1
				#temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				#t5 = t5 & 1
				#pc = 0x0021FC5C
				#continue
			#0x0021FC5C:
				#if s3 != 0:
					#pc = 0x0021fc70
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FC70:
				#v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				#v1 = v1 + -1
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#v1 = v1 & 255
				#if v1 != 0:
					#pc = 0x0021fcd4
					#continue
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0 + 0
				#if s3 != v1:
					#pc = 0x0021fca0
					#continue
				## nop
				#pc = 0x0021fcb8
				#continue
			#0x0021FCA0:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#s2 = v1 & 255
				#pc = 0x0021FCB8
				#continue
			#0x0021FCB8:
				#s3 = 0
				#if s4 != 0:
					#pc = 0x0021fcc8
					#continue
				#pc = 0x0021fcf4
				#continue
			#0x0021FCC8:
				#temp_buff.encode_s8(5, s2)#store_byte(a0 + 0x2035, s2)
				#v1 = 0 + 8
				#temp_buff.encode_s8(4, v1)#store_byte(a0 + 0x2034, v1)
				#pc = 0x0021FCD4
				#continue
			#0x0021FCD4:
				## nop
				#v1 = temp_buff.decode_u8(5)#load_byte_unsigned(a0 + 0x2035)
				#s3 = 0 + 1
				#t6 = (v1 << 24)
				#t6 = (t6 >> 24)
				#v1 = v1 >> 1
				#temp_buff.encode_s8(5, v1)#store_byte(a0 + 0x2035, v1)
				#t6 = t6 & 1
				#pc = 0x0021FCF4
				#continue
			#0x0021FCF4:
				#if s3 != 0:
					#pc = 0x0021fd08
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FD08:
				#s3 = temp_buff.decode_s32(0x20)#load_word(a0 + 0x0020)
				#v1 = temp_buff.decode_s32(0x24)#load_word(a0 + 0x0024)
				#s4 = 0
				#if s3 != v1:
					#pc = 0x0021fd20
					#continue
				#pc = 0x0021fd38
				#continue
			#0x0021FD20:
				#v1 = s3 + 1
				#temp_buff.encode_s32(0x20, v1)#store_word(a0 + 0x0020, v1)
				#s4 = 0 + 1
				#v1 = input.decode_s8(s3)#load_byte_signed(s3 + 0x0000)
				#v1 = ~(v1 | 0)
				#t7 = v1 & 255
				#pc = 0x0021FD38
				#continue
			#0x0021FD38:
				#v1 = t5 & 255
				#if s4 != 0:
					#pc = 0x0021fd48
					#continue
				#v0 = 0
				#pc = 0x0021fdb4
				#continue
			#0x0021FD48:
				#s3 = t7 & 255
				#s4 = v1 << 1
				#s3 = s3 + -256
				#v1 = t6 & 255
				#v1 = s4 + v1
				#v1 = v1 + 2
				#pc = 0x0021FD60
				#continue
			#0x0021FD60:
				#s4 = v1 + 0
				#s3 = s3 + v0
				#v1 = v1 + -1
				#if s4 == 0:
					#pc = 0x0021f8bc
					#continue
				#pc = 0x0021FD70
				#continue
			#0x0021FD70:
				#s4 = s3 & 8191
				#s5 = a0 + s4
				#s3 = s3 + 1
				#s6 = history.decode_u8(s5 + 0x34)#load_byte_unsigned(s5 + 0x0034)
				#s4 = v0 & 8191
				#v0 = v0 + 1
				#s5 = a0 + s4
				#history.encode_s8(s5 + 0x34, s6)#store_byte(s5 + 0x0034, s6)
				#s4 = v1 + 0
				#output.append(s6)#store_byte(a1 + 0x0000, s6)
				#v1 = v1 + -1
				#a1 = a1 + 1
				#if s4 != 0:
					#pc = 0x0021fd70
					#continue
				#v1 = temp_buff.decode_u8(4)#load_byte_unsigned(a0 + 0x2034)
				#pc = 0x0021f8c0
				#continue
			#0x0021FDAC:
				#v0 = 0 + 1
				#pc = 0x0021FDB4
				#continue
			#0x0021FDB4:
				#break
	#return output


func _get_bit(input: PackedByteArray, ip: int, bitbuf: int, bits_left: int) -> Array:
	if bits_left == 0:
		if ip >= input.size():
			# No new data → behave as 0 bit without advancing state.
			return [0, ip, bitbuf, bits_left]
		bitbuf = (~input[ip]) & 0xFF
		ip += 1
		bits_left = 8
	var bit := bitbuf & 1
	bitbuf >>= 1
	bits_left -= 1
	return [bit, ip, bitbuf, bits_left]


func _read_byte(input: PackedByteArray, ip: int) -> Array:
	if ip >= input.size():
		return [0, ip]
	var v := (~input[ip]) & 0xFF
	ip += 1
	return [v, ip]


func decompress_lz_variant(input: PackedByteArray) -> PackedByteArray:
	if input.size() < 4:
		return PackedByteArray()

	var magic: String = input.slice(0, 4).get_string_from_ascii()
	var ip: int = 0
	if magic == "EOFC":
		return PackedByteArray()
	elif magic == "APLN":
		ip = input.decode_u32(0x4) + 0x30
	elif magic == "FCNK":
		ip = 0x20
	elif magic == "AFCE":
		ip = input.decode_u32(0x14) + 0x30
	else:
		ip = 0xA8

	# If your files rely on the embedded end pointer:
	# var end := input.decode_u32(0x2C) + 0x38

	var out := PackedByteArray()
	var hist := PackedByteArray()
	hist.resize(0x2000)              # 8 KiB history

	var bitbuf := 0
	var bits_left := 0
	var wpos := 0
	var mask := 0x1FFF

	while true:
		# Literal if first control bit is 1.
		var r: Array = _get_bit(input, ip, bitbuf, bits_left)
		var ctrl: int = r[0]; ip = r[1]; bitbuf = r[2]; bits_left = r[3]
		if ctrl == 1:
			var rb := _read_byte(input, ip)
			var lit: int = rb[0]; ip = rb[1]
			hist[wpos & mask] = lit
			out.append(lit)
			wpos += 1
			continue

		# Otherwise a match. Next bit chooses short/long form.
		r = _get_bit(input, ip, bitbuf, bits_left)
		var is_long: int = r[0] == 1
		ip = r[1]; bitbuf = r[2]; bits_left = r[3]

		var length := 0
		var offset := 0

		if is_long:
			# Long form:
			# offset = ((b2<<5)|(b1>>3)) - 8192
			# length = (b1&7)==0 ? (next+1) : (b1&7)+2
			var rb1: Array = _read_byte(input, ip)
			var b1: int = rb1[0]; ip = rb1[1]
			var rb2: Array = _read_byte(input, ip)
			var b2: int= rb2[0]; ip = rb2[1]

			# End marker.
			if (b1 | b2) == 0:
				break

			offset = ((b2 << 5) | (b1 >> 3)) - 8192
			length = b1 & 7
			if length == 0:
				var rbl := _read_byte(input, ip)
				length = rbl[0] + 1
				ip = rbl[1]
			else:
				length += 2
		else:
			# Short form:
			# length = ((bA<<1)|bB) + 2  ∈ [2..5]
			# offset = next_byte - 256  ∈ [-256..-1]
			r = _get_bit(input, ip, bitbuf, bits_left)
			var bA: int= r[0]; ip = r[1]; bitbuf = r[2]; bits_left = r[3]
			r = _get_bit(input, ip, bitbuf, bits_left)
			var bB: int = r[0]; ip = r[1]; bitbuf = r[2]; bits_left = r[3]

			length = ((bA << 1) | bB) + 2
			var rbo := _read_byte(input, ip)
			offset = rbo[0] - 256
			ip = rbo[1]

		# Copy (overlap-safe).
		var src := wpos + offset
		var i := 0
		while i < length:
			var v := hist[src & mask]
			hist[wpos & mask] = v
			out.append(v)
			wpos += 1
			src += 1
			i += 1

	return out
	
	
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


func _on_tilesoutput_toggled(_toggled_on: bool) -> void:
	tile_output = !tile_output


func _on_debugout_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_file_load_mov_files_selected(paths: PackedStringArray) -> void:
	selected_movs = paths
	file_load_folder.show()


func _on_load_mov_pressed() -> void:
	if not selected_exe:
		OS.alert("Please load an exe first (SLPM_xxx.xx)")
		return
		
	file_load_mov.show()


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	selected_exe = path
