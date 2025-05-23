extends Control

var folder_path: String = ""
var selected_files: PackedStringArray = []

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		
		
func extract_arc() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		if in_file.get_buffer(6).get_string_from_ascii() != "DIGPCK":
			OS.alert("%s isn't a valid PCK!" % selected_files[file].get_file())
			continue
			
		in_file.seek(0x28)
		var start_off: int = in_file.get_32() + 0x2C
		var pos: int = 0x2C
		while pos < start_off:
			in_file.seek(pos)
			
			var result: Array = ComFuncs.find_end_bytes_file(in_file, 0)
			var f_name: String = ComFuncs.convert_jis_packed_byte_array(result[1], shift_jis_dic).get_string_from_utf8()
			
			pos = in_file.get_position() + 1
			
			in_file.seek(pos)
			var unk32_1: int = in_file.get_32()
			var f_offset: int= in_file.get_32() + start_off
			var f_size: int = in_file.get_32()
			pos = in_file.get_position()
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
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
