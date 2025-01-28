extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if chose_file and chose_folder:
		extractArc()
		selected_files.clear()
		chose_file = false
		chose_folder = false
	
	
func extractArc() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var num_files: int
	var off_tbl: int
	var name_tbl: int
	var name_tbl_size: int
	var f_offset: int
	var f_name: String
	var f_size: int
	var f_ext: String
	var ext: String
	
	# TODO: .LSD decompression
	
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	for file in range(selected_files.size()):
		if selected_files[file].get_extension().to_lower() == "afs":
			in_file = FileAccess.open(selected_files[file], FileAccess.READ)
			
			in_file.seek(4)
			num_files = in_file.get_32()
			
			off_tbl = 8
			
			in_file.seek((num_files * 8) + off_tbl)
			name_tbl = in_file.get_32()
			name_tbl_size = in_file.get_32()
			
			if name_tbl == 0 or name_tbl_size == 0:
				# check for odd cases where name table isn't the last in the offset table
				in_file.seek(8)
				f_offset = in_file.get_32()
				
				in_file.seek(f_offset - 8)
				name_tbl = in_file.get_32()
				name_tbl_size = in_file.get_32()
				if name_tbl == 0 or name_tbl_size == 0:
					print_rich("[color=red]Couldn't find name table in %s" % selected_files[file])
			
			for files in range(num_files - 1):
				in_file.seek((files * 8) + off_tbl)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				if name_tbl != 0 or name_tbl_size != 0:
					in_file.seek((files * 0x30) + name_tbl)
					f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(in_file, 0)[1], shift_jis_dic).get_string_from_utf8()
					f_ext = f_name.get_extension()
				else:
					f_name = "%04d" % files
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
			
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		else:
			in_file = FileAccess.open(selected_files[file], FileAccess.READ)
			var bin_file: FileAccess = FileAccess.open(selected_files[file].get_basename() + ".BIN", FileAccess.READ)
			if !bin_file:
				OS.alert("Can't find header file %s to %s" % [selected_files[file].get_basename() + ".BIN", selected_files[file]])
				continue
			
			bin_file.seek(0)
			if bin_file.get_buffer(0xC).get_string_from_ascii() != "LSDARC V.100":
				OS.alert("Couldn't find header 'LSDARC V.100' in %s" % selected_files[file].get_basename() + ".BIN")
				continue
			
			bin_file.seek(0xC)
			num_files = bin_file.get_32()
			
			bin_file.seek(0x14)
			for i in range(num_files):
				f_offset = bin_file.get_32()
				f_size = bin_file.get_32()
				var next_f: int = bin_file.get_32()
				f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(bin_file, 0)[1], shift_jis_dic).get_string_from_utf8()
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				var bytes: int = buff.decode_u32(0)
				if bytes == 0x324D4954: # TIM2
					f_name += ".TM2"
				elif bytes == 0x20524353: # SCRx20
					f_name += ".SCR"
				elif bytes == 0x1A44534C: # LSDx1A
					f_name += ".LSD"
				else:
					f_name += ".BIN"
					
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				buff.clear()
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
				
				bin_file.seek(bin_file.get_position() + 4)
	
	print_rich("[color=green]Finished![/color]")


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	chose_file = true
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
