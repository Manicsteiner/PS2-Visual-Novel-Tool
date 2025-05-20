extends Control

var folder_path: String
var selected_files: PackedStringArray
var debug_brute_force_names: bool = false
#var export_hashed_names: bool = false

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var hash_tbl: Dictionary = {
	0x365F1789B10F0002: "/ads/bgm_magic00.ads",
	0x265F1789B10F0002: "/ads/bgm_magic01.ads",
	0x165F1789B10F0002: "/ads/bgm_magic02.ads",
	0x65F1789B10F0002: "/ads/bgm_magic03.ads",
	0x765F1789B10F0002: "/ads/bgm_magic04.ads",
	0x665F1789B10F0002: "/ads/bgm_magic05.ads",
	0x565F1789B10F0002: "/ads/bgm_magic06.ads",
	0x465F1789B10F0002: "/ads/bgm_magic07.ads",
	-0x49A0E8764EF0FFFE: "/ads/bgm_magic08.ads",
	-0x59A0E8764EF0FFFE: "/ads/bgm_magic09.ads",
	0x375F1789B10F0002: "/ads/bgm_magic10.ads",
	0x275F1789B10F0002: "/ads/bgm_magic11.ads",
	0x175F1789B10F0002: "/ads/bgm_magic12.ads",
	0x75F1789B10F0002: "/ads/bgm_magic13.ads",
	0x775F1789B10F0002: "/ads/bgm_magic14.ads",
	0x675F1789B10F0002: "/ads/bgm_magic15.ads",
	0x575F1789B10F0002: "/ads/bgm_magic16.ads",
	0x475F1789B10F0002: "/ads/bgm_magic17.ads",
	-0x48A0E8764EF0FFFE: "/ads/bgm_magic18.ads",
	-0x58A0E8764EF0FFFE: "/ads/bgm_magic19.ads",
	0x345F1789B10F0002: "/ads/bgm_magic20.ads",
	0x245F1789B10F0002: "/ads/bgm_magic21.ads",
	0x145F1789B10F0002: "/ads/bgm_magic22.ads",
	0x45F1789B10F0002: "/ads/bgm_magic23.ads",
	0x745F1789B10F0002: "/ads/bgm_magic24.ads",
	0x645F1789B10F0002: "/ads/bgm_magic25.ads",
	0x545F1789B10F0002: "/ads/bgm_magic26.ads",
	0x445F1789B10F0002: "/ads/bgm_magic27.ads",
	-0x4BA0E8764EF0FFFE: "/ads/bgm_magic28.ads",
	-0x5BA0E8764EF0FFFE: "/ads/bgm_magic29.ads",
	0x355F1789B10F0002: "/ads/bgm_magic30.ads",
	0x255F1789B10F0002: "/ads/bgm_magic31.ads",
	0x155F1789B10F0002: "/ads/bgm_magic32.ads",
	0x55F1789B10F0002: "/ads/bgm_magic33.ads",
	0x755F1789B10F0002: "/ads/bgm_magic34.ads",
	0x655F1789B10F0002: "/ads/bgm_magic35.ads",
	0x555F1789B10F0002: "/ads/bgm_magic36.ads",
	0x455F1789B10F0002: "/ads/bgm_magic37.ads",
	-0x4AA0E8764EF0FFFE: "/ads/bgm_magic38.ads",
	-0x5AA0E8764EF0FFFE: "/ads/bgm_magic39.ads",
	-0x2D9A0E876C07D8E4: "/ads/me_magic01.ads",
	-0x2E9A0E876C07D8E4: "/ads/me_magic02.ads",
	-0x2F9A0E876C07D8E4: "/ads/me_magic03.ads",
	-0x289A0E876C07D8E4: "/ads/me_magic04.ads",
	-0x299A0E876C07D8E4: "/ads/me_magic05.ads",
	-0x2A9A0E876C07D8E4: "/ads/me_magic06.ads",
	-0x2B9A0E876C07D8E4: "/ads/me_magic07.ads",
	-0x249A0E876C07D8E4: "/ads/me_magic08.ads",
	-0x259A0E876C07D8E4: "/ads/me_magic09.ads",
	-0x2C8A0E876C07D8E4: "/ads/me_magic10.ads",
	0x5D14A3434182892F: "/font/sce20i22.gf",
	0x5D54A7434182892F: "/font/sce24i26.gf",
	-0xF28A4E87B7D76D9: "/font/fn12x24.bin",
	-0xF28A4A87B7D76D9: "/font/fn16x24.bin",
	-0xF28A48B7B7D76D9: "/font/fn24x24.bin",
	-0xF2AA4AB7B7D76D9: "/font/fn26x26.bin",
	-0xF2CA4CB7B7D76D9: "/font/fn20x20.bin",
	0x928939F76828FC0: "/font/dai_font.bin",
	-0xF2A8C60897D76D9: "/font/dai_f16.bin",
	-0xF2E8C60897D76D9: "/font/dai_f12.bin",
	0x5D34A3434182892F: "/font/sce20i20.gf",
	0x5D34A1434182892F: "/font/sce22i20.gf",
	0x5D14A1434182892F: "/font/sce22i22.gf",
	0x5D74A7434182892F: "/font/sce24i24.gf",
	0x2D333709F93E0EBB: "/movie/mov0000.pss",
	0x2D233709F93E0EBB: "/movie/mov0001.pss",
	0x2D133709F93E0EBB: "/movie/mov0002.pss",
	0x2D033709F93E0EBB: "/movie/mov0003.pss",
	0x2D733709F93E0EBB: "/movie/mov0004.pss",
	0x2D633709F93E0EBB: "/movie/mov0005.pss",
	0x2D533709F93E0EBB: "/movie/mov0006.pss",
	0x2D433709F93E0EBB: "/movie/mov0007.pss",
	0x2DB33709F93E0EBB: "/movie/mov0008.pss",
	0x2DA33709F93E0EBB: "/movie/mov0009.pss",
	0x2D323709F93E0EBB: "/movie/mov0010.pss",
	-0x7C4D1E5B26CA7294: "/voice/OP_title.ads",
	0x8743B2E693B28E0: "/title/title2d.bin",
	0x593551118231B12C: "/status/StFace_0001.ag",
	0x593551118231B22C: "/status/StFace_0002.ag",
	0x593551118231B32C: "/status/StFace_0003.ag",
	0x593551118231B42C: "/status/StFace_0004.ag",
	0x593551118231B62C: "/status/StFace_0006.ag",
	0x593551118231B72C: "/status/StFace_0007.ag",
	0x593551118231B10C: "/status/StFace_0021.ag",
	0x593551118231B92C: "/status/StFace_0009.ag",
	0x593551118231B20C: "/status/StFace_0022.ag",
	0x593551118231B01C: "/status/StFace_0030.ag",
	0x593551118231B51C: "/status/StFace_0035.ag",
	0x593551118231B06C: "/status/StFace_0040.ag",
	0x593551118231B56C: "/status/StFace_0045.ag",
	0x593551118231B07C: "/status/StFace_0050.ag",
	0x593551118231B57C: "/status/StFace_0055.ag",
	0x593551118231B04C: "/status/StFace_0060.ag",
	0x593551118231B54C: "/status/StFace_0065.ag",
	0x593551118231B05C: "/status/StFace_0070.ag",
	0x593551118231B55C: "/status/StFace_0075.ag",
	0x593551118231B0AC: "/status/StFace_0080.ag",
	0x593551118231B5AC: "/status/StFace_0085.ag",
	0x593551118231B0BC: "/status/StFace_0090.ag",
	0x593551118231B5BC: "/status/StFace_0095.ag",
	0x593551118231B02D: "/status/StFace_0100.ag",
}

#func _ready() -> void:
	#print("%04X" % custom_hash_amagami("epi/e1_01a0.tm2", 0x256))
	
	#var in_file: FileAccess = FileAccess.open("G:/SLPS_257.75", FileAccess.READ)
	#var entry: int = 0xFFF80
	#var bgm_tbl: int = 0x002259A0 - entry
	#var bg_tbl: int = 0x00270560 - entry
	#var mov_tbl: int = 0x0021F4E0 - entry
	#var fac_tbl: int = 0x0022EA64 - entry
	#var tbl: int = fac_tbl
	#var off: int = 0
	##print("%08X" % custom_hash_magician("/status/StFace_0100.ag"))
	#while true:
		#in_file.seek(tbl)
		#off = in_file.get_32()
		#if off == 0x001C01D3 or off > 0x00400000:
			#break
		#if off == 0:
			#tbl += 0x4
			#continue
		#off -= entry
		#in_file.seek(off)
		#var txt: String = in_file.get_line()
		#var hash: int = custom_hash_magician(txt)
		#print("%08X %s" % [hash, txt])
		#tbl += 0x4
		
		
	#in_file.seek(0xF150)
	#print("%X" % in_file.get_64())
	#var hash: int = make_hash("/option/option2d.bin")
	#print("%X" % hash)

func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		
		
func extract_arc() -> void:
	var f_name: String
	var f_start: int
	var f_offset: int
	var f_size: int
	var f_tbl: int
	var raw_tbl: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	
	if selected_files[0].get_file().get_extension().to_lower() == "hb":
		#TODO: Some sort of decryption in function 0x001A1E70 for scripts only?
		
		in_file = FileAccess.open(selected_files[0], FileAccess.READ)
		var tbl_file = FileAccess.open(selected_files[0].get_basename() + ".HT", FileAccess.READ)
		if tbl_file == null:
			OS.alert("Could not find %s for %s!" % [selected_files[0].get_basename() + ".HT", selected_files[0].get_file()])
			return
		
		var tbl_size: int = tbl_file.get_length()
		var pos: int = 0x20
		var f_id: int = 0
		while true:
			tbl_file.seek(pos)
			if tbl_file.get_position() >= tbl_size:
				break
			
			var f_hash: int = tbl_file.get_64()
			f_offset = tbl_file.get_32() * 0x800
			f_size = tbl_file.get_32()
			
			for key in hash_tbl.keys():
				if key == f_hash:
					f_name = hash_tbl[key]
					break
				else:
					f_name = "%04d.BIN" % f_id
				
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			print("%08X %08X %08X %s/%s" % [f_hash, f_offset, f_size, folder_path, f_name])
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + f_name.get_base_dir())
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			pos += 0x10
			f_id += 1
	else:
		#TODO: A better brute force method for names.
		for file in range(selected_files.size()):
			in_file = FileAccess.open(selected_files[file], FileAccess.READ)
			var arc_name: String = selected_files[file].get_file().to_lower()
			var unk_name_cnt: int = 0
			
			raw_tbl = in_file.get_32()
			f_tbl = (raw_tbl << 2) + 8
			f_start = in_file.get_32()
			for tbl_off in range(f_tbl, f_start, 16):
				in_file.seek(tbl_off)
				var unk: int = in_file.get_32()
				var f_name_hash: int = in_file.get_32()
				#print("%04X" % f_name_hash)
				#if f_name_hash != 0x508AB4A5:
					#continue
				if debug_brute_force_names:
					f_name = brute_force_hash(f_name_hash, arc_name, raw_tbl)
				else:
					f_name = "%04d" % unk_name_cnt
					unk_name_cnt += 1
					
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				if f_name == "":
					f_name = "%04d.BIN" % unk_name_cnt
					unk_name_cnt += 1
				
				print("%08X %08X %08X %08X %s/%s" % [f_offset, f_size, unk, f_name_hash, folder_path, f_name])
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					f_name += ".TM2"
				else:
					f_name += ".BIN"
				
				#var dir: DirAccess = DirAccess.open(folder_path)
				#dir.make_dir_recursive(folder_path + "/" + f_name.get_base_dir())
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			
	print_rich("[color=green]Finished![/color]")
	
	
func custom_hash_magician(str: String, hash_const: int = 0x4E) -> int:
	var at: int
	var v0: int
	var v1: int
	var a0_buff: PackedByteArray = str.to_ascii_buffer()
	var a0: int = 0
	var a1_buff: PackedByteArray
	var a1: int = 0
	var a2: int
	var a3: int
	var t0: int = 0
	var t1: int = hash_const # From 0x14 in .HT header
	var t2: int
	var t3: int
	var t4: int
	var t5: int
	var t6: int
	var t7: int
	
	a0_buff.append(0) # add padding to end of string
	a1_buff.resize(8)
	v1 = t1 >> 4
	a2 = v1 & 0xF
	a3 = t1 & 0xF
	v1 = t1 >> 8
	v1 &= 0xF
	t1 = a0_buff.decode_s8(0)
	if !t1:
		return 0
		
	var label: String = "0015843C"
	while true:
		match label:
			"0015843C":
				t1 = 0
				label = "001584D0"
			"00158448":
				t3 = t2 << 56
				t3 = t3 >> 56
				t2 = t0 & 7
				if t0 >= 0:
					label = "00158464"
				else:
					if t2 == 0:
						t2 = t3 << t2
						label = "00158468"
					else:
						t2 -= 8
						label = "00158464"
			"00158464":
				t2 = t3 << t2
				label = "00158468"
			"00158468":
				t3 = t0 >> 3
				t4 = t2 & 0xFFFF
				if t0 >= 0:
					label = "0015847C"
				else:
					t2 = t0 + 7
					t3 = t2 >> 3
					label = "0015847C"
			"0015847C":
				t6 = a1 + t3
				t7 = t4 & 0xFF
				t5 = a1_buff.decode_u8(t6)
				t2 = t4 >> 8
				t4 = t2 & 0xFF
				t3 += 1
				t2 = t3 & 0x7
				t5 = t5 ^ t7
				a1_buff.encode_s8(t6, t5)
				if t3 >= 0:
					label = "001584B0"
				else:
					if t2 == 0:
						t3 = a1 + t2
						label = "001584B4"
					else:
						t2 -= 8
						label = "001584B0"
			"001584B0":
				t3 = a1 + t2
				label = "001584B4"
			"001584B4":
				t0 += a2
				t2 = a1_buff.decode_u8(t3)
				t0 &= 0x3F
				t1 += 1
				a0 += 1
				t2 = t2 ^ t4
				a1_buff.encode_s8(t3, t2)
				label = "001584D0"
			"001584D0":
				at = t1 < a3
				if at == 0:
					label = "001584E8"
				else:
					t2 = a0_buff.decode_s8(a0)
					if t2 != 0:
						label = "00158448"
					else:
						label = "001584E8"
			"001584E8":
				t1 = a0_buff.decode_s8(a0)
				if t1 == 0:
					break
				else: 
					t0 += v1
					if t1 != 0:
						label = "0015843C"
						t0 &= 0x3F
					else: 
						break
	return a1_buff.decode_u64(0)
	
	
func custom_hash_amagami(input_string: String, file_info_offset) -> int:
	var hash_value: int = 0
	var multiplier: int = 0x3FAD
	var chars: PackedByteArray = input_string.to_ascii_buffer()
	var length: int = chars.size()
	var i: int = 0
	var t6: int = chars[i]
	
	if length == 0:
		return 0
	
	i += 1
	while i < length:
		var t3: int = chars[i]
		i += 1
		hash_value = (t6 * multiplier) + t3
		t6 = hash_value & 0xFFFFFFFF 
		
	hash_value = t6
	return hash_value
	
	
func reverse_hash(target_hash: int) -> String:
	var multiplier: int = 0x3FAD
	var chars: Array = []
	var hash_value: int = target_hash
	
	while hash_value > 0:
		var last_char: int = hash_value % multiplier
		hash_value = (hash_value - last_char) / multiplier
		chars.append(last_char)
	
	chars.reverse()
	var result: String = ""
	for ascii in chars:
		if ascii > 0:
			result += char(ascii)
	return result
	
	
func brute_force_hash(target_hash: int, arc_name: String, file_info_offset: int) -> String:
	var possible_prefixes: PackedStringArray = ["0"]
	
	if arc_name == "graph1.arc":
		possible_prefixes = ["bg", "epi"]
	for prefix in possible_prefixes:
		for n in range(1000):
			for m in range(100):
				var filename: String = "%s/%03d_%02d.tm2" % [prefix, n, m]
				if custom_hash_amagami(filename, file_info_offset) == target_hash:
					return filename
				if prefix == "epi":
					for x in range(9):
						for hex_value in range(0x0000, 0x2000):
							var filename2: String = "%s/e%d_%04x.tm2" % [prefix, x, hex_value]
							if custom_hash_amagami(filename2, file_info_offset) == target_hash:
								return filename2
	return ""


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


#func _on_export_names_toggled(_toggled_on: bool) -> void:
	#export_hashed_names = !export_hashed_names
