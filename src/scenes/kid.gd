extends Control

@onready var file_load_afs: FileDialog = $FILELoadAFS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var debug_out: bool = false
var remove_alpha: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractAFS()
		selected_files.clear()
		chose_file = false
		chose_folder = false
	
	
func extractAFS() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var arc_size: int
	var num_files: int
	var off_tbl: int
	var name_tbl: int
	var name_tbl_size: int
	var f_offset: int
	var f_name: String
	var name_size: int
	var f_size: int
	var f_ext: String
	var ext: String
	var tga_header: PackedByteArray
	var tga_img: PackedByteArray
	var swap: PackedByteArray
	var width: int
	var height: int
	var bpp: int
	var pal: PackedByteArray
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		
		in_file.seek(4)
		num_files = in_file.get_32()
		
		off_tbl = 8
		
		in_file.seek((num_files * 8) + off_tbl)
		name_tbl = in_file.get_32()
		name_tbl_size = in_file.get_32()
		
		
		for files in range(num_files - 1):
			in_file.seek((files * 8) + off_tbl)
			
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			
			in_file.seek((files * 0x30) + name_tbl)
			f_name = in_file.get_line()
			f_ext = f_name.get_extension()
				
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			if f_ext == "KLZ":
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".COMP", FileAccess.WRITE)
					out_file.store_buffer(buff)
					
				buff = lzh_decode_mips(buff)
				
				var bytes: int = buff.decode_u32(0)
				if bytes == 0x324D4954: #TIM2
					#f_name += ".TM2"
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					
					# TIM2 search
					var color: String
					var search_results: PackedInt32Array
					var tm2_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.READ)
					
					var pos: int = 0
					var last_pos: int = 0
					var f_id: int = 0
					var entry_count: int = 0
					tm2_file.seek(pos)
					
					while tm2_file.get_position() < tm2_file.get_length():
						tm2_file.seek(pos)
						if tm2_file.eof_reached():
							break
							
						var tm2_bytes: int = tm2_file.get_32()
						last_pos = tm2_file.get_position()
						if tm2_bytes == 0x324D4954:
							search_results.append(last_pos - 4)
							
							tm2_file.seek(last_pos + 0xC) #TIM2 size at 0x10
							var tm2_size: int = tm2_file.get_32()
								
							tm2_file.seek(search_results[entry_count]) #Go back to TIM2 header
							var tm2_buff: PackedByteArray = tm2_file.get_buffer(tm2_size + 0x10)
							
							last_pos = tm2_file.get_position()
							if !last_pos % 16 == 0: #align to 0x10 boundary
								last_pos = (last_pos + 15) & ~15
								
							out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % entry_count + ".TM2", FileAccess.WRITE)
							out_file.store_buffer(tm2_buff)
							out_file.close()
							tm2_buff.clear()
							
							#print("0x%08X " % search_results[entry_count], "0x%08X " % tm2_size + "%s" % folder_path + "/%s" % f_name + "_%04d" % f_id + ".TM2")
							entry_count += 1
						else:
							if !last_pos % 16 == 0: #align to 0x10 boundary
								last_pos = (last_pos + 15) & ~15
								
						pos = last_pos
						f_id += 1
					
					if entry_count > 0:
						color = "green"
					else:
						color = "red"
						
					print_rich("[color=%s]Found %d TIM2 entries[/color]" % [color, search_results.size()])
					print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
					continue
				else:
					f_name += ".BIN"
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
	
	print_rich("[color=green]Finished![/color]")
	
	
func lzh_decode_mips(input: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray
	var f_out: PackedByteArray
	var output_size: int = ComFuncs.swap32(input.decode_u32(0))
	var fill_count: int = ComFuncs.swapNumber(input.decode_u16(4), "16")
	var at: int = 0
	var v0: int
	var v1: int
	var a0: int
	var s0: int = 0
	var s1: int = 0
	var s2: int = 0
	var s3: int = 0
	var OO40_sp: int = 0
	var OO42_sp: int = 0
	var OO44_sp: int
	var OO48_sp: int
	var OO50_sp: int = 0 #out buffer address
	var OO60_sp: int = 0
	var OO70_sp: int = fill_count
	var next_read_pos: int = 0
	var count: int = 0
	var num_passes: int = 0
	var decode_table: PackedByteArray = [
		0x01, 0x02, 0x04, 0x08,
		0x10, 0x20, 0x40, 0x80,
		# Only first 8 are used
		0x81, 0x75, 0x81, 0x69,
		0x00, 0x00, 0x00, 0x00,
		0x01, 0x02, 0x00, 0x00
	]
	
	out.resize(0x4000)
	if fill_count > 0x4000:
		next_read_pos = 4
		while OO70_sp > 0x4000:
			var cnt: int = 0
			var copy_off: int = next_read_pos + 2
			while cnt < 0x4000:
				f_out.append(input.decode_u8(copy_off))
				cnt += 1
				copy_off += 1
			count += 0x4000
			next_read_pos += cnt + 2
			num_passes += 1
			OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
			if count >= output_size or next_read_pos >= input.size():
				return f_out
			OO60_sp = next_read_pos + 2
	else:
		OO60_sp = 6
		
	OO44_sp = OO60_sp
	v0 = OO60_sp + 1
	OO48_sp = v0
	while true:
		v0 = input.decode_u8(OO44_sp)
		a0 = v0 & 0xFF
		v0 = OO40_sp
		v1 = v0 & 0xFF
		v0 = decode_table[v1] & 0xFF
		v0 &= a0
		# 001BA8AC
		if v0 == 0:
			v1 = input.decode_u8(OO48_sp)
			v0 = OO50_sp + s0
			out.encode_s8(v0, v1)
			OO48_sp += 1
			OO42_sp += 1
			s0 += 1
		elif v0 != 0:
			# 001BA8F0
			OO42_sp += 2
			v0 = input.decode_u8(OO48_sp) & 0xFF
			v1 = v0 << 8
			v0 = input.decode_u8(OO48_sp + 1) & 0xFF
			v0 = v1 | v0
			v0 &= 0xFFFF
			s2 = v0 & 0xFFFF
			v0 = s2 & 0xFFFF
			v0 &= 0x1F
			v0 += 2
			v0 &= 0xFFFF
			s3 = v0 & 0xFFFF
			v0 = s2 & 0xFFFF
			v0 >>= 5
			v0 &= 0xFFFF
			s1 = v0 & 0xFFFF
			v0 = s1 & 0xFFFF
			v0 = s0 - v0
			v0 -= 1
			v0 &= 0xFFFF
			s1 = v0 & 0xFFFF
			OO48_sp += 1
			v0 = 1
			while v0 != 0: 
				at = s0 < 0x0800
				# 001BA96C
				if at != 0:
					v0 = s1 & 0xFFFF
					at = s0 < v0
					if at != 0:
						v1 = out.decode_u8(OO50_sp)
						v0 = OO50_sp + s0
						out.encode_s8(v0, v1)
						s0 += 1
						v0 = s1 + 1
						s1 = v0 & 0xFFFF
						# 001BA9D8
						v1 = s3
						v0 = v1 - 1
						s3 = v0 & 0xFFFF
						v0 = v1 & 0xFFFF
						continue
				# 001BA9B0
				v1 = s1 & 0xFFFF
				v0 = OO50_sp
				v0 += v1
				v1 = out.decode_u8(v0)
				v0 = OO50_sp
				v0 += s0
				out.encode_s8(v0, v1)
				s0 += 1
				v0 = s1 + 1
				s1 = v0 & 0xFFFF
				# 001BA9D8
				v1 = s3
				v0 = v1 - 1
				s3 = v0 & 0xFFFF
				v0 = v1 & 0xFFFF
						
			OO48_sp += 1
		# 001BAA00
		OO40_sp += 1
		v1 = OO40_sp & 0xFF
		v0 = 8
		if v1 == v0:
			OO40_sp = 0
			OO44_sp = OO48_sp
			OO48_sp += 1
			OO42_sp += 1
		v0 = OO42_sp
		v1 = v0 & 0xFFFF
		v0 = OO70_sp
		v0 -= 1
		v0 = v1 < v0
		if v0 == 0:
			count += s0
			if count >= output_size or next_read_pos >= input.size():
				f_out.append_array(out)
				return f_out
			num_passes += 1
			if num_passes == 1:
				next_read_pos += OO70_sp + 6
			else:
				next_read_pos += OO70_sp + 2
				
			f_out.append_array(out)
			#out.fill(0)
			#print("%X, %X, %X, %X, Next read pos: %X" % [s0, s1, OO70_sp, count, next_read_pos])
			#print_rich("[color=yellow]Last pass: Num passes: %d, Addresses: %X, %X, %X, %X, %X, %X, %X[/color]" % [num_passes, OO40_sp, OO42_sp, OO44_sp, OO48_sp, OO50_sp, OO60_sp, OO70_sp])
			OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
			if OO70_sp > 0x4000:
				while OO70_sp > 0x4000:
					var cnt: int = 0
					var copy_off: int = next_read_pos + 2
					while cnt < 0x4000:
						f_out.append(input.decode_u8(copy_off))
						cnt += 1
						copy_off += 1
					count += 0x4000
					next_read_pos += cnt + 2
					OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
					if count >= output_size or next_read_pos >= input.size():
						return f_out
				
			s0 = 0
			s1 = 0
			OO50_sp = 0
			OO42_sp = 0
			OO48_sp = next_read_pos + 2
			if OO48_sp > input.size():
				return f_out
			OO40_sp = 0
			OO60_sp = OO48_sp
			OO44_sp = OO60_sp
			v0 = OO60_sp + 1
			OO48_sp = v0
			#print_rich("[color=orange]This pass: Addresses: %X, %X, %X, %X, %X, %X, %X, This read pos: %X[/color]" % [OO40_sp, OO42_sp, OO44_sp, OO48_sp, OO50_sp, OO60_sp, OO70_sp, next_read_pos + 2])
			
	return f_out


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_load_afs_pressed() -> void:
	file_load_afs.visible = true


func _on_file_load_afs_files_selected(paths: PackedStringArray) -> void:
	file_load_afs.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir
