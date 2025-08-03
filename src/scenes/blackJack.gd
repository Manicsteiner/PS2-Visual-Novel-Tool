extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_str: FileDialog = $FILELoadSTR

var folder_path: String
var selected_files: PackedStringArray
var str_path: String
var out_org: bool = false


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		str_path = ""
	elif str_path and folder_path:
		extract_strm()
		folder_path = ""
		selected_files.clear()
		str_path = ""
		
		
func extract_arc() -> void:
	var step_mod: int
	var f_name: String
	var f_offset: int
	var f_size: int
	var num_files: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	if Main.game_type == Main.MOEMOE2JIDEL or Main.game_type == Main.MOEMOE2JI2:
		step_mod = 12
	else:
		step_mod = 8
		
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		if in_file.get_buffer(4).get_string_from_ascii() == "PACK":
			num_files = in_file.get_32()
			for f_file in num_files:
				in_file.seek((f_file * 0x90) + step_mod)
				
				var _hash1: int = in_file.get_32()
				var _hash2: int = in_file.get_32()
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				var result: Array = ComFuncs.find_end_bytes_file(in_file, 0)
				f_name = ComFuncs.convert_jis_packed_byte_array(result[1], shift_jis_dic).get_string_from_utf8()
				#if f_name != "TEXTURE/EV1/EV_KYOU_401A.HTD": continue
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				if buff.slice(0, 4).get_string_from_ascii() == "LZSS":
					f_size = buff.decode_u32(4)
					buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size, 0xFF0)
				if buff.slice(0, 3).get_string_from_ascii() == "HTD":
					var w: int = buff.decode_u16(8)
					var h: int = buff.decode_u16(10)
					var pal_off: int = buff.decode_u32(12) + 0x14
					var pal_size: int = buff.decode_u32(16)
					
					var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
					var img_dat: PackedByteArray = buff.slice(0x14, pal_off + 14)
					var pal: PackedByteArray = buff.slice(pal_off, pal_off + pal_size)
					if pal_size == 0x400:
						for y in range(h):
							for x in range(w):
								var pixel_index: int = img_dat[x + y * w]
								var r: int = pal[pixel_index * 4 + 0]
								var g: int = pal[pixel_index * 4 + 1]
								var b: int = pal[pixel_index * 4 + 2]
								var a: int = pal[pixel_index * 4 + 3]
								a = int((a / 128.0) * 255.0)
								
								image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
					elif pal_size == 0x40:
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
								a1 = int((a1 / 128.0) * 255.0)
								
								image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

								# Set second pixel (only if within bounds)
								if x + 1 < w:
									var r2: int = pal[pixel_index_2 * 4 + 0]
									var g2: int = pal[pixel_index_2 * 4 + 1]
									var b2: int = pal[pixel_index_2 * 4 + 2]
									var a2: int = pal[pixel_index_2 * 4 + 3]
									a2 = int((a2 / 128.0) * 255.0)
									
									image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
					elif pal_size == 0:
						img_dat = buff.slice(0x14)
						var dir: DirAccess = DirAccess.open(folder_path)
						dir.make_dir_recursive(f_name.get_base_dir())
						if out_org:
							out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(buff)
							out_file.close()
						
						for i in range(0, img_dat.size(), 4):
							img_dat.encode_u8(i + 3, int((img_dat.decode_u8(i + 3) / 128.0) * 255.0))
							
						var image2: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, img_dat)
						image2.save_png(folder_path + "/%s" % f_name + ".PNG")
						continue
					else:
						push_error("Unknown palette size %X in %s" % [pal_size, f_name])
							
					var dir: DirAccess = DirAccess.open(folder_path)
					dir.make_dir_recursive(f_name.get_base_dir())
					image.save_png(folder_path + "/%s" % f_name + ".PNG")
					if out_org:
						out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
					continue
						
				var dir: DirAccess = DirAccess.open(folder_path)
				dir.make_dir_recursive(f_name.get_base_dir())
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
		else:
			print_rich("[color=red]%s is an unknown BIN file. Skipping.[/color]" % arc_name)
			continue
			
	print_rich("[color=green]Finished![/color]")
	
	
func extract_strm() -> void:
	#TODO: Loops in exe for some games.
	#Izumo zero: 0x005f1218 + loop math in function 0x0011E730
	
	var in_file: FileAccess
	var out_file: FileAccess
	
	in_file = FileAccess.open(str_path, FileAccess.READ)
	var arc_name: String = str_path.get_file()
	if in_file.get_buffer(4).get_string_from_ascii() != "STRM":
		OS.alert("Invalid STRM header in %s" % arc_name)
		return
		
	var string: String
	var out_name: String = ".BIN.txth"
	
	out_file = FileAccess.open(folder_path + "/%s" % out_name, FileAccess.WRITE)
	
	in_file.seek(4)
	var num_entries: int = in_file.get_32()
			
	string = "codec             = PSX"
	out_file.store_line(string)
	string = "interleave        = 0x2000"
	out_file.store_line(string)
	string = "padding_size      = auto-empty"
	out_file.store_line(string)
	out_file.store_string("\n")
	string = "header_file       = %s" % arc_name
	out_file.store_line(string)
	string = "body_file         = STRM_PAC.BIN"
	out_file.store_line(string)
	out_file.store_string("\n")
	string = "subsong_count     = %02d" % num_entries
	out_file.store_line(string)
	string = "subsong_offset    = 0x1C"
	out_file.store_line(string)
	out_file.store_string("\n")
	string = "base_offset       = 0x10"
	out_file.store_line(string)
	out_file.store_string("\n")
	string = "sample_type       = bytes"
	out_file.store_line(string)
	out_file.store_string("\n")
	string = "channels          = @0x14"
	out_file.store_line(string)
	string = "start_offset      = @0x0C * 0x800"
	out_file.store_line(string)
	string = "sample_rate       = @0x10"
	out_file.store_line(string)
	string = "data_size         = @0x04"
	out_file.store_line(string)
	string = "num_samples       = data_size"
	out_file.store_line(string)
	#string = "loop_flag         = auto"
	#out_file.store_line(string)
	print("%s/%s" % [folder_path, out_name])
	print_rich("[color=green]Finished![/color]")
	
	
func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_org_htd_toggled(_toggled_on: bool) -> void:
	out_org = !out_org


func _on_file_load_str_file_selected(path: String) -> void:
	str_path = path
	file_load_folder.show()


func _on_load_str_pressed() -> void:
	file_load_str.show()
