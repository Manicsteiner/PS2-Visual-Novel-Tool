extends Control

var folder_path: String = ""
var selected_files: PackedStringArray = []

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

#TODO: VOICESCR.NOA files. Compression is different?

func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		
		
func extract_arc() -> void:
	for file in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		if in_file.get_buffer(4).get_string_from_ascii() != "NOAH":
			OS.alert("%s is not a valid NOAH archive." % selected_files[file])
			continue
			
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		in_file.seek(0x10)
		var start_off: int = in_file.get_32()
		in_file.seek(0x18)
		var num_files: int = in_file.get_32()
		in_file.seek(0x30)
		var f_tbl: int = in_file.get_32()
		in_file.seek(0x50)
		var name_tbl: int = in_file.get_32()
		for tbl_pos in range(0, num_files):
			in_file.seek((tbl_pos * 0x18) + f_tbl)
			var f_offset: int = in_file.get_32() + start_off
			var null_32: int = in_file.get_32()
			var f_size: int = in_file.get_32()
			null_32 = in_file.get_32()
			var f_name_off: int = in_file.get_32()
			
			in_file.seek(f_name_off)
			var f_name: String = in_file.get_line()
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			in_file.seek(f_offset)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			if f_name.ends_with(".BMP") or f_name.ends_with(".CMP"):
				if buff.decode_u16(0) != 0x4D42:
					f_size = ComFuncs.swap32(buff.decode_u32(4))
					buff = fushigiDecompLZ(buff, f_size)
			elif f_name.ends_with(".G2D"):
				if buff.decode_u32(0x18) != 0:
					push_error("output may be wrong in %s" % f_name)
				var temp_files: int = buff.decode_u32(8)
				for i in range(temp_files):
					var t_pos: int = (i * 4) + 0x10
					var t_off: int = buff.decode_u32(t_pos)
					var t_size: int = buff.decode_u32(t_pos + 4)
					if i == 0:
						t_off += 4
					if t_size == 0:
						t_size = buff.decode_u32(t_off + 0xC)
					var t_buff: PackedByteArray = buff.slice(t_off, t_size)
					if i >= 1:
						t_buff = t_buff.slice(0x24)
					t_buff = fushigiDecompLZ(t_buff, ComFuncs.swap32(t_buff.decode_u32(4)))
					
					var t_name: String = f_name + "%02d.BMP" % i
					
					var dir: DirAccess = DirAccess.open(folder_path)
					dir.make_dir_recursive(folder_path + "/" + arc_name)
						
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % t_name, FileAccess.WRITE)
					out_file.store_buffer(t_buff)
					out_file.close()
					
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + arc_name)
				
			var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
	print_rich("[color=green]Finished![/color]")
	
	
func fushigiDecompLZ(file:PackedByteArray, decomp_size:int) -> PackedByteArray:
	# This is horrible old code, but it works
	const com_types:PackedByteArray = [
	0x0C, 0x03, 0x0B, 0x03, 0x0A, 0x03, 0x09, 0x03,
	0x06, 0x03, 0x05, 0x03, 0x00, 0x00, 0x00, 0x00,
	0x06, 0x02, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00,
	0x08, 0x04, 0x07, 0x04, 0x00, 0x00, 0x00, 0x00,
	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01,
	0xF0, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	]
	var v0:int
	var v1:int
	var a0:int
	var a1:int
	var a2:int
	var a3:int
	var t0:int #stack offset
	var t1:int
	var t4:int #file size
	var t2:int
	var t3:int
	var t5:int
	var t6:int
	var t7:int
	var s6:int
	var temp_i:int
	var temp_i_2:int
	var loop_1_i:int
	var loop_2_i:int
	var do_loop:bool = true
	var new_arrary:PackedByteArray
	var new_file:PackedByteArray
	var comp_size:int
	var magic_byte_1:int
	var magic_byte_2:int
	var magic_byte_3:int
	
	temp_i = 0
	temp_i_2 = 0
	loop_1_i = 1
	loop_2_i = 1
	s6 = 0
	magic_byte_1 = file.decode_u8(0)
	magic_byte_2 = com_types[(magic_byte_1 << 1) + 1]
	magic_byte_1 = com_types[magic_byte_1 << 1]
	magic_byte_3 = (1 << magic_byte_1) - 1
	comp_size = file.size()
	new_arrary = file.slice(0x8)
	t0 = 0 #stack offset
	t4 = decomp_size #size
	new_file.resize(t4)
	t1 = 0
	t5 = 0
	a0 = decomp_size #size
	if a0 <= t1:
		return file
			
	t4 = t4 + t1
	t3 = 0
	t7 = t0 + 0x14
	t6 = t0 + 0x1C
	t3 >>= 1
	t2 = t0 + 0x14
	v0 = 0
	while s6 < decomp_size:
		s6 += 1
		loop_1_i = 1
		loop_2_i = 1
		while do_loop:
			if t3 == 0:
				v0 = t4 < t1
				if v0 != 0:
					do_loop = false
					s6 = decomp_size
					break
					
				v0 = a0 < t1
				t2 = t7 #t2 = temp_loc
				v1 = 0 #loaded file loc lw       v1, $0010(t0)
				v0 = temp_i #lw       v0, $0000(t2)
				t3 = 0x80
				v1 = v1 + v0
				if v1 >= comp_size - 8:
					do_loop = false
					s6 = decomp_size
					break
				v0 += 1
				t5 = new_arrary.decode_u8(v1)
				temp_i = v0
				
			v0 = t3 & t5 #001A037C
			if v0 != 0:
				a1 = temp_i
				v1 = 0 #loaded file loc
				a0 = temp_i_2
				if a1 >= comp_size - 8:
					do_loop = false
					s6 = decomp_size
					break
				v0 = 0 #new file lw       v0, $0018(t0)
				v1 = v1 + a1
				a2 = new_arrary.decode_u8(v1)
				a1 += 1
				v0 += a0
				a0 += 1
				new_file.encode_s8(v0, a2)
				temp_i = a1
				temp_i_2 = a0
				t1 = temp_i_2
				a0 = decomp_size
				v0 = t1 < a0
				t3 >>= 1
				if v0 != 0:
					break
			
			v1 = temp_i
			v0 = 0 #loaded file loc
			v0 = v0 + v1
			if v0 >= comp_size - 8:
				do_loop = false
				s6 = decomp_size
				break
			v1 += 1
			a1 = new_arrary.decode_u8(v0)
			a2 = v1 + 1
			temp_i = v1
			a1 <<= 8
			v0 = 0
			v0 = v0 + v1
			if v0 >= comp_size - 8:
				do_loop = false
				s6 = decomp_size
				break
			a0 = new_arrary.decode_u8(v0)
			temp_i = a2
			a0 |= a1
			v0 = magic_byte_1
			v1 = magic_byte_3
			t1 = temp_i_2
			v0 = a0 >> v0
			v1 &= a0
			a1 = magic_byte_2
			v0 &= 0xFFFF
			a3 = t1 - v1
			a2 = v0 + a1
			a0 = decomp_size
			if a3 <= 0:
				if a2 >= 0:
					a0 = t0 + 0x1C
					v1 = temp_i_2
				else:
					a0 = decomp_size
					v0 = t1 < a0
					t3 >>= 1
					break
					
				while loop_1_i > 0:
					a3 += 1
					v0 = 0 #001A0434 newfile offset
					a2 -= 1
					loop_1_i = a2
					v0 += v1
					v1 += 1
					new_file.encode_s8(v0, 0)
					temp_i_2 = v1
					if a3 >= 0:
						break
						
				t1 = temp_i_2
				if a2 >= 1: #blezl    a2, $001A0498
					t1 = t0 + 0x1C
					while loop_2_i > 0:
						a0 = 0 #newfile
						a2 -= 1
						v0 = temp_i_2
						v1 = a0 + a3
						a3 += 1
						a1 = new_file.decode_u8(v1)
						a0 += v0
						v0 += 1
						new_file.encode_s8(a0, a1)
						temp_i_2 = v0
						loop_2_i = a2
					#t1 = temp_i
			else:
				if a2 >= 0:
					t1 = t0 + 0x1C
					loop_2_i = a2
					while loop_2_i > 0:
						a0 = 0 #newfile
						a2 -= 1
						v0 = temp_i_2
						v1 = a0 + a3
						if v1 >= decomp_size:
							do_loop = false
							s6 = decomp_size
							break
						a3 += 1
						a1 = new_file.decode_u8(v1)
						a0 += v0
						v0 += 1
						new_file.encode_s8(a0, a1)
						temp_i_2 = v0
						loop_2_i = a2
					t1 = temp_i_2
					
			a0 = decomp_size
			v0 = t1 < a0
			t3 >>= 1
			if v0 == 0:
				do_loop = false
				s6 = decomp_size
				t3 >>= 1
				break
	return new_file
	
	
func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
