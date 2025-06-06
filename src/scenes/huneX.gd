extends Node

@onready var load_bin: FileDialog = $LoadBIN
@onready var load_folder: FileDialog = $LoadFOLDER
@onready var load_exe: FileDialog = $LoadExe
@onready var load_image: FileDialog = $LoadIMAGE
@onready var debug_output_button: CheckBox = $VBoxContainer/DebugOutput
@onready var remove_alpha_1: CheckBox = $VBoxContainer/RemoveAlpha1
@onready var remove_alpha_2: CheckBox = $VBoxContainer/RemoveAlpha2
@onready var load_exe_button: Button = $HBoxContainer/LoadExe
@onready var load_cd_bin_file: Button = $HBoxContainer/LoadCdBinFile
@onready var tiled_output: CheckBox = $VBoxContainer/TiledOutput
@onready var load_image_button: Button = $HBoxContainer/LoadImage
@onready var load_databin: FileDialog = $LoadDATABIN
@onready var load_databin_button: Button = $HBoxContainer/LoadDatabin


var folder_path: String
var selected_file: String
var selected_imgs: PackedStringArray
var data_bin_path: String
var exe_path: String
var debug_output: bool = false
var tile_output: bool = false
var remove_alpha: bool = true
var keep_alpha_char: bool = false

var type2_game_types: PackedInt32Array = [
	Main.RAMUNE, Main.FATESTAY, 
	Main.HARUNOASHIOTO, Main.ONETWENTYYEN,
	Main.SCARLETNICHIJOU, Main.MAPLECOLORS]

#TODO: Image DATA2.BIN_00000016.MF_00003280.MF, DATA2.BIN_00000016.MF_00005021.MF in Fate Stay Night

func _ready() -> void:
	load_exe.filters = [
		"SLPM_657.17, SLPM_655.85, SLPM_550.98, SLPM_661.65, SLPM_664.37, MAIN.ELF"
		]
		
	if Main.game_type in type2_game_types:
		load_exe_button.hide()
		load_cd_bin_file.hide()
		debug_output_button.hide()
	elif Main.game_type not in type2_game_types:
		remove_alpha_1.hide()
		remove_alpha_2.hide()
		tiled_output.hide()
		load_image_button.hide()
		load_databin_button.hide()
		
		
func _process(_delta):
	if selected_file and folder_path:
		extract_cd_bin()
		_clear_strings()
	elif data_bin_path and folder_path:
		extract_mf_uffa()
		_clear_strings()
	elif selected_imgs and folder_path:
		convert_imgs()
		_clear_strings()


func _clear_strings() -> void:
	folder_path = ""
	selected_file = ""
	selected_imgs.clear()
	data_bin_path = ""
	return
	
	
func extract_cd_bin() -> void:
	var in_file: FileAccess
	var exe_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var tbl_start: int
	var tbl_end: int
	var f_id: int
	var f_offset: int
	var f_size: int
	var f_name: String
	
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	exe_file = FileAccess.open(exe_path, FileAccess.READ)
	
	if exe_path.get_file() == "SLPM_550.98": # Koi suru Otome to Shugo no Tate: The Shield of AIGIS
		tbl_start = 0x45480
		tbl_end = 0x7D820
	elif exe_path.get_file() == "SLPM_655.85": # Princess Holiday - Korogaru Ringo Tei Sen'ya Ichiya
		tbl_start = 0x51A00
		tbl_end = 0x65DC8
	elif exe_path.get_file() == "SLPM_657.17": # Tsuki wa Higashi ni Hi wa Nishi ni - Operation Sanctuary
		tbl_start = 0x4A780
		tbl_end = 0x76188
	elif exe_path.get_file() == "SLPM_661.65": # Otome wa Boku ni Koishiteru
		tbl_start = 0x4B800
		tbl_end = 0x6C768
	elif exe_path.get_file() == "SLPM_664.37": # Soul Link Extension
		tbl_start = 0x56200
		tbl_end = 0x6B5C0
	elif exe_path.get_file() == "MAIN.ELF": # Tsuki wa Higashi ni Hi wa Nishi ni - Operation Sanctuary (Dengeki D73 demo)
		tbl_start = 0x60810
		tbl_end = 0x61378
	
	f_id = 0
	for pos: int in range(tbl_start, tbl_end, 8):
		exe_file.seek(pos)
		f_offset = exe_file.get_32() * 0x800
		f_size = (((exe_file.get_32() + 0x7FF) & 0xFFFFF800) + 0x3FF) & 0xFFFFFC00
		
		in_file.seek(f_offset)
		buff = in_file.get_buffer(f_size)
		
		if buff.slice(0, 4).get_string_from_ascii() == "1bin" or buff.slice(0, 4).get_string_from_ascii() == "1BIN":
			f_name = "%08d.1bin" % f_id
			buff = gplDataSgi(buff)
			if Main.game_type == Main.KOISURU and (f_id == 28074 or f_id == 28206 or f_id == 28249): # Packed images
				var num_files: int = buff.decode_u32(0)
				var mem_pos: int = 8
				for i: int in num_files:
					var mem_off: int = buff.decode_u32(mem_pos)
					var mem_size: int = buff.decode_u32(mem_pos + 4)
					var png: Image = make_img(buff.slice(mem_off, mem_off + mem_size))
					png.save_png(folder_path + "/%s" % f_name + "_%02d" % i + ".PNG")
					mem_pos += 8
		elif buff.slice(0, 4).get_string_from_ascii() == "1tex":
			f_name = "%08d.1tex" % f_id
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			buff = gplDataSgi(buff)
			if debug_output:
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			var png: Image = make_img(buff)
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			f_id += 1
			continue
		elif buff.decode_u32(0) == 0xBA010000:
			f_name = "%08d.pss" % f_id
		else:
			f_name = "%08d.BIN" % f_id
		
		out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
		out_file.store_buffer(buff)
		out_file.close()
		
		print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		f_id += 1
		
	print_rich("[color=green]Finished![/color]")
	
	
func extract_mf_uffa() -> void:
	const BUFFER_SIZE = 8 * 1024 * 1024
	
	var in_file: FileAccess = FileAccess.open(data_bin_path, FileAccess.READ)
	var f_name: String = data_bin_path.get_file()
	var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
	
	if hdr == "MF":
		var ext: String = "BIN"
		
		in_file.seek(4)
		var num_files: int = in_file.get_32()
		var base_off: int = in_file.get_32()
		var mf_pos: int = 0x10
		var uffa_id: int = 0
		for mf_i in range(num_files):
			in_file.seek(mf_pos)
			var f_comp_size: int = in_file.get_32()
			var f_offset: int = in_file.get_32()
			var is_comp: bool = in_file.get_32()
			var f_size: int = in_file.get_32()
			mf_pos += 0x10
			if f_offset == 0 or f_size == 0:
				continue
			
			if is_comp:
				in_file.seek(f_offset)
				var buff: PackedByteArray = in_file.get_buffer(f_comp_size)
				
				in_file.seek(f_offset + 8)
				f_size = in_file.get_32()
				
				in_file.seek(f_offset + 16)
				buff = ComFuncs.decompLZSS(buff.slice(16), f_comp_size - 16, f_size)
				if buff.decode_u32(0) == 0x0000464D:
					ext = "MF"
					
				uffa_id += 1
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [mf_i, ext], FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			else:
				in_file.seek(f_offset)
				var hdr_bytes: int = in_file.get_32()
				in_file.seek(f_offset)
				var hdr_arr: PackedByteArray = in_file.get_buffer(16)
				var is_adpcm: bool = true
				for b in hdr_arr:
					if b != 0:
						is_adpcm = false
						break
				if hdr_bytes == 0xBA010000:
					ext = "PSS"
				elif hdr_bytes == 0x0000464D:
					ext = "MF"
				elif is_adpcm:
					ext = "ADPCM"
				else:
					ext = "BIN"
					
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [mf_i, ext], FileAccess.WRITE)
				in_file.seek(f_offset)
				while in_file.get_position() < f_offset + f_size:
					var read_size: int = min(BUFFER_SIZE, (f_offset + f_size) - in_file.get_position())
					var buff: PackedByteArray = in_file.get_buffer(read_size)
					out_file.store_buffer(buff)
				out_file.close()
				
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name + "_%04d.%s" % [mf_i, ext]])
	else:
		print_rich("[color=red]%s does not have a valid header!" % f_name)
	print_rich("[color=green]Finished![/color]")
	
	
func convert_imgs() -> void:
	for file in range(selected_imgs.size()):
		var in_file: FileAccess = FileAccess.open(selected_imgs[file], FileAccess.READ)
		var f_name: String = selected_imgs[file].get_file()
		var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
		if hdr == "MF":
			in_file.seek(0x14)
			var first_off: int = in_file.get_32()
			
			in_file.seek(first_off)
			hdr = in_file.get_buffer(3).get_string_from_ascii().strip_escapes()
			if hdr == "IMG" or hdr == "STD" or hdr == "1" or hdr == "2" or hdr == "0":
				var is_std: bool = false
				if hdr == "STD":
					is_std = true # For character images, though likely not needed
				in_file.seek(0)
				var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
				var num_files: int = buff.decode_u32(4)
					
				var img_tex_off: int = buff.decode_u32(8)
				var str_size: int = buff.decode_u32(0x10)
				var img_str: String = buff.slice(img_tex_off + 4, img_tex_off + 4 + str_size - 4).get_string_from_ascii()
				if buff.decode_u8(img_tex_off + 3) == 0xD:
					str_size -= 2
					img_str = buff.slice(img_tex_off + 5, img_tex_off + 5 + str_size - 5).get_string_from_ascii()
				elif buff.decode_u8(img_tex_off + 2) == 0xA:
					str_size -= 2
					img_str = buff.slice(img_tex_off + 3, img_tex_off + 3 + str_size - 3).get_string_from_ascii()
				var width_end: int = img_str.find(",")
				var height_end: int = img_str.find("\n")
				var f_w: int = img_str.substr(0, width_end).to_int()
				var f_h: int = img_str.substr(width_end, height_end - width_end).to_int()
				if height_end == -1:
					f_h = img_str.substr(width_end).to_int()
				
				var mf_pos: int = 0x20
				for hdr_i in range(num_files - 1):
					var tbl_start: int = buff.decode_u32(mf_pos + 4)
					if tbl_start == 0:
						mf_pos += 0x10
						continue
						
					var img_arr: Array[Image]
					var pos: int = 0x1C
					var hdr_buff: PackedByteArray = buff.slice(tbl_start)
					var num_imgs: int = hdr_buff.decode_u32(4)
					if num_imgs > 800:
						print_rich("[color=yellow]Palette data(and only that?) found in %s/%s_%03d skipping." % [folder_path, f_name, hdr_i])
						mf_pos += 0x10
						continue
					elif num_imgs > 1:
						# Mainly for Fate Stay Night checks for multiple images that are different dims from the rest. Improve detection later.
						var temp_w1: int = hdr_buff.decode_u32(pos + 4)
						var temp_h1: int = hdr_buff.decode_u32(pos + 8)
						var temp_w2: int = hdr_buff.decode_u32(pos + 0x24)
						var temp_h2: int = hdr_buff.decode_u32(pos + 0x28)
						if temp_h1 != temp_h2 or temp_w1 != temp_w2:
							is_std = true
					var img_format: int
					for img_i in range(num_imgs):
						img_format = hdr_buff.decode_u32(pos)
						var w: int = hdr_buff.decode_u32(pos + 4)
						var h: int = hdr_buff.decode_u32(pos + 8)
						var pal_off: int =  hdr_buff.decode_u32(pos + 12)
						var img_off: int =  hdr_buff.decode_u32(pos + 16)
						var unk: int = hdr_buff.decode_u32(pos + 0x1C)
						
						var img_size: int = w * h
						var pal_size: int = 0x400
						var pal: PackedByteArray
						if img_format == 0x13: # 8 bit
							pal = ComFuncs.unswizzle_palette(hdr_buff.slice(pal_off, pal_off + pal_size), 32)
						elif img_format == 0x14: # 4 bit
							pal_size = 0x40
							pal = hdr_buff.slice(pal_off, pal_off + pal_size)
						
						var img_buff: PackedByteArray = hdr_buff.slice(img_off, img_off + img_size)
						var png: Image = make_img2(img_buff, pal, is_std, img_i, w, h, img_format)
						if tile_output:
							png.save_png(folder_path + "/%s" % f_name + "_%03d_%03d.PNG" % [hdr_i, img_i])
						if is_std and img_i == 0:
							png.save_png(folder_path + "/%s" % f_name + "_%03d_mask.PNG" % hdr_i)
							pos += 0x20
							continue
						img_arr.append(png)
						pos += 0x20
						
					if is_std:
						print("0x%02X %02d %d x %d %s" % [img_format, num_imgs - 1, f_w, f_h, folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i])
					else:
						print("0x%02X %02d %d x %d %s" % [img_format, num_imgs, f_w, f_h, folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i])
						
					var png: Image
					if num_imgs > 2:
						png = tile_images_by_batch(img_arr, f_w, f_h, is_std)
					else:
						png = img_arr[0]
						
					png.save_png(folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i)
					mf_pos += 0x10
			elif hdr == "MF":
				print_rich("[color=yellow]%s has MF archive(s) in it. Please extract it first." % [folder_path + "/%s" % f_name])
			else:
				print_rich("[color=red]%s is not a valid image!" % [folder_path + "/%s" % f_name])
		else:
			print_rich("[color=red]%s does not have a valid header!" % [folder_path + "/%s" % f_name])
			
	print_rich("[color=green]Finished![/color]")
	
	
func gplDataSgi(input_data: PackedByteArray) -> PackedByteArray:
	var input_offset: int = 8
	var output_offset: int = 0
	var output_size: int = (input_data.decode_u8(4) << 24) | (input_data.decode_u8(5) << 16) | (input_data.decode_u8(6) << 8) | input_data.decode_u8(7)
	var output_data: PackedByteArray
	output_data.resize(output_size)
	
	while input_offset < input_data.size():
		var control: int = input_data.decode_s8(input_offset)
		input_offset += 1
		if control == 0:
			break
		
		if control > 0:  # Literal copy
			for _i in range(control):
				if input_offset >= input_data.size():
					break
				output_data.encode_s8(output_offset, input_data.decode_s8(input_offset))
				input_offset += 1
				output_offset += 1
		else:  # Back-reference copy
			if input_offset >= input_data.size():
				break
			var copy_offset: int = input_data.decode_u8(input_offset)
			input_offset += 1
			var copy_source: int = output_offset - copy_offset - 1
			for _i in range(2 - control):
				output_data.encode_s8(output_offset, output_data.decode_s8(copy_source))
				copy_source += 1
				output_offset += 1
	
	return output_data
	
	
func make_img2(data: PackedByteArray, pal: PackedByteArray, is_std: bool, img_id: int, w: int, h: int, img_format: int) -> Image:
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	if img_format == 0x13 or img_format == 0x14:
		if img_format == 0x13:
			for y in range(h):
				for x in range(w):
					var pixel_index: int = data[x + y * w]
					var r: int = pal[pixel_index * 4 + 0]
					var g: int = pal[pixel_index * 4 + 1]
					var b: int = pal[pixel_index * 4 + 2]
					var a: int = pal[pixel_index * 4 + 3]
					image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		elif img_format == 0x14:
			for y in range(h):
				for x in range(0, w, 2):  # Two pixels per byte
					var byte_index: int  = (x + y * w) / 2
					var byte_value: int  = data[byte_index]

					# Extract two 4-bit indices (little-endian order)
					var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
					var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

					# Set first pixel
					var r1: int = pal[pixel_index_1 * 4 + 0]
					var g1: int = pal[pixel_index_1 * 4 + 1]
					var b1: int = pal[pixel_index_1 * 4 + 2]
					var a1: int = pal[pixel_index_1 * 4 + 3]
					image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

					# Set second pixel (only if within bounds)
					if x + 1 < w:
						var r2: int = pal[pixel_index_2 * 4 + 0]
						var g2: int = pal[pixel_index_2 * 4 + 1]
						var b2: int = pal[pixel_index_2 * 4 + 2]
						var a2: int = pal[pixel_index_2 * 4 + 3]
						image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	else:
		print_rich("[color=red]Unknown image format 0x%02X!" % img_format)
		return Image.create_empty(1, 1, false, Image.FORMAT_L8)
		
	if !is_std and remove_alpha:
		image.convert(Image.FORMAT_RGB8)
	elif is_std and img_id > 0 and !keep_alpha_char: # always keep alpha in mask parts of character images
		image.convert(Image.FORMAT_RGB8)
		
	return image
	
	
func make_img(data: PackedByteArray) -> Image:
	var w: int = data.decode_u16(2)
	var h: int = data.decode_u16(4)
	var bpp: int = data.decode_u16(6)
	var img_size: int = data.decode_u32(0xC) << 8
	var pal_size: int = data.decode_u32(img_size + 0x2C) << 8
	
	if bpp != 8 and bpp != 4:
		print_rich("[color=red]Unknown BPP %02d!" % bpp)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGB8)
	
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	
	if bpp == 8:
		var img_dat:PackedByteArray = data.slice(0x20, img_size + 0x20)
		var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(img_size + 0x40, img_size + 0x40 + pal_size), 32)
		
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				#var a: int = palette[pixel_index * 4 + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
	elif bpp == 4:
		pal_size = 0x40
		var img_dat:PackedByteArray = data.slice(0x20, img_size + 0x20)
		var pal: PackedByteArray = data.slice(img_size + 0x40, img_size + 0x40 + pal_size)
		
		for y in range(h):
			for x in range(0, w, 2):  # Two pixels per byte
				var byte_index: int  = (x + y * w) / 2
				var byte_value: int  = img_dat[byte_index]

				# Extract two 4-bit indices (little-endian order)
				var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
				var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

				# Set first pixel
				var r1: int = pal[pixel_index_1 * 4 + 0]
				var g1: int = pal[pixel_index_1 * 4 + 1]
				var b1: int = pal[pixel_index_1 * 4 + 2]
				var a1: int = pal[pixel_index_1 * 4 + 3]
				image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0))

				# Set second pixel (only if within bounds)
				if x + 1 < w:
					var r2: int = pal[pixel_index_2 * 4 + 0]
					var g2: int = pal[pixel_index_2 * 4 + 1]
					var b2: int = pal[pixel_index_2 * 4 + 2]
					var a2: int = pal[pixel_index_2 * 4 + 3]
					image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0))
	return image
	
	
#func tile_images_by_batch(images: Array[Image], final_width: int, final_height: int, is_std: bool) -> Image:
	#var tile_w: int = images[0].get_width()
	#var tile_h: int = images[0].get_height()
#
	#var cols: int = final_width / tile_w
	#var rows: int = final_height / tile_h
	#if !is_std and images.size() >= 180: # there's likely some dynamic way to do this
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 138:
		#pass
	#elif !is_std and images.size() >= 128:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 120:
		#rows += 1
	#elif !is_std and images.size() >= 110:
		#pass
	#elif !is_std and images.size() >= 102:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 91:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 88:
		##cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 80:
		#rows += 1
	#elif !is_std and images.size() >= 70:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 60:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 40:
		#rows += 1
	#elif !is_std and images.size() >= 30:
		#cols += 1
		#rows += 1
	#elif !is_std and images.size() >= 20:
		#cols += 1
		#rows += 1
	#elif is_std and images.size() >= 80:
		#cols += 1
		#rows += 1
	#elif is_std and images.size() >= 68:
		#cols += 1
		#rows += 1
	#elif is_std and images.size() >= 64:
		#cols = int(ceili(sqrt(images.size())))
		#rows = int(ceili(images.size() / float(cols)))
	#elif is_std and images.size() >= 58:
		#cols = int(ceili(sqrt(images.size()))) - 1
		#rows = int(ceili(images.size() / float(cols)))
	#elif is_std and images.size() >= 40:
		#cols = int(ceili(sqrt(images.size()))) - 2
		#rows = int(ceili(images.size() / float(cols)))
	#elif images.size() < 4:
		#cols = 1
		#rows = 3
	#elif is_std and images.size() >= 36:
		#cols += 1
		#rows = int(ceili(images.size() / float(cols)))
	#elif is_std and images.size() < 35:
		#cols = int(ceili(sqrt(images.size()))) - 2
		#rows = int(ceili(images.size() / float(cols)))
#
	#var final_image: Image = Image.create_empty(final_width, final_height, false, images[0].get_format())
#
	## Tile in row-major order until we run out of tiles
	#var img_i: int = 0
	#for row in range(rows):
		#for col in range(cols):
			#if img_i >= images.size():
				#return final_image
#
			#var dst_x: int = col * tile_w
			#var dst_y: int = row * tile_h
			#var tile_img: Image = images[img_i]
#
			## If you want a straight copy (no alpha blending), use blit_rect():
			## If you specifically need to blend (e.g. preserve semi-transparency), use:
			## final_image.blend_rect(tile_img, Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
			#if !is_std and remove_alpha:
				#final_image.blit_rect(tile_img, Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
			#elif is_std and keep_alpha_char:
				#final_image.blend_rect(tile_img, Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
			#else:
				#final_image.blend_rect(tile_img, Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
#
			#img_i += 1
		## next column
	## next row
#
	#return final_image
	
	
func tile_images_by_batch(images: Array[Image], final_width: int, final_height: int, is_std: bool) -> Image:
	var n: int = images.size()
	if n == 0:
		push_error("No images to tile!")
		return Image.create_empty(1,1, false, Image.FORMAT_L8)

	var tile_w: int = images[0].get_width()
	var tile_h: int = images[0].get_height()

	# 1) Find the “closest to square” divisor pair (c ≤ r):
	var grid: Vector2i = get_best_divisor_grid(n)
	var cols: int = grid.x
	var rows: int = grid.y
	
	# I don't know what these games are doing
	
	if n >= 200:
		cols = final_width / tile_w
		rows = final_height / tile_h
	elif Main.game_type == Main.MAPLECOLORS:
		cols = grid.y
		rows = grid.x
		if n >= 120:
			cols = grid.x
			rows = grid.y
		elif n in range(68, 73):
			cols = final_width / tile_w
			rows = int(ceili(n / float(cols)))
		elif n in range(12, 19):
			cols = grid.x
			rows = grid.y
		elif n <= 11:
			cols = final_width / tile_w
			rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 190:
		cols = final_width / tile_w
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 180:
		cols = grid.y
		rows = grid.x
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 170:
		cols = final_width / tile_w
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 168:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 160:
		cols = final_width / tile_w
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 158:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 150:
		cols = grid.x
		rows = grid.y
	elif Main.game_type == Main.HARUNOASHIOTO and n == 144:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 140:
		cols = grid.x
		rows = grid.y
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 130:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 120:
		cols = grid.x
		rows = grid.y
		#cols = final_width / tile_w
		#rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 110:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n >= 90:
		cols = grid.y
		rows = grid.x
	elif n >= 90:
		cols = grid.x
		rows = grid.y
	elif Main.game_type == Main.SCARLETNICHIJOU and n == 70:
		cols = grid.y
		rows = grid.x
	elif n == 70:
		cols = grid.x
		rows = grid.y
	elif n >= 64:
		cols = grid.y
		rows = grid.x
	elif n == 36:
		cols = final_width / tile_w + 1
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.HARUNOASHIOTO and n <= 18:
		cols = grid.y
		rows = grid.x
	elif Main.game_type == Main.SCARLETNICHIJOU and n == 30:
		cols = final_width / tile_w
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.SCARLETNICHIJOU and n in range(42, 49):
		cols = grid.x
		rows = grid.y
	elif Main.game_type == Main.SCARLETNICHIJOU and n in range(9, 59):
		cols = grid.y
		rows = grid.x
	elif Main.game_type == Main.SCARLETNICHIJOU and n in range(8, 12):
		cols = final_width / tile_w
		rows = int(ceili(n / float(cols)))
	elif Main.game_type == Main.SCARLETNICHIJOU and n in range(2, 5):
		cols = grid.y
		rows = grid.x
	elif n in range(4, 9):
		if Main.game_type == Main.HARUNOASHIOTO:
			cols = grid.y
			rows = grid.x
			pass
		elif cols - 1 != 0:
			cols -= 1
		rows = int(ceili(n / float(cols)))

	#print("n=", n, " → cols=", cols, ", rows=", rows)  # debug

	var final_image: Image = Image.create_empty(final_width, final_height, false, images[0].get_format())

	# 3) Blit/blend row-major:
	var img_i: int = 0
	for y in range(rows):
		for x in range(cols):
			if img_i >= n:
				return final_image
			var dst_x: int = x * tile_w
			var dst_y: int = y * tile_h
			if !is_std:
				final_image.blit_rect(images[img_i], Rect2i(0,0,tile_w,tile_h), Vector2i(dst_x,dst_y))
			else:
				final_image.blend_rect(images[img_i], Rect2i(0,0,tile_w,tile_h), Vector2i(dst_x,dst_y))
			img_i += 1
	return final_image
	
	
func get_best_divisor_grid(n: int) -> Vector2i:
	# Returns (c, r) so that c*r == N and |c-r| is minimal.  Always c ≤ r.
	if n <= 0:
		return Vector2i(1,1)
	var best_c: int = 1
	var best_r: int = n
	var best_diff: int = abs(n - 1)
	var limit := int(floor(sqrt(n)))
	for c in range(1, limit+1):
		if n % c == 0:
			var r: int = n / c
			var diff: int = abs(r - c)
			if diff < best_diff:
				best_diff = diff
				best_c = c
				best_r = r
			# (Note: we do NOT swap or tie-break by “larger side.”)
	return Vector2i(best_c, best_r)  # c ≤ r
	
	
func _on_load_folder_dir_selected(dir):
	folder_path = dir
	
	
func _on_load_cd_bin_file_pressed():
	if exe_path == "":
		OS.alert("EXE must be selected first.")
		return
		
	load_bin.show()
	
	
func _on_load_exe_pressed() -> void:
	load_exe.show()
	
	
func _on_load_exe_file_selected(path: String) -> void:
	exe_path = path
	
	
func _on_debug_output_pressed() -> void:
	debug_output = !debug_output


func _on_load_bin_file_selected(path: String) -> void:
	selected_file = path
	load_folder.show()


func _on_load_image_pressed() -> void:
	load_image.show()


func _on_load_image_files_selected(paths: PackedStringArray) -> void:
	selected_imgs = paths
	load_folder.show()


func _on_tiled_output_toggled(_toggled_on: bool) -> void:
	tile_output = !tile_output


func _on_remove_alpha_1_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_remove_alpha_2_toggled(_toggled_on: bool) -> void:
	keep_alpha_char = !keep_alpha_char


func _on_load_bin_2_file_selected(path: String) -> void:
	data_bin_path = path
	load_folder.show()


func _on_load_databin_pressed() -> void:
	load_databin.show()
