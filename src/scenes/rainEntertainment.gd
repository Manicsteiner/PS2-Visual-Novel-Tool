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
	var in_file: FileAccess
	var tbl_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var tex_hdr: String = "****TEX_DATA****"
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		tbl_file = FileAccess.open(selected_files[file].get_basename() + ".TAG", FileAccess.READ)
		if tbl_file == null:
			OS.alert("Could not find %s for %s!" % [selected_files[file].get_basename() + ".TAG", selected_files[file].get_file()])
			continue
			
		var f_tbl: int = 0x810
		var tbl_size: int = tbl_file.get_length()
		var i: int = 0
		while true:
			tbl_file.seek(f_tbl + i * 0x20)
			if tbl_file.get_position() >= tbl_size:
				break
			
			f_name = tbl_file.get_buffer(0x10).get_string_from_ascii()
			var unk_32: int = tbl_file.get_32()
			f_offset = tbl_file.get_32()
			f_size = tbl_file.get_32()
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
				f_name += ".TM2"
			
			if f_name.get_extension().to_lower() == "prs":
				f_size = buff.decode_u32(0)
				buff = ComFuncs.decompLZSS(buff.slice(4), buff.size() - 4, f_size)
				if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
					f_name += ".TM2"
				elif buff.slice(0, 16).get_string_from_ascii() == tex_hdr:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					var buff_i: int = 0
					while true:
						var pos: int = 0x20 + buff_i * 0x20
						var temp_name: String = buff.slice(pos, pos + 0x10).get_string_from_ascii()
						if temp_name == "":
							break
						temp_name
						f_offset = buff.decode_u32(pos + 0x14)
						f_size = buff.decode_u32(pos + 0x34)
						if f_size == 0: f_size = buff.size()
						
						print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, temp_name])
						
						var n_buff: PackedByteArray = buff.slice(f_offset, f_size)
						
						out_file = FileAccess.open(folder_path + "/%s" % temp_name, FileAccess.WRITE)
						out_file.store_buffer(n_buff)
						out_file.close()
						buff_i += 1
				
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			i += 1
	print_rich("[color=green]Finished![/color]")


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
