extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path:String
var selected_file: String
var chose_file: bool = false
var chose_folder: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractArc()
		selected_file = ""
		chose_file = false
		chose_folder = false


func extractArc() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var arc_name: String
	var arc_size: int
	var num_files: int
	var f_offset: int
	var f_name_off: int
	var f_name: String
	var f_size: int
	var off_tbl: int = 0x10
	var dir: DirAccess
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	var bytes: int = in_file.get_32()
	
	if bytes != 0x20435241: #ARC\0x20
		OS.alert("Not a valid ARC header.")
		return
	
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	num_files = in_file.get_32()
	arc_size = in_file.get_32()
	
	dir = DirAccess.open(folder_path)
	
	for files in range(num_files):
		in_file.seek((files * 0x10) + off_tbl)
		
		f_name_off = in_file.get_32()
		f_offset = in_file.get_32() * 0x800
		f_size = in_file.get_32()
		#if f_offset != 0x154D800:
			#continue
		
		in_file.seek(f_name_off)
		var result: Array = ComFuncs.find_end_bytes_file(in_file, 0)
			
		f_name = ComFuncs.convert_jis_packed_byte_array(result[1], shift_jis_dic).get_string_from_utf8()
		
		in_file.seek(f_offset)
		buff = in_file.get_buffer(f_size)
		
		dir.make_dir_recursive(f_name.get_base_dir())
		out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
		out_file.store_buffer(buff)
		out_file.close()
		
		buff.clear()
		
		print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
	
	print_rich("[color=green]Finished![/color]")


func _on_load_dat_pressed() -> void:
	file_load_arc.visible = true


func _on_file_load_arc_file_selected(path: String) -> void:
	file_load_arc.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_file = path


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
