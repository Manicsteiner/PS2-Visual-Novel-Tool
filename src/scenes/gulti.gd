extends Control
# Dev GULTI Co.,LTD

@onready var file_load_bin: FileDialog = $FILELoadBIN
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray

func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_bin()
		folder_path = ""
		selected_files.clear()
		
		
func extract_bin() -> void:
	var buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var f_name: String
	var off_tbl: int
	var off_mod: int
	var name_tbl: int
	var num_files: int
	var name_tbl_size: int
	var f_offset: int
	var f_size: int
	var f_dec_size: int
	var f_id: int
	var start: int
	var dec_flag: int
	
	# TODO: Decryption at 0x00197948 for files that have dec_flag set to 0
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		
		in_file.seek(0)
		if in_file.get_buffer(0xF).get_string_from_ascii() != "GGXArchiver1.00":
			OS.alert("%s does not contain a valid header, skipping." % selected_files[file])
			continue
			
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		in_file.seek(0x10)
		name_tbl_size = in_file.get_32()
		num_files = in_file.get_32()
		off_tbl = (name_tbl_size << 5) + 0x20
		name_tbl = 0x20
		
		for i in range(0, num_files):
			in_file.seek((i * 0x18) + off_tbl)
			f_id = in_file.get_32()
			var unk_flag: int = in_file.get_32()
			f_dec_size = in_file.get_32()
			f_size = in_file.get_32()
			dec_flag = in_file.get_32()
			f_offset = (num_files * 0x18) + ((name_tbl_size << 5) + 0x20) + in_file.get_32()
			
			in_file.seek((f_id * 0x20) + name_tbl)
			f_name = in_file.get_line()
			
			print("%02X %02X %02X %08X %08X %08X %s/%s" % [f_id, unk_flag, dec_flag, f_offset, f_size, f_dec_size, folder_path, f_name])
			
			in_file.seek(f_offset)
			if dec_flag == 2:
				buff = ComFuncs.decompLZSS(in_file.get_buffer(f_size), f_size, f_dec_size)
			elif dec_flag == 0:
				print_rich("[color=red]%s is encrypted. Decryption currently not supported.[/color]" % f_name)
				buff = in_file.get_buffer(f_size)
			else:
				buff = in_file.get_buffer(f_size)
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + f_name.get_base_dir())
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
	
	print_rich("[color=green]Finished![/color]")


func _on_load_bin_pressed() -> void:
	file_load_bin.show()


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
