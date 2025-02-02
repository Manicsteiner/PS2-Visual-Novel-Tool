extends Control

@onready var file_load_lmm: FileDialog = $FILELoadLMM
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_file: String
var chose_file: bool = false
var chose_folder: bool = false

func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extract_lmm()
		chose_folder = false
		chose_file = false
		selected_file = ""
		

func extract_lmm() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var f_name_off: int
	var f_offset: int
	var f_size: int
	var num_files: int
	
	if selected_file.get_extension().to_lower() == "lmm":
		in_file = FileAccess.open(selected_file, FileAccess.READ)
		var hdr_str: String = in_file.get_buffer(0xE).get_string_from_ascii()
		if hdr_str != "LMM_File_V1.00":
			OS.alert("Invalid header in %s. Expected 'LMM_File_V1.00' but got %s" % [selected_file, hdr_str])
			return
		
		in_file.seek(0x10)
		num_files = in_file.get_32()
		for pos in range(0x14, num_files, 0xC):
			in_file.seek(pos)
			f_name_off = in_file.get_32()
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			
			in_file.seek(f_name_off)
			f_name = in_file.get_line()
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/%s" % f_name.get_base_dir())
			
			in_file.seek(f_offset)
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(in_file.get_buffer(f_size))
			out_file.close()
				
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
	elif selected_file.get_extension().to_lower() == "bl":
		in_file = FileAccess.open(selected_file, FileAccess.READ)
		
		in_file.seek(0x4)
		num_files = in_file.get_32()
		var start: int = in_file.get_32()
		var hdr_pos: int = 0x10
		for i in range(num_files):
			in_file.seek(hdr_pos)
			f_offset = in_file.get_32() # ?
			f_size = in_file.get_32()
			f_name = in_file.get_line()
			
			hdr_pos += 0x20
			
			in_file.seek(start)
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(in_file.get_buffer(f_size))
			out_file.close()
				
			print("%08X %08X %s/%s" % [start, f_size, folder_path, f_name])
			
			start = in_file.get_position()
	
	print_rich("[color=green]Finished![/color]")


func _on_load_lmm_pressed() -> void:
	file_load_lmm.show()


func _on_file_load_lmm_file_selected(path: String) -> void:
	selected_file = path
	chose_file = true
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
