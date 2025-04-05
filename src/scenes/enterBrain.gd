extends Control

var folder_path: String
var selected_files: PackedStringArray
var debug_brute_force_names: bool = false
#var export_hashed_names: bool = false

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

#func _ready() -> void:
	#print("%04X" % custom_hash("epi/e1_01a0.tm2", 0x256))

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
	

func custom_hash(input_string: String, file_info_offset) -> int:
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
				if custom_hash(filename, file_info_offset) == target_hash:
					return filename
				if prefix == "epi":
					for x in range(9):
						for hex_value in range(0x0000, 0x2000):
							var filename2: String = "%s/e%d_%04x.tm2" % [prefix, x, hex_value]
							if custom_hash(filename2, file_info_offset) == target_hash:
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
