extends Control

@onready var file_load_image: FileDialog = $FILELoadIMAGE
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var load_image: Button = $HBoxContainer/LoadImage
@onready var load_ptd: Button = $HBoxContainer/LoadPTD
@onready var file_load_ptd: FileDialog = $FILELoadPTD
@onready var remove_alpha_box: CheckBox = $"VBoxContainer/Remove Alpha"
@onready var output_debug: CheckBox = $"VBoxContainer/Output Debug"

var folder_path: String
var selected_files: PackedStringArray
var selected_ptds: PackedStringArray
var remove_alpha: bool = true
var debug_out: bool = false

# TODO: Make sense of number of colors in an image. See make_img()

func _ready() -> void:
	if Main.game_type == Main.ROSARIO:
		load_image.show()
		load_ptd.hide()
		remove_alpha_box.show()
		output_debug.show()
	elif Main.game_type == Main.JIGOKUSHOUJO:
		load_image.hide()
		load_ptd.show()
		remove_alpha_box.hide()
		output_debug.hide()
	
	
func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_image()
		folder_path = ""
		selected_files.clear()
	elif folder_path and selected_ptds:
		extract_ptd()
		folder_path = ""
		selected_ptds.clear()
		
		
func extract_image() -> void:
	var buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var f_name: String
	var f_size: int
	var f_offset: int
	var num_files: int
	var pos: int
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file()
		if arc_name.get_extension() == "abg" or arc_name.get_extension() == "bst":
			buff = lzr_decompress(in_file.get_buffer(in_file.get_length()))
			
			if debug_out:
				out_file = FileAccess.open(folder_path + "/%s" % arc_name + ".dec", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			num_files = buff.decode_u16(2)
			pos = 0x10
			for i in num_files:
				var unk_8: int = buff.decode_u8(pos + 1)
				f_size = buff.decode_u32(pos + 4)
				f_offset = buff.decode_u32(pos + 0xC)
				f_name = buff.slice(pos + 0x10, pos + 0x30).get_string_from_ascii()
				
				var new_buff: PackedByteArray = buff.slice(f_offset, f_offset + f_size)
				if f_name.get_extension() == "tm2" and debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(new_buff)
					out_file.close()
				elif f_name.get_extension() != "tm2":
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(new_buff)
					out_file.close()
					
				if f_name.get_extension() == "tm2":
					var png: Image = make_img(new_buff)
					png.save_png(folder_path + "/%s" % f_name + ".PNG")
					
				print("%08X %08X %s %s/%s" % [f_offset, f_size, arc_name, folder_path, f_name])
				
				pos += 0x20
		elif arc_name.get_extension() == "tex":
			arc_name += ".PNG"
			var png: Image = make_img(in_file.get_buffer(in_file.get_length()))
			png.save_png(folder_path + "/%s" % arc_name)
			
			print("%s/%s" % [folder_path, arc_name])
		elif arc_name.get_extension() == "pac":
			var buffers: Array
			buff = in_file.get_buffer(in_file.get_length())
			num_files = buff.decode_u16(2)
			if num_files == 0:
				print_rich("[color=yellow]Skipping %s as num_files is 0" % arc_name)
				continue
				
			pos = 0x10
			for i in num_files:
				var unk_8: int = buff.decode_u8(pos + 1)
				f_size = buff.decode_u32(pos + 4)
				f_offset = buff.decode_u32(pos + 0xC)
				f_name = buff.slice(pos + 0x10, pos + 0x30).get_string_from_ascii()
				var new_buff: PackedByteArray = buff.slice(f_offset, f_offset + f_size)
				if new_buff.slice(0, 3).get_string_from_ascii() == "LZR":
					buffers.append(f_name)
					buffers.append(lzr_decompress(new_buff))
				else:
					buffers.append(f_name)
					buffers.append(new_buff)
				pos += 0x20
			for arr_idx in range(0, buffers.size(), 2):
				var dir: DirAccess = DirAccess.open(folder_path)
				dir.make_dir_recursive(folder_path + "/" + arc_name)
				f_name = buffers[arr_idx]
				buff = buffers[arr_idx + 1]
				if f_name.get_extension() == "bst" or f_name.get_extension() == "abg":
					num_files = buff.decode_u16(2)
					pos = 0x10
					for i in num_files:
						var unk_8: int = buff.decode_u8(pos + 1)
						f_size = buff.decode_u32(pos + 4)
						f_offset = buff.decode_u32(pos + 0xC)
						f_name = buff.slice(pos + 0x10, pos + 0x30).get_string_from_ascii()
						
						var new_buff: PackedByteArray = buff.slice(f_offset, f_offset + f_size)
						if (f_name.get_extension() == "tm2" or f_name.get_extension() == "tex") and debug_out:
							out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(new_buff)
							out_file.close()
						elif f_name.get_extension() != "tm2" and f_name.get_extension() != "tex":
							out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(new_buff)
							out_file.close()
							
						if f_name.get_extension() == "tm2" or f_name.get_extension() == "tex":
							var png: Image = make_img(new_buff)
							png.save_png(folder_path + "/%s" % arc_name + "/%s" % f_name + ".PNG")
								
						print("%08X %08X %s %s/%s/%s" % [f_offset, f_size, arc_name, folder_path, arc_name, f_name])
						
						pos += 0x20
				else:
					if f_name.get_extension() == "tm2" or f_name.get_extension() == "tex":
						var png: Image = make_img(buff)
						png.save_png(folder_path + "/%s" % arc_name + "/%s" % f_name + ".PNG")
					else:
						out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						
					print("%08X %08X %s %s/%s/%s" % [f_offset, f_size, arc_name, folder_path, arc_name, f_name])
	print_rich("[color=green]Finished![/color]")
	
	
func extract_ptd() -> void:
	var buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var ptd_all_file: FileAccess
	var tables: Dictionary = {}
	var ptd_names_off: int
	var ptd_name: String
	var num_files: int
	var f_name: String
	var f_size: int
	var f_offset: int
	var pos: int
	var off_tbl: int
	var last_tbl: int
	
	for file in range(selected_ptds.size()):
		in_file = FileAccess.open(selected_ptds[file], FileAccess.READ)
		ptd_all_file = FileAccess.open(selected_ptds[file].get_base_dir() + "/PTDALL.PID", FileAccess.READ)
		if ptd_all_file == null:
			OS.alert("Please place 'PTDALL.PID' in the same directory as your selected .PTD file.")
			return
			
		var selected_ptd_name: String = selected_ptds[file].get_file()
		
		ptd_all_file.seek(0)
		num_files = ptd_all_file.get_32()
		ptd_names_off = (num_files << 2) + 4
		off_tbl = (num_files << 4) + 0x34
		
		ptd_all_file.seek(ptd_names_off)
		ptd_name = ptd_all_file.get_line()
		
		for tbl in range(0, num_files):
			ptd_all_file.seek((tbl * 0x10) + ptd_names_off)
			ptd_name = ptd_all_file.get_line()
			
			ptd_all_file.seek((tbl * 4) + 4)
			var ptd_files: int = ptd_all_file.get_32()
			last_tbl = (ptd_files << 3) + off_tbl
			var info: Array[int] = [ptd_files, off_tbl]
			tables[ptd_name] = info.duplicate()
			info.clear()
			
			off_tbl = last_tbl
		if selected_ptd_name in tables:
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + selected_ptd_name)
			
			off_tbl = tables[selected_ptd_name][1]
			for ptd_file in range(0, tables[selected_ptd_name][0]):
				f_name = "%08d" % ptd_file
				
				ptd_all_file.seek((ptd_file * 8) + off_tbl)
				f_offset = ptd_all_file.get_32() * 0x800
				f_size = ptd_all_file.get_32()
				if f_size == 0:
					continue
					
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					f_name += ".TM2"
				elif buff.decode_u32(0) == 0:
					f_name += ".ADPCM"
				else:
					if selected_ptd_name == "PTD000.PTD":
						var tm2_arr: Array[PackedByteArray] = ComFuncs.tim2_scan_buffer(buff, 4)
						for tm2 in range(0, tm2_arr.size()):
							out_file = FileAccess.open(folder_path + "/%s" % selected_ptd_name + "/%s" % f_name + ".BIN_%04d.TM2" % tm2, FileAccess.WRITE)
							out_file.store_buffer(tm2_arr[tm2])
							out_file.close()
					f_name += ".BIN"
					
				out_file = FileAccess.open(folder_path + "/%s" % selected_ptd_name + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
						
				print("%08X %08X %s %s/%s/%s" % [f_offset, f_size, selected_ptd_name, folder_path, selected_ptd_name, f_name])
				
	print_rich("[color=green]Finished![/color]")
	
	
func lzr_decompress(compressed: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray
	var v0: int
	var v1: int
	var a0: int = 0  # Stack offset
	var a1: int = 0 #compressed.size() - 0x10
	var a2: int = 0  # Output offset
	var a3: int
	var t0: int
	var t1: int
	var t2: int
	var t3: int
	var t4: int
	var t5: int
	var t6: int
	var t7: int
	var t8: int
	var t9: int
	var s0: int
	var s1: int
	var s2: int
	var s3: int
	var s4: int
	var s5: int
	var dec_size: int = compressed.decode_u32(0xC)
	var header_buff: PackedByteArray # Acts as a0 offset (pointer to stack)
	
	out.resize(dec_size)
	header_buff.resize(0x20)
	#header_buff.encode_u32(0, 0) # out offset
	#header_buff.encode_u32(0x8, 0) # Compressed data start
	header_buff.encode_u32(0xC, compressed.decode_u32(4))
	header_buff.encode_u32(0x14, compressed.decode_u32(8))
	t4 = compressed.decode_u32(4)
	t7 = t4 + 7
	t5 = t4 + 0xE
	t6 = t7 > 0
	if t6 == 0: # How can this ever happen? Who knows.
		t7 = t5
	header_buff.encode_u32(0x10, t7 >> 3)
	compressed = compressed.slice(0x10)
	
	var goto: String = "init"
	while true:
		match goto:
			"init":
				t1 = header_buff.decode_u32(0xC)
				t3 = header_buff.decode_u32(0)
				t0 = 0xC0
				t7 = t1 >> 31
				t7 = t1 + t7
				a2 = 0
				t7 >>= 1
				t6 = t3
				a3 = header_buff.decode_u32(0x8) # Compressed data start off
				t2 = header_buff.decode_u32(0x10) # Some new offset pointer
				if t7 <= 0:
					goto = "00145334"
				else:
					a1 = 0xC
					v0 = 2
					s2 = 1
					s0 = 4
					s5 = 8
					v1 = 0x30
					t8 = 0x10
					s1 = 0x20
					t9 = 0x80
					s3 = 0x40
					s4 = 0xC0
					t7 = compressed.decode_u8(a3)
					goto = "00145280"
			"00145280":
				t6 = t7 & t0
				t7 = t6 < 0xD
				if t6 == a1:
					goto = "001453A8"
				elif t7 == 0:
					goto = "00145400"
				else:
					goto = "00145294" # Fake but needed since we don't have proper gotos
			"00145294":
				t7 = t6 < 0x3
				if t6 == v0:
					goto = "0014536C"
				elif t7 == 0:
					goto = "00145354"
				elif t6 == 0:
					goto = "00145340"
					t7 = compressed.decode_u8(t2)
				elif t6 == s2:
					goto = "001452D8"
					t5 = compressed.decode_u8(t2)
				else:
					break
			"001452D4":
				t5 = compressed.decode_u8(t2)
				goto = "001452D8"
			"001452D8":
				t4 = 0
				t2 += 1
				if t5 == 0:
					goto = "00145304"
				else:
					t6 = 1
					while t6 != 0:
						t7 = compressed.decode_u8(t2)
						t4 += 1
						t6 = t4 < t5
						out.encode_s8(t3, t7)
						t2 += 1
						t3 += 1
					t1 = header_buff.decode_u32(0xC)
					goto = "00145304"
			"00145304":
				t0 >>= 2
				t7 = t1 >> 31
				if t0 != 0:
					goto = "00145318"
				else:
					t0 = 0xC0
					a3 += 1
					goto = "00145318"
			"00145318":
				a2 += 1
				t7 = t1 + t7
				t7 >>= 1
				t7 = a2 < t7
				if t7 != 0:
					goto = "00145280"
					t7 = compressed.decode_u8(a3)
				else:
					goto = "00145334"
			"00145334":
				t6 = header_buff.decode_u32(0)
				t7 =  t4 - t6
				# goto = "001452B4"
				header_buff.encode_s32(4, t7)
				break
			"00145340":
				out.encode_s8(t3, t7)
				t2 += 1
				t1 = header_buff.decode_u32(0xC)
				goto = "00145304"
				t3 += 1
			"00145354":
				t7 = t6 < 4
				if t6 == s0:
					goto = "001452D4"
				else:
					if t7 != 0:
						goto = "001453AC"
						t5 = compressed.decode_u8(t2 + 1)
					elif t6 != s5:
						break
					else:
						goto = "0014536C"
			"0014536C":
				t5 = compressed.decode_u8(t2)
				goto = "00145370"
			"00145370":
				t4 = 0
				t2 += 1
				t6 = compressed.decode_u8(t2)
				t2 += 1
				if t5 == 0:
					goto = "00145304"
				else:
					t7 = 1
					while t7 != 0:
						out.encode_s8(t3, t6)
						t4 += 1
						t7 = t4 < t5
						t3 += 1
					goto = "00145304"
					t1 = header_buff.decode_u32(0xC)
			"001453A8":
				t5 = compressed.decode_u8(t2 + 1)
				goto = "001453AC"
			"001453AC":
				t6 = compressed.decode_u8(t2)
				t7 = t5 & 0xFF
				t6 <<= 4
				t7 >>= 4
				t5 &= 0xF
				t6 = t6 + t7
				t5 &= 0xFF # but why
				t6 = t3 - t6
				t2 += 2
				if t5 == 0:
					goto = "00145304"
				else:
					t4 = t5
					t7 = out.decode_u8(t6)
					t4 -= 1
					out.encode_s8(t3, t7)
					t6 += 1
					t3 += 1
					while t4 != 0:
						t7 = out.decode_u8(t6)
						t4 -= 1
						out.encode_s8(t3, t7)
						t6 += 1
						t3 += 1
					goto = "00145304"
					t1 = header_buff.decode_u32(0xC)
			"00145400":
				t7 = t6 < 0x31
				if t6 == v1:
					goto = "001453A8"
				elif t7 == 0:
					goto = "00145428"
				elif t6 == t8:
					goto = "001452D8"
					t5 = compressed.decode_u8(t2)
				elif t6 == s1:
					goto = "00145370"
					t5 = compressed.decode_u8(t2)
				else:
					break
			"00145428":
				t7 = t6 < 0x81
				if t6 == t9:
					goto = "0014536C"
				elif t7 == 0:
					goto = "00145448"
				elif t6 == s3:
					goto = "001452D8"
					t5 = compressed.decode_u8(t2)
				else:
					break
			"00145448":
				if t6 == s4:
					goto = "001453AC"
					t5 = compressed.decode_u8(t2 + 1)
				else:
					break
	return out


func make_img(data: PackedByteArray) -> Image:
	var bpp: int = data.decode_u16(0) # 1 = 8bb, 2 = 16bpp, 3 = 32bpp
	var image_width: int = data.decode_u16(2)
	var image_height: int = data.decode_u16(4)
	var num_colors: int = data.decode_u16(6) # Determines palette size as well
	if num_colors != 256:
		push_error("Number of colors in image isn't 256. Output will be wrong!")
		#return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	if bpp != 1:
		push_error("image bpp isn't 8. Output will be wrong!")
		#return Image.create(1, 1, false, Image.FORMAT_RGBA8)

	var palette_offset: int = data.decode_u32(0x8) + 0x10
	var palette: PackedByteArray = PackedByteArray()
	if num_colors == 256:
		for i in range(0, 0x400):
			palette.append(data.decode_u8(palette_offset + i))
		palette = ComFuncs.unswizzle_palette(palette, 32)
		if remove_alpha:
			for i in range(0, 0x400, 4):
				palette.encode_u8(i + 3, 255)
	else:
		palette = data.slice(palette_offset)
	

	var image_data_offset: int = 0x10
	var pixel_data: PackedByteArray = data.slice(image_data_offset, image_data_offset + image_width * image_height)

	var image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)

	for y in range(image_height):
		for x in range(image_width):
			var pixel_index: int = pixel_data[x + y * image_width]
			var r: int = palette[pixel_index * 4 + 0]
			var g: int = palette[pixel_index * 4 + 1]
			var b: int = palette[pixel_index * 4 + 2]
			var a: int = palette[pixel_index * 4 + 3]
			image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))

	return image
	
	
func _on_load_image_pressed() -> void:
	file_load_image.show()


func _on_file_load_image_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_file_load_ptd_files_selected(paths: PackedStringArray) -> void:
	selected_ptds = paths
	file_load_folder.show()


func _on_load_ptd_pressed() -> void:
	file_load_ptd.show()
