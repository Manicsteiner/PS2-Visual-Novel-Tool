extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var out_comp: bool = false
	
	
func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract_arc()
		selected_files.clear()
		folder_path = ""
	
	
func extract_arc() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var num_files: int
	var off_tbl: int
	var name_tbl: int
	var name_tbl_size: int
	var f_offset: int
	var f_name: String
	var f_size: int
	var f_ext: String
	var ext: String
	
	
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	for file in range(selected_files.size()):
		if selected_files[file].get_extension().to_lower() == "afs":
			in_file = FileAccess.open(selected_files[file], FileAccess.READ)
			
			in_file.seek(4)
			num_files = in_file.get_32()
			
			off_tbl = 8
			
			in_file.seek((num_files * 8) + off_tbl)
			name_tbl = in_file.get_32()
			name_tbl_size = in_file.get_32()
			
			if name_tbl == 0 or name_tbl_size == 0:
				# check for odd cases where name table isn't the last in the offset table
				in_file.seek(8)
				f_offset = in_file.get_32()
				
				in_file.seek(f_offset - 8)
				name_tbl = in_file.get_32()
				name_tbl_size = in_file.get_32()
				if name_tbl == 0 or name_tbl_size == 0:
					print_rich("[color=red]Couldn't find name table in %s" % selected_files[file])
			
			for files in range(num_files - 1):
				in_file.seek((files * 8) + off_tbl)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				if name_tbl != 0 or name_tbl_size != 0:
					in_file.seek((files * 0x30) + name_tbl)
					f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(in_file, 0)[1], shift_jis_dic).get_string_from_utf8()
					f_ext = f_name.get_extension()
				else:
					f_name = "%04d" % files
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				if f_name.get_extension().to_lower() == "tm2":
					var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, true)
					for p in range(pngs.size()):
						var png: Image = pngs[p]
						png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" %  p)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
			
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		else:
			in_file = FileAccess.open(selected_files[file], FileAccess.READ)
			var bin_file: FileAccess = FileAccess.open(selected_files[file].get_basename() + ".BIN", FileAccess.READ)
			if !bin_file:
				OS.alert("Can't find header file %s to %s" % [selected_files[file].get_basename() + ".BIN", selected_files[file]])
				continue
			
			bin_file.seek(0)
			if bin_file.get_buffer(0xC).get_string_from_ascii() != "LSDARC V.100":
				OS.alert("Couldn't find header 'LSDARC V.100' in %s" % selected_files[file].get_basename() + ".BIN")
				continue
			
			bin_file.seek(0xC)
			num_files = bin_file.get_32()
			
			bin_file.seek(0x14)
			for i in range(num_files):
				f_offset = bin_file.get_32()
				f_size = bin_file.get_32()
				var next_f: int = bin_file.get_32()
				f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(bin_file, 0)[1], shift_jis_dic).get_string_from_utf8()
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				var buff_str: String = buff.slice(0, 3).get_string_from_ascii()
				if buff_str == "TIM": # TIM2
					f_name += ".TM2"
					var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, true)
					for p in range(pngs.size()):
						var png: Image = pngs[p]
						png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" %  p)
				elif buff_str == "SCR": # SCRx20
					f_name += ".SCR"
				elif buff_str == "LSD": # LSDx1A
					f_name += ".LSD"
					if out_comp:
						out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
					buff = decompress_lsd(buff)
					if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
						f_name += ".TM2"
						var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, true, false)
						for p in range(pngs.size()):
							var png: Image = pngs[p]
							png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" %  p)
					else:
						f_name += ".BIN"
				else:
					f_name += ".BIN"
					
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				buff.clear()
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				bin_file.seek(bin_file.get_position() + 4)
	
	print_rich("[color=green]Finished![/color]")


func decompress_lsd(data: PackedByteArray) -> PackedByteArray:
	var input_len: int = data.size()
	if input_len < 8:
		push_error("Input buffer too small to contain header.")
		return PackedByteArray()

	var uncompressed_size: int = data.decode_u32(6)
	
	var code = data[5]  # one of 0x57('W'), 0x48('H'), 0x52('R'), 0x44('D')
	var decompressed: PackedByteArray = []
	match code:
		0x57:  # 'W'
			# MIPS did: jal 0x0016aad0 with (a0=input+8, a1=output, a2=s0)
			push_error("TODO: 0x57. What game uses this?")
			return PackedByteArray()

		0x48:  # 'H'
			# MIPS did: jal 0x00169eb0 with (a0=input+8, a1=output, a2=s0)
			push_error("TODO: 0x48")
			return PackedByteArray()

		0x52:  # 'R'
			# MIPS did: jal 0x0016a520 with (a0=input+8, a1=output)
			decompressed = _decompress_R(data, PackedByteArray(), uncompressed_size)

		0x44:  # 'D'
			# MIPS did: jal 0x0016a840 with (a0=input+8, a1=output, a2=s0)
			push_error("TODO: 0x44. What game uses this?")
			return PackedByteArray()

		_:  # anything else → fail
			push_error("Unknown compression code: 0x%02X" % code)
			return PackedByteArray()
			
	return decompressed
	
	
func _decompress_R(input_buf: PackedByteArray, output_buf: PackedByteArray, required_size) -> PackedByteArray:
	var in_len = input_buf.size()
	var in_i = 12
	var out_i = 0
	
	output_buf.resize(required_size)
	
	while true:
		if in_i >= in_len:
			push_error("R‐decompress ran past end of input.")
			return PackedByteArray()

		var ctrl_byte = input_buf[in_i]
		
		var top_two = ctrl_byte & 0xC0
		var key = 0
		if top_two == 0xC0:
			key = ctrl_byte & 0xF0
		else:
			key = top_two
		
		match key:
			0xF0:
				return output_buf
			0xC0:
				if in_i + 1 >= in_len:
					push_error("R‐decompress: truncated extended‐copy length.")
					return PackedByteArray()
				var length_high = (ctrl_byte & 0x0F) << 8
				var length_low = input_buf[in_i + 1]
				var length = length_high + length_low
				
				var src_start = in_i + 2
				var src_end = src_start + length
				if src_end > in_len:
					push_error("R‐decompress: extended‐copy runs past input buffer.")
					return PackedByteArray()
				var dst_start = out_i
				var dst_end = dst_start + length
				if dst_end > required_size:
					push_error("R‐decompress: 0xC0 runs past output")
					break
				
				#for k in range(length):
					#output_buf[dst_start + k] = input_buf[src_start + k]
				for k in range(length):
					output_buf[dst_start + k] = 0
				
				out_i += length
				in_i += 2
				continue
			0x00:
				var run_len = ctrl_byte & 0x3F
				if run_len > 0:
					var dst_start0 = out_i
					var dst_end0 = out_i + run_len
					if dst_end0 > required_size:
						push_error("R‐decompress: 0x00 runs past output")
						break
					for k in range(run_len):
						output_buf[dst_start0 + k] = 0
					out_i += run_len
				in_i += 1
				continue
			0xE0:
				if in_i + 2 >= in_len:
					push_error("R‐decompress: truncated 0xE0 length_low.")
					return PackedByteArray()

				var high_nibble = (ctrl_byte & 0x0F) << 8
				var length_low  = input_buf[in_i + 1]
				var length      = high_nibble + length_low

				var fill_value  = input_buf[in_i + 2]

				if out_i + length > required_size:
					push_error("R‐decompress: 0xE0 runs past output")
					break
				for k in range(length):
					output_buf[out_i + k] = fill_value

				out_i += length
				in_i  +=  3
				continue
			0x80:
				var run_len = ctrl_byte & 0x3F
				if run_len > 0:
					if in_i + 1 >= in_len:
						push_error("R‐decompress: truncated 0x80 fill‐value.")
						return PackedByteArray()

					var fill_value = input_buf[in_i + 1]
					if out_i + run_len > required_size:
						push_error("R‐decompress: 0x80 runs past output")
						break
					for k in range(run_len):
						output_buf[out_i + k] = fill_value

					out_i += run_len
					in_i  += 2 
				else:
					in_i += 2
				continue
			0x40:
				var long_len = ctrl_byte & 0x3F
				var src4 = in_i + 1
				var src4_end = src4 + long_len
				if src4_end > in_len:
					push_error("R‐decompress: truncated long copy.")
					return PackedByteArray()
				var dst4 = out_i
				var dst4_end = dst4 + long_len
				if dst4_end > required_size:
					push_error("R‐decompress: 0x40 runs past output")
					break
				
				for k in range(long_len):
					output_buf[dst4 + k] = input_buf[src4 + k]
				
				out_i += long_len
				in_i = in_i + long_len + 1
				continue
			0xD0:
				if in_i + 2 >= in_len:
					push_error("R‐decompress: truncated 0xD0 parameters.") 
					return PackedByteArray()
				var length_high2 = (ctrl_byte & 0x0F) << 8
				var length_low2  = input_buf[in_i + 1]
				var length2      = length_high2 + length_low2

				var dst_start: int = in_i + 2

				if dst_start + length2 >= in_len:
					push_error("R-decompress: 0xD0 copy runs past input.")
					break
				for k in range(length2):
					output_buf[out_i + k] = input_buf[dst_start + k]

				out_i += length2
				in_i += length2 + 2
				continue
			_:
				push_error("R‐decompress: invalid control code 0x%02X at input[%d]" % [ctrl_byte, in_i])
				return PackedByteArray()
				
	push_error("Prematurely broke loop in _decompress_R")
	return output_buf
	
	
func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	out_comp = !out_comp
