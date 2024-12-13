extends Control

@onready var file_load_file: FileDialog = $FILELoadFILE
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_exe: FileDialog = $FILELoadEXE

var folder_path:String
var exe_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extractArc()
		selected_files.clear()
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
	var off_tbl: int
	var ext: String
	
	for i in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		arc_name = selected_files[i].get_file()
		
		if arc_name == "DATA.ARC":
			
			var bytes: int = in_file.get_32()
			if bytes != 0x56435241: #ARCV
				OS.alert("Not a valid ARC header.")
				return
			
			in_file.seek(0xC)
			var start_off: int = in_file.get_32()
			
			in_file.seek(0x18)
			var tbl_end: int = in_file.get_32() + 0x30
			var name_tbl: int = tbl_end + 0x15
			var name_pos: int = name_tbl
			
			off_tbl = 0x30
			
			for files in range(off_tbl, tbl_end, 0x10):
				in_file.seek(files)
				
				f_offset = in_file.get_32()  + start_off
				f_size = in_file.get_32()
				
				in_file.seek(name_pos)
				f_name = in_file.get_line()
				
				name_pos = in_file.get_position()
				
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				buff.clear()
				
				print("0x%08X 0x%08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
		elif arc_name == "PACK.BIN":
			var color: String
			var search_results: PackedInt32Array
			in_file = FileAccess.open(selected_files[i], FileAccess.READ)
			f_name = selected_files[i].get_file()
			
			# TIM2 search
			search_results.clear()
			
			var pos: int = 0
			var last_pos: int = 0
			var f_id: int = 0
			var entry_count: int = 0
			in_file.seek(pos)
			
			while in_file.get_position() < in_file.get_length():
				in_file.seek(pos)
				if in_file.eof_reached():
					break
					
				var bytes: int = in_file.get_32()
				last_pos = in_file.get_position()
				if bytes == 0x324D4954:
					search_results.append(last_pos - 4)
					
					in_file.seek(last_pos + 0xC) #TIM2 size at 0x10
					f_size = in_file.get_32()
						
					in_file.seek(search_results[entry_count]) #Go back to TIM2 header
					buff = in_file.get_buffer(f_size + 0x10)
					
					last_pos = in_file.get_position()
					if !last_pos % 16 == 0: #align to 0x10 boundary
						last_pos = (last_pos + 15) & ~15
						
					out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%04d" % entry_count + ".TM2", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					buff.clear()
					
					print("0x%08X " % search_results[entry_count], "0x%08X " % f_size + "%s" % folder_path + "/%s" % f_name + "_%04d" % f_id + ".TM2")
					entry_count += 1
				else:
					if !last_pos % 16 == 0: #align to 0x10 boundary
						last_pos = (last_pos + 15) & ~15
						
				pos = last_pos
				f_id += 1
			
			if entry_count > 0:
				color = "green"
			else:
				color = "red"
				
			print_rich("[color=%s]Found %d TIM2 entries in %s[/color]" % [color, search_results.size(), f_name])
			
		print_rich("[color=green]Finished searching in %s[/color]" % f_name)
			#todo some other time, can't figure out at the moment
			#var exe_file: FileAccess = FileAccess.open(exe_path, FileAccess.READ)
			#if exe_file == null:
				#OS.alert("Must load EXE first to extract PACK.BIN")
				#continue
				#
			#var exe_off: int = 0x00277198 - 0xFF000
			#var exe_end: int = 0x0027a0e0 - 0xFF000
			#var pos: int = 0
			#var next_start: int = 0
			#var files: int = 0
			#while exe_off < exe_end:
				#if in_file.eof_reached():
					#break
					#
				#exe_file.seek(exe_off)
				#
				#f_offset = exe_file.get_32() + next_start
				#f_size = exe_file.get_32()
				#
				#while f_size == 0:
					#f_size = exe_file.get_32()
					#
				#
				#if (f_size - f_offset) < 0:
					#in_file.seek(f_offset)
					#buff = in_file.get_buffer(f_size)
					#
					#var bytes: int = buff.decode_u32(0)
					#if bytes == 0x324D4954: #TIM2
						#ext = ".TM2"
					#else:
						#ext = ".BIN"
					#
					#next_start = f_offset
					#
					#f_name = "%08d" % files
					#files += 1
					#exe_off += 4
					#
					#out_file = FileAccess.open(folder_path + "/%s" % f_name + ext, FileAccess.WRITE)
					#out_file.store_buffer(buff)
					#out_file.close()
					#
					#buff.clear()
					#
					#print("%08X %08X /%s/%s" % [f_offset, f_size - f_offset, folder_path, f_name + ext])
					#continue
					#
				#in_file.seek(f_offset)
				#buff = in_file.get_buffer(f_size - f_offset)
				#
				#if buff.size() == 0:
					#files += 1
					#exe_off += 4
					#continue
				#
					#
				#var bytes: int = buff.decode_u32(0)
				#if bytes == 0x324D4954: #TIM2
					#ext = ".TM2"
				#else:
					#ext = ".BIN"
				#
				#f_name = "%08d" % files
				#files += 1
				#exe_off += 4
				#
				#out_file = FileAccess.open(folder_path + "/%s" % f_name + ext, FileAccess.WRITE)
				#out_file.store_buffer(buff)
				#out_file.close()
				#
				#buff.clear()
				#
				#print("0x%08X 0x%08X /%s/%s" % [f_offset, f_size - f_offset, folder_path, f_name + ext])
	
	print_rich("[color=green]Finished![/color]")


func _on_load_file_pressed() -> void:
	file_load_file.visible = true


func _on_file_load_file_files_selected(paths: PackedStringArray) -> void:
	file_load_file.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true


func _on_load_exe_pressed() -> void:
	file_load_exe.visible = true


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path
