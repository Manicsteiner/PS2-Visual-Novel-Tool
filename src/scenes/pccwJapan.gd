extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		

func extract_arc() -> void:
	var f_name: String
	var f_offset: int
	var f_size: int
	var num_files: int
	var name_tbl: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		var arc_size: int = in_file.get_length()
		
		num_files = in_file.get_32()
		name_tbl = in_file.get_32() + 1
		var name_pos: int = 0
		
		for i in range(num_files - 1):
			in_file.seek((i * 4) + 8)
			
			f_offset = in_file.get_32()
			f_size = in_file.get_32() - f_offset
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			in_file.seek(name_pos + name_tbl)
			f_name = in_file.get_line()
			name_pos += f_name.length() + 2 #TODO: These 2 bytes are probably some sort of sorting ID
			
			if f_name.ends_with(".tm2"):
				if buff.slice(0, 4).get_string_from_ascii() != "TIM2":
					f_size = buff.decode_u32(0)
					buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size)
			elif f_name.ends_with(".bin"):
				f_size = buff.decode_u32(0)
				buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size)
			
			print("%08X %08X %s/%s/%s" % [f_offset, f_size, folder_path, arc_name, f_name])
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + arc_name)
			
			out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
	print_rich("[color=green]Finished![/color]")


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
