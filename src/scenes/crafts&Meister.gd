extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var out_org: bool = false

#TODO: CVM extractor

func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		

func extract_arc() -> void:
	var f_name: String
	var f_offset: int
	var f_size: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		var arc_name_full: String = selected_files[file].get_file()
		var hdr_str: String = in_file.get_buffer(4).get_string_from_ascii()
		
		in_file.seek(0)
		if hdr_str == "OOCH":
			buff = lz_code_geass_mips(in_file.get_buffer(in_file.get_length()))
		elif hdr_str == "pack":
			buff = in_file.get_buffer(in_file.get_length())
		else:
			print_rich("[color=red]Unknown header %s in %s[/color]" % [hdr_str, arc_name_full])
			continue
			
		if out_org:
			out_file = FileAccess.open(folder_path + "/%s" % arc_name_full + ".PACK", FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
		var hdr_str_buff: String = buff.slice(0, 4).get_string_from_ascii()
		if hdr_str_buff == "pack":
			var num_files: int = buff.decode_u32(8)
			var bup_mod: int = 0
			if num_files > 32:
				num_files = buff.decode_u16(4)
				bup_mod = 0xC + ((num_files - 1) / 4) * 4 + num_files * 4
			if arc_name_full == "OMKALLJ.P": # why is this file different from the others???
				num_files = 0x1C
				
			for p_files in range(num_files):
				# this file format sucks
				var entry_pos: int = 0x10 + p_files * 4
				if bup_mod:
					entry_pos = bup_mod + p_files * 4
				f_offset = buff.decode_u32(entry_pos)
				f_size = buff.decode_u32(entry_pos + 4)
				if f_size > buff.size() or f_size <= 0:
					f_size = buff.size()
				
				var out_buff: PackedByteArray = buff.slice(f_offset, f_size)
				var ext: String
				if out_buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					ext = ".TM2"
					var num_tm2s: int = out_buff.decode_u16(6)
					if num_tm2s > 1:
						var tm2_hdr: PackedByteArray = out_buff.slice(0, 0x80)
						tm2_hdr.encode_u8(6, 1)
						var last_pos: int = 0
						entry_pos = 0x80
						
						for tm2 in range(num_tm2s):
							var tm2_size: int = out_buff.decode_u32(entry_pos)
							var tm2_buff: PackedByteArray = out_buff.slice(entry_pos, tm2_size + entry_pos)
							
							f_name = "%s_%04d_%04d%s" % [arc_name, p_files, tm2, ext]
							
							print("%08X %08X %s/%s" % [entry_pos, tm2_size + entry_pos, folder_path, f_name])
							
							var tm2_f_buff: PackedByteArray
							tm2_f_buff.append_array(tm2_hdr)
							tm2_f_buff.append_array(tm2_buff)
							
							out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(tm2_f_buff)
							out_file.close()
							
							last_pos += entry_pos
							entry_pos += tm2_size
						#continue
				elif out_buff.slice(0, 4).get_string_from_ascii() == "FGB":
					ext = ".FGB"
				else:
					ext = ".BIN"
					
				f_name = "%s_%04d%s" % [arc_name, p_files, ext]
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(out_buff)
				out_file.close()
			continue
			
	print_rich("[color=green]Finished![/color]")
	
	
func lz_code_geass_mips(input: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray
	var s4_buff: PackedByteArray
	var at: int
	var v0: int
	var v1: int
	var a0: int # ?
	var a1: int
	var a2: int
	var a3: int
	var t0: int 
	var t2: int
	var s0: int
	var s1: int # out size
	var s2: int = 0 # out offset
	var s5: int
	var _00C4: int = 8
	var _00C8: int
	var _00CC: int = 0x800 # offset to compressed data
	var _00A0: int = 0xFFFFFFFF
	var _0014_s3: int = 0 # output offset
	var _0024_s3: int = 0 # counter for something
	
	s1 = input.decode_u32(0xC)
	out.resize(s1)
	# 0012E8E8
	s4_buff.resize(16)
	var temp: int = input.decode_s32(0x20)
	s4_buff.encode_s8(4, temp)
	temp = input.decode_s32(0x24)
	s4_buff.encode_s8(5, temp)
	a2 = temp & 0xFF
	
	v1 = input.decode_u32(0x20)
	a1 = v1 & 0xFF
	v1 = v0 << a1
	a0 = v1 - 1
	s4_buff.encode_s8(6, a0)
	v0 = v0 << a2
	v1 = v0 - 1
	s4_buff.encode_s8(7, v1)
	v0 = a1 + a2
	v1 = v0 + 8
	v0 = v1 >> 1
	s4_buff.encode_s8(8, v0)
	v0 = a1 + 1
	v0 = v0 + a2
	s4_buff.encode_s8(9, v0)
	var off: int = 0
	while true:
		match off:
			0:
				a0 =  input.decode_u32(8) # comp size
				#a0 = 0x2000
				_00C8 = a0
				off = 0x0010DF50
			0x0010DF50:
				# 0010DF50
				if a0 > 0:
					a1 = _00C4
					t0 = _00CC
					v1 = input.decode_u8(t0)
					v0 = a1 - 1
					v1 = v1 >> v0
					v1 &= 1
					if v1 == 0:
						off = 0x0010E010
					else:
						a0 -= 1
						v1 = s4_buff.decode_u8(9)
						a0 <<= 3
						a0 = a1 + a0
						at = a0 < v1
						if at == 0:
							_00C4 = v0
							if v0 == 0: #0010DFA8 if equal
								v0 = t0 + 1
								v1 = 8
								_00CC = v0
								v0 = _00C8
								_00C4 = v1
								v0 -= 1
								_00C8 = v0
							#0010DFD0 DO
							t0 = s4_buff.decode_u8(4)
							#a0 = s4_buff
							a1 = _00CC
							a2 = _00C8
							a3 = _00C4
							var arr: Array[int] = _lz_code_geass_mips(a1, a2, a3, t0, input)
							_00CC = arr[0]
							_00C8 = arr[1]
							_00C4 = arr[2]
							v0 = arr[3]
							s5 = v0
							a1 = _00CC
							a2 = _00C8
							a3 = _00C4
							arr = _lz_code_geass_mips(a1, a2, a3, t0, input)
							_00CC = arr[0]
							_00C8 = arr[1]
							_00C4 = arr[2]
							v0 = arr[3]
							off = 0x0010E098
							s0 = v0
						else:
							off = 0x0010E0A0
							v0 = 0
				else:
					off = 0x0010E0A0
					v0 = 0
			0x0010E010:
				at = a0 < 2
				if at == 0:
					off = 0x0010e028
				else:
					off = 0x0010E0A0
					v0 = 0
			0x0010E028:
				v1 = 1
				if a1 != v1:
					off = 0x0010E058
				# 0010E034
				else:
					v0 = _00C8
					v1 = t0 + 2
					s0 = input.decode_u8(t0 + 1)
					a0 = 8
					v0 -= 2
					_00C4 = a0
					_00CC = v1
					off = 0x0010E090
					_00C8 = v0
			0x0010E058:
				_00C4 = v0
				v1 = 8
				a1 = input.decode_u8(t0 + 1)
				a2 = v1 - v0
				a3 = input.decode_u8(t0)
				a0 = t0 + 1
				v1 = _00C8
				a1 >>= v0
				a2 = a3 << a2
				_00CC = a0
				a0 = a2 & 0xFF
				v0 = v1 - 1
				s0 = a0 | a1
				_00C8 = v0
				off = 0x0010E090
			0x0010E090:
				s5 = 0xFFFFFFFF
				off = 0x0010E098
			0x0010E098:
				v0 = 1 # daddiu v0, zero, $0001 ???
				off = 0x0010E0A0
			0x0010E0A0:
				if v0 != 0:
					off = 0x0010E0B8
				else:
					#v0 = _00C8
					#_00B0 = v0
					off = 0x0010E1B0
					#_00C8 = 0
			0x0010E0B8:
				v0 = 0xFFFFFFFF
				if s5 == v0:
					off = 0x0010E0E0
				else:
					if s5 == 0:
						off = 0x0010E0D8
					else:
						off = 0x0010E120
			0x0010E0D8:
				off = 0x0010E188
			0x0010E0E0:
				if s1 == 0 or s1 > 0x7FFFFFFF or s1 < 0:
					off = 0x0010E180
				else:
					out.encode_s8(s2, s0)
					s1 -= 1
					v0 = _0014_s3
					s2 += 1
					s0 = 0
					s5 = 0
					v1 = 1 # daddiu v1, zero, $0001 ???
					v0 += 1
					_0014_s3 = v0
					v0 = _0024_s3
					v0 += 1
					off = 0x0010E188
					_0024_s3 = v0
			0x0010E120:
				v0 = s1 < s0
				if v0 != 0:
					off = 0x0010E180
				else:
					v1 = s2 - s5
					a0 = s0
					while true:
						v0 = out.decode_u8(v1)
						s0 -= 1
						out.encode_s8(s2, v0)
						v1 += 1
						s2 += 1
						if s0 == 0 or s0 == 0xFFFFFFFF:
							break
					v0 = _0014_s3
					s1 = s1 - a0
					s0 = 0
					s5 = 0
					v1 = 1 # daddiu v1, zero, $0001 ???
					v0 = v0 + a0
					_0014_s3 = v0
					v0 = _0024_s3
					v0 = v0 + a0
					off = 0x0010E188
					_0024_s3 = v0
			0x0010E180: 
				break
			0x0010E188:
				if v1 == 0:
					break
				else:
					a0 = _00C8
					if a0 == 0 or a0 == -1 or a0 == 0xFFFFFFFF:
						break
					else:
						if s1 > 0:
							off = 0x0010DF50
						else:
							# ???
							#off = 0x0010DE08
							break
			0x0010E1B0:
				break
			_:
				push_error("Shouldn't go here")
				break
	return out
	
func _lz_code_geass_mips(a1: int, a2: int, a3: int, t0: int, in_buff: PackedByteArray) -> Array[int]:
	var at: int
	var v0: int
	var v1: int
	var a0: int
	var t1: int
	var t2: int
	var t3: int
	var t4: int
	
	var off: int = 0
	while true:
		match off:
			0:
				a0 = a3
				v1 = 8
				v0 = 0
				if a0 != v1:
					off = 0x0010DBDC
				else:
					v1 = t0 < 8
					off = 0x0010DB74
			0x0010DB74:
				if v1 != 0:
					off = 0x0010DBA8
				else:
					v1 = a1
					a0 = v0 << 8
					t0 -= 8
					v0 = in_buff.decode_u8(v1)
					v1 += 1
					v0 = a0 | v0
					a1 = v1
					v1 = a2
					v1 -= 1
					off = 0x0010DBCC
					a2 = v1
			0x0010DBA8:
				v1 = 8
				a0 = v1 - t0
				v0 = v0 << t0
				a3 = a0
				v1 = a1
				v1 = in_buff.decode_u8(v1)
				v1 = v1 >> a0
				off = 0x0010DD00
				v0 = v0 | v1
			0x0010DBCC:
				if t0 != 0:
					v1 = t0 < 8
					off = 0x0010DB74
				else:
					off = 0x0010DD00
			0x0010DBDC:
				v1 = t0 < 8
				if v1 != 0:
					off = 0x0010DC38
				else:
					t3 = a1
					t1 = v0 << 8
					t4 = a3
					v1 = 8
					t0 -= 8
					t2 = in_buff.decode_u8(t3)
					v0 = t3 + 1
					a0 = v1 - t4
					v1 = in_buff.decode_u8(t3 + 1)
					t2 = t2 << a0
					a1 = v0
					a0 = v1 >> t4
					v1 = a2
					v0 = t2 & 0xFF
					v0 = t1 | v0
					v0 = v0 | a0
					v1 -= 1
					off = 0x0010DCF8
					a2 = v1
			0x0010DC38:
				a0 = a3
				at = a0 < t0
				if at != 0:
					v1 = v0 << t0
					off = 0x0010DC9C
				else:
					t2 = 8
					t3 = a1
					t1 = t2 - a0
					v1 = a0 - t0
					a0 = t2 - t0
					v0 = v0 << t0
					t0 = in_buff.decode_u8(t3)
					t0 = t0 << t1
					a3 = v1
					t0 &= 0xFF
					a0 = t0 >> a0
					v0 = v0 | a0
					if v1 != 0:
						off = 0x0010DD00
					else:
						a3 = t2
						v1 = a1
						v1 += 1
						a1 = v1
						v1 = a2
						v1 -= 1
						off = 0x0010DD00
						a2 = v1
			0x0010DC9C:
				t1 = a1
				t3 = t0 - a0
				v0 = 8
				t2 = v0 - t3
				v0 = 1
				t0 = in_buff.decode_u8(t1)
				v0 = v0 << a0
				a0 = v0 - 1
				v0 = in_buff.decode_u8(t1 + 1)
				a0 = t0 & a0
				a0 = a0 << t3
				a0 &= 0xFF
				a3 = t2
				a0 = v1 | a0
				v1 = a1
				v0 = v0 >> t2
				v0 = v0 | a0
				v1 += 1
				a1 = v1
				v1 = a2
				v1 -= 1
				off = 0x0010DD00
				a2 = v1
			0x0010DCF8:
				if t0 != 0:
					v1 = t0 < 8
					off = 0x0010DBE0
				else:
					break
			0x0010DD00:
				break
			_:
				push_error("Shouldn't go here (sub function)")
				break
				
	var arr: Array[int]
	arr.resize(4)
	arr[0] = a1
	arr[1] = a2
	arr[2] = a3
	arr[3] = v0
	return arr
	
	
func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_decompress_files_toggled(_toggled_on: bool) -> void:
	out_org = !out_org
