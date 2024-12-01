extends Control

var selected_files: PackedStringArray
var folder_path: String
var tm2_toggle: bool = false
var bmp_toggle: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func searchAndExtract() -> void:
	var pos: int
	var last_pos: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var lz77_bytes: int = 0x37375A4C
	var tim2_bytes: int = 0x324D4954
	var dec_size: int
	var f_size: int
	var bytes: int
	var file_name: String
	var search_results: PackedInt32Array
	var f_id: int
	var entry_count: int
	var color: String
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		file_name = selected_files[i].get_file()
		
		# TIM2 search
		if tm2_toggle:
			search_results.clear()
			
			pos = 0
			last_pos = 0
			f_id = 0
			entry_count = 0
			in_file.seek(pos)
			
			while in_file.get_position() < in_file.get_length():
				in_file.seek(pos)
				if in_file.eof_reached():
					break
					
				bytes = in_file.get_32()
				last_pos = in_file.get_position()
				if bytes == tim2_bytes:
					search_results.append(last_pos - 4)
					
					in_file.seek(last_pos + 0xC) #TIM2 size at 0x10
					f_size = in_file.get_32()
						
					in_file.seek(search_results[entry_count]) #Go back to TIM2 header
					buff = in_file.get_buffer(f_size + 0x10)
					
					last_pos = in_file.get_position()
					if !last_pos % 16 == 0: #align to 0x10 boundary
						last_pos = (last_pos + 15) & ~15
						
					out_file = FileAccess.open(folder_path + "/%s" % file_name + "_%04d" % entry_count + ".TM2", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					buff.clear()
					
					print("0x%08X " % search_results[entry_count], "0x%08X " % f_size + "%s" % folder_path + "/%s" % file_name + "_%04d" % f_id + ".TM2")
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
				
			print_rich("[color=%s]Found %d TIM2 entries in %s[/color]" % [color, search_results.size(), file_name])
			
		# BMP search
		if bmp_toggle:
			search_results.clear()
			
			pos = 0
			last_pos = 0
			f_id = 0
			entry_count = 0
			in_file.seek(pos)
			
			while in_file.get_position() < in_file.get_length():
				in_file.seek(pos)
				if in_file.eof_reached():
					break
					
				bytes = in_file.get_32()
				last_pos = in_file.get_position()
				if bytes == tim2_bytes:
					search_results.append(last_pos - 4)
					
					in_file.seek(last_pos + 0xC) #TIM2 size at 0x10
					f_size = in_file.get_32()
						
					in_file.seek(search_results[entry_count]) #Go back to TIM2 header
					buff = in_file.get_buffer(f_size + 0x10)
					
					last_pos = in_file.get_position()
					if !last_pos % 16 == 0: #align to 0x10 boundary
						last_pos = (last_pos + 15) & ~15
						
					out_file = FileAccess.open(folder_path + "/%s" % file_name + "_%04d" % entry_count + ".TM2", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					buff.clear()
					
					print("0x%08X " % search_results[entry_count], "0x%08X " % f_size + "%s" % folder_path + "/%s" % file_name + "_%04d" % f_id + ".TM2")
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
				
			print_rich("[color=%s]Found %d TIM2 entries in %s[/color]" % [color, search_results.size(), file_name])
			
		print_rich("[color=green]Finished searching in %s[/color]" % file_name)


func _on_tm_2_toggle_toggled(_toggled_on: bool) -> void:
	tm2_toggle = !tm2_toggle


func _on_bmp_toggle_toggled(_toggled_on: bool) -> void:
	bmp_toggle = !bmp_toggle
