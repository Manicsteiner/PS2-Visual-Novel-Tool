extends Control

@onready var file_load_bins: FileDialog = $FILELoadBINS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER


var chose_folder: bool = false
var folder_path: String
var selected_files: PackedStringArray
var decomp_file: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if selected_files and chose_folder:
		socioMakeFiles()
		chose_folder = false
		selected_files.clear()
	
	
func socioMakeFiles() -> void:
	var loaded_array_size: int
	var file_name: String
	var archive_id: String
	var archive_size: int
	var file: FileAccess
	var file_hed: FileAccess
	var out_file: FileAccess
	var mem_file: PackedByteArray
	var start_off: int
	var file_off: int
	var file_size: int
	var seek_hed: int
	var i: int
	var files: int
	
	# todo: images that have header magic "T" that appear mostly blank
	
	loaded_array_size = selected_files.size()
	start_off = 0
	seek_hed = 0
	i = 0
	files = 0
	while files < loaded_array_size:
		file = FileAccess.open(selected_files[files], FileAccess.READ)
		file_hed = FileAccess.open(selected_files[files].get_basename() + ".HD", FileAccess.READ)
		if !file_hed:
			OS.alert("Cannot find header file %s" % selected_files[files].get_basename() + ".HD")
			file.close()
			files += 1
			continue
			
		archive_id = selected_files[files].get_file()
		archive_size = file.get_length()
		while !file_hed.eof_reached():
			file_hed.seek(seek_hed)
			file_size = file_hed.get_32()
			if file_size == 0:
				i += 1
				seek_hed += 4
				continue
			# for debugging
			#if i != 295:
				#start_off = (((start_off + file_size) + 0x7FF) >> 11) * 0x800
				#i += 1
				#seek_hed += 4
				#continue
				
			mem_file.resize(file_size)
			
			file.seek(start_off)
			mem_file = file.get_buffer(file_size)
			
			if archive_id == "SOUND_ID.BIN" or archive_id == "VOICE_ID.BIN":
				if file_size == 0x14:
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08X" % i + ".PSH", FileAccess.WRITE)
				else:
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08X" % i + ".STV", FileAccess.WRITE)
					
			elif archive_id == "LIST.BIN" or archive_id == "SYSTEM.BIN":
				out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BIN", FileAccess.WRITE)
			elif archive_id == "SCRIPT.BIN":
				if mem_file.decode_u32(0) == 0x324D4954:
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".TM2", FileAccess.WRITE)
				else:
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BIN", FileAccess.WRITE)
			elif archive_id == "NORMAL.BIN" or archive_id == "SCENE_ID.BIN" or archive_id == "SCENEDAT.BIN":
				if Main.game_type == Main.CAMBRIAN and archive_id == "NORMAL.BIN": #Cambrian QTS check as these aren't compressed
					if mem_file.decode_u32(0) == 0x324D4954: #TIM2
						out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".TM2", FileAccess.WRITE)
					elif mem_file.decode_u32(0) == 0x4B434150: #PACK
						out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".PAK", FileAccess.WRITE)
					elif mem_file.decode_u32(0) == 0x43524146: #FARC
						out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".FAC", FileAccess.WRITE)
					elif mem_file.decode_u16(0) == 0x4D42: #BMP
						out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BMP", FileAccess.WRITE)
					else:
						out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BIN", FileAccess.WRITE)
				elif mem_file.decode_u32(9) == 0x324D4954: #TIM2
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".TM2", FileAccess.WRITE)
					if decomp_file:
						mem_file.resize(mem_file.decode_u32(0))
						mem_file = decompressFile(mem_file, mem_file.decode_u32(0), 8)
				elif mem_file.decode_u16(9) == 0x4D42: #BMP
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BMP", FileAccess.WRITE)
					if decomp_file:
						mem_file.resize(mem_file.decode_u32(0))
						mem_file = decompressFile(mem_file, mem_file.decode_u32(0), 8)
				elif mem_file.decode_u16(9) == 0x4D54: #TM split headers
					if decomp_file:
						mem_file.resize(mem_file.decode_u32(0))
						var dec_size: int = mem_file.decode_u32(0)
						var split_size: int = dec_size / 2
						mem_file = decompressFile(mem_file, dec_size, 8)
						
						print_rich("[color=green]Combined split TIM2 image in %s[/color]" % i)
						mem_file = combineSplitTIM2(mem_file, split_size)
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".TM2", FileAccess.WRITE)
				else:
					if decomp_file:
						mem_file.resize(mem_file.decode_u32(0))
						mem_file = decompressFile(mem_file, mem_file.decode_u32(0), 8)
					out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BIN", FileAccess.WRITE)
					
			else:
				out_file = FileAccess.open(folder_path + "/" + archive_id + "_%08d" % i + ".BIN", FileAccess.WRITE)
				
			out_file.store_buffer(mem_file)
			mem_file.clear()
			out_file.close()
			
			print("%08X " % start_off, "%08X " % file_size, "%s " % archive_id, "%s " % i)
			start_off = (((start_off + file_size) + 0x7FF) >> 11) * 0x800
			i += 1
			seek_hed += 4
		file.close()
		file_hed.close()
		files += 1
	print_rich("[color=green]Finished![/color]")
	
	
func combineSplitTIM2(data: PackedByteArray, part_size: int) -> PackedByteArray:
	var tm2_data: PackedByteArray
	
	for part in range(0, part_size):
		tm2_data.append(data.decode_u8(part))
		tm2_data.append(data.decode_u8(part + part_size))
		
	return tm2_data
	
	
func decompressFile(buffer: PackedByteArray, decompressed_size: int, off: int) -> PackedByteArray:
	var out_buffer: PackedByteArray
	var v0:int
	var v1:int
	var a0:int
	var a1:int
	var a2:int
	var a3:int
	var t0:int 
	var t1:int
	var t2:int
	var t3:int
	var t4:int
	var t5:int
	var t6:int
	var t7:int
	var t8:int
	var t9:int
	var width:int
	var height:int
	var unk:int
	var start_off:int
	var buff_size:int
	
	var off_01FFE790:int = 0x0023F898
	var off_01FFE794:int = 0x0023F8A0
	var off_01FFE798:int = 0x0023F8A8
	var off_01FFE79C:int = 0x0023F8B0
	var off_01FFE7A0:int = 0x0023F8B8
	var off_01FFE7A4:int = 0x0023F8C0
	
	var off_01FFE7A8:int = 0x01FFE790
	var off_01FFE7AC:int = 0x01FFE794
	var off_01FFE7B0:int = 0x01FFE798
	var off_01FFE7B4:int = 0x01FFE79C
	var off_01FFE7B8:int = 0x01FFE7A0
	var off_01FFE7BC:int = 0x01FFE7A4
	
	# Use caution while looking at this function. Your brain may bleed.
	#
	#
	#
	#a0 stack with special byte offsets
	#a1 file mem location + start at tim2 header with magic byte
	#a2 out mem location
	#a3 = out loc
	#t0 / t7 = comp/decomp size?
	buff_size = buffer.size()
	out_buffer.resize(decompressed_size)
	t0 = decompressed_size
	a0 = 0
	t7 = t0
	a1 = off
	v0 = a1
	a2 = 0
	a3 = 0
	t7 = a2 + t7
	a1 = t7 - 1
	if t0 == 0:
		return out_buffer
		
	t9 = -0x20 & 0xFFFFFFFF
	t8 = 0xC0
	t5 = buffer.decode_u8(v0)
	while t7 != 0:
		t7 = t5 & t9
		v1 = 0xE0
		#00100834
		if t7 == t8:
			#0010083C
			t2 = off_01FFE7B8
			t7 = t5 & 0x1F
			t4 = off_01FFE7BC
			t7 += 2
			t6 = off_01FFE7A0
			v1 = a3 + t7
			t3 = off_01FFE7B4
			t5 = a1 < v1
			off_01FFE7A4 = t6
			t7 = a1 + 1
			#00100864 movn     v1, t7, t5
			if t5 != 0:
				v1 = t7
			t6 = off_01FFE79C
			t1 = a3 < v1
			t4 = off_01FFE7B0
			off_01FFE7A0 = t6
			t5 = off_01FFE7AC
			t7 = off_01FFE798
			t2 = off_01FFE7A8
			off_01FFE79C = t7
			t6 = off_01FFE794
			off_01FFE798 = t6
			t7 = off_01FFE790
			off_01FFE794 = t7
			off_01FFE790 = v0
			v0 += 1
			t4 = buffer.decode_u8(v0)
			v0 += 1
			if t1 != 0:
				out_buffer.encode_s8(a3, t4)
				t7 = 1
				while t7 != 0:
					a3 += 1
					if a3 >= decompressed_size: #fail safe since it can go over for some reason
						return out_buffer
					t7 = a3 < v1
					out_buffer.encode_s8(a3, t4)
			t7 = a1 < a3
			if t7 == 0:
				t7 = a3 - a2
			else:
				return out_buffer
				
			t7 = t7 < t0
			if t7 == 0:
				return out_buffer
				
			if v0 >= buff_size: #fail safe since it can go over for some reason
				return out_buffer
				
			t5 = buffer.decode_u8(v0)
			continue
			
		
		#001008F8
		if t7 == v1:
			t7 >>= 5
			#00100900
			t2 = off_01FFE7B8
			t7 = t5 & 0x1F
			t5 = off_01FFE7BC
			t7 &= 0xFF
			#00100910 lw       t6, $0000(t2)
			t6 = off_01FFE7A0
			#00100914 dsll32   t7, t7, 0
			#0010091C dsra32   t7, t7, 0
			t7 &= 0xFFFFFFFF
			t3 = off_01FFE7B4
			off_01FFE7A4 = t6
			v1 = a3 + t7
			t7 = a1 < v1
			t4 = off_01FFE7B0
			t6 = off_01FFE79C
			#00100934 movn     v1, a1, t7
			if t7 != 0:
				v1 = a1
			t5 = off_01FFE7AC
			t1 = v1 < a3
			off_01FFE7A0 = t6
			t7 = off_01FFE798
			t2 = off_01FFE7A8
			off_01FFE79C = t7
			t6 = off_01FFE794
			off_01FFE798 = t6
			t7 = off_01FFE790
			off_01FFE794 = t7
			off_01FFE790 = v0
			v0 += 1
			#00100964
			if t1 == 0:
				t7 = 0
				while t7 == 0:
					t7 = buffer.decode_u8(v0)
					out_buffer.encode_s8(a3, t7)
					a3 += 1
					t7 = v1 < a3
					v0 += 1
					if v0 >= buff_size:
						return out_buffer
			t7 = a1 < a3
			if t7 != 0:
				return out_buffer
				
			t7 = a3 - a2
			t7 = t7 < t0
			if t7 == 0:
				return out_buffer
				
			t5 = buffer.decode_u8(v0)
			continue
			
		t7 >>= 5
		#001009A0
		t1 = t5 & 0x1F
		t4 = t7 & 0xFF
		t6 = t4 & 0xFFFFFFFF #001009A8 dsll32   t6, t4, 0
		t7 = t4 < 0x5
		t6 <<= 2
		t6 += a0
		if t6 == 0:
			t3 = off_01FFE790
		elif t6 == 0x4:
			t3 = off_01FFE794
		elif t6 == 0x8:
			t3 = off_01FFE798
		elif t6 == 0xC:
			t3 = off_01FFE79C
		elif t6 == 0x10:
			t3 = off_01FFE7A0
		elif t6 == 0x14:
			t3 = off_01FFE7A4
		elif t6 == 0x18:
			t3 = off_01FFE7A8
		elif t6 == 0x1C:
			t3 = off_01FFE7AC
		elif t6 == 0x20:
			t3 = off_01FFE7B0
		elif t6 == 0x24:
			t3 = off_01FFE7B4
		elif t6 == 0x28:
			t3 = off_01FFE7B8
		elif t6 == 0x2C:
			t3 = off_01FFE7BC
		
		
		if t7 == 0:
			t7 = off_01FFE7B8
			t5 = off_01FFE7BC
			t6 = off_01FFE7A0
			#t6 = getSpecialBytes(t7) #001009CC lw       t6, $0000(t7)
			off_01FFE7A4 = t6
		t7 = t4 < 0x4
		if t7 == 0:
			t7 = off_01FFE7B4
			t5 = off_01FFE7B8
			t6 = off_01FFE79C
			#t6 = getSpecialBytes(t7)
			off_01FFE7A0 = t6
		t7 = t4 < 0x3
		if t7 == 0:
			t7 = off_01FFE7B0
			t5 = off_01FFE7B4
			t6 = off_01FFE798
			#t6 = getSpecialBytes(t7)
			off_01FFE79C = t6
		t7 = t4 < 0x2
		if t7 == 0:
			t7 = off_01FFE7AC
			t5 = off_01FFE7B0
			t6 = off_01FFE794
			#t6 = getSpecialBytes(t7)
			off_01FFE798 = t6
		t2 = off_01FFE7A8
		if t4 > 0:
			t6 = off_01FFE7AC
			t7 = off_01FFE790
			#t7 = getSpecialBytes(t2)
			off_01FFE794 = t7
			
		off_01FFE790 = t3
		if t3 in range(0x0023F898, 0x0023F8C8):
			t7 = getSpecialBytes(t3)
			t7 = t9 & t7
			t3 += 1
			if t7 == t8:
				t7 = t1 + 2
				v1 = a3 + t7
				t5 = a1 + 1
				t7 = a1 < v1
				#00100A60 movn     v1, t5, t7
				if t7 != 0:
					v1 = t5
				t6 = a3 < v1
				t4 = getSpecialBytes(t3)
				if t6 != 0:
					out_buffer.encode_s8(a3, t4)
					t7 = 1
					while t7 != 0:
						a3 += 1
						if a3 >= decompressed_size: #fail safe since it can go over for some reason
							return out_buffer
						t7 = a3 < v1
						out_buffer.encode_s8(a3, t4)
				#00100A90
				t7 = a1 < a3
				v0 += 1
				if t7 != 0:
					return out_buffer
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
				
			#00100AA4
			#not going here but should be correct
			if t7 != v1:
				v0 += 1
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
			
			t7 = t1 >> 2
			t5 = a1 + 1
			t1 &= 3
			t3 += t7
			v1 = a3 + t1
			t7 = a1 < v1
			#00100AC4 movn     v1, t5, t7
			if t7 != 0:
				v1 = t5
			t6 = v1 < a3
			t7 = a1 < a3
			if t6 != 0:
				v0 += 1
				if t7 == 0:
					return out_buffer
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
				
			while t7 != 0:
				if t3 in range(0x0023F898, 0x0023F8C7):
					t7 = getSpecialBytes(t3)
				else:
					t7 = buffer.decode_u8(t3)
				out_buffer.encode_s8(a3, t7)
				a3 += 1
				t7 = v1 < a3
				t3 += 1
			t7 = a1 < a3
			v0 += 1
			if t7 != 0:
				return out_buffer
			t7 = a3 - a2
			t7 = t7 < t0
			if t7 == 0:
				return out_buffer
			t5 = buffer.decode_u8(v0)
			continue
			
		#not special bytes
		else:
			t7 = buffer.decode_u8(t3)
			t7 = t9 & t7
			t3 += 1
			if t7 == t8:
				t7 = t1 + 2
				v1 = a3 + t7
				t5 = a1 + 1
				t7 = a1 < v1
				#00100A60 movn     v1, t5, t7
				if t7 != 0:
					v1 = t5
				t6 = a3 < v1
				t4 = buffer.decode_u8(t3)
				if t6 != 0:
					out_buffer.encode_s8(a3, t4)
					t7 = 1
					while t7 != 0:
						a3 += 1
						if a3 >= decompressed_size: #fail safe since it can go over for some reason
							return out_buffer
						t7 = a3 < v1
						out_buffer.encode_s8(a3, t4)
				#00100A90
				t7 = a1 < a3
				v0 += 1
				if v0 >= buff_size: #fail safe since it can go over for some reason
					return out_buffer
				if t7 != 0:
					return out_buffer
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
				
			#00100AA4
			if t7 != v1:
				v0 += 1
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
			
			t7 = t1 >> 2
			t5 = a1 + 1
			t1 &= 3
			t3 += t7
			v1 = a3 + t1
			t7 = a1 < v1
			#00100AC4 movn     v1, t5, t7
			if t7 != 0:
				v1 = t5
			t6 = v1 < a3
			t7 = a1 < a3
			if t6 != 0:
				v0 += 1
				if t7 == 0:
					return out_buffer
				t7 = a3 - a2
				t7 = t7 < t0
				if t7 == 0:
					return out_buffer
				t5 = buffer.decode_u8(v0)
				continue
				
			t7 = 0
			while t7 == 0:
				#if t3 in range(0x0023F898, 0x0023F8C7):
					#t7 = getSpecialBytes(t3)
				#else:
					#t7 = buffer.decode_u8(t3)
				t7 = buffer.decode_u8(t3)
				out_buffer.encode_s8(a3, t7)
				a3 += 1
				t7 = v1 < a3
				t3 += 1
				if a3 >= decompressed_size: #fail safe since it can go over for some reason
					return out_buffer
				if t3 >= buff_size: #fail safe since it can go over for some reason
					return out_buffer
					
			t7 = a1 < a3
			v0 += 1
			if v0 >= buff_size: #fail safe since it can go over for some reason
				return out_buffer
			if t7 != 0:
				return out_buffer
			t7 = a3 - a2
			t7 = t7 < t0
			if t7 == 0:
				return out_buffer
			t5 = buffer.decode_u8(v0)
			continue
			
	return out_buffer



func getSpecialBytes(num: int) -> int:
	# Define mappings for decompression variables
	var specific_values: Dictionary = {
		0x0023F898: 0xDF,
		0x0023F8A0: 0xDF,
		0x0023F8A1: 1,
		0x0023F8A8: 0xDF,
		0x0023F8A9: 0xFF,
		0x0023F8B0: 0xDF,
		0x0023F8B1: 0x80,
		0x0023F8B8: 0xDF,
		0x0023F8B9: 0x7F,
		0x0023F8C0: 0xDF,
		0x0023F8C1: 0xFE
	}

	# Define ranges that map to 0
	var zero_ranges: Array = [
		[0x0023F899, 0x0023F89C],
		[0x0023F89E, 0x0023F89F],
		[0x0023F8A2, 0x0023F8A7],
		[0x0023F8AA, 0x0023F8AF],
		[0x0023F8B2, 0x0023F8B7],
		[0x0023F8BA, 0x0023F8BF],
		[0x0023F8C2, 0x0023F8C7]
	]

	# Check for specific values
	if num in specific_values:
		return specific_values[num]

	# Check for ranges mapping to 0
	for range_pair in zero_ranges:
		if num >= range_pair[0] and num <= range_pair[1]:
			return 0

	# Default case
	return num


func _on_load_bin_pressed() -> void:
	file_load_bins.visible = true


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_bins.visible = false
	file_load_folder.visible = true


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
