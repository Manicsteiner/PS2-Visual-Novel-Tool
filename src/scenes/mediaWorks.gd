extends Control

@onready var file_load_bin: FileDialog = $FILELoadBin
@onready var file_load_folder: FileDialog = $FILELoadFolder
@onready var file_load_ex_bins: FileDialog = $FILELoadExBins

var folder_path: String = ""
var selected_file: String = ""
var selected_bins: PackedStringArray


func _process(_delta: float) -> void:
	if selected_file and folder_path:
		extractBin()
		folder_path = ""
		selected_file = ""
		selected_bins.clear()
	elif selected_bins and folder_path:
		searchAndExtract()
		folder_path = ""
		selected_file = ""
		selected_bins.clear()


func extractBin() -> void:
	var f_id: int
	var f_size: int
	var f_offset: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var file_tbl_off: int
	var unk1: int
	var unk2: int
	var unk3: int
	var i: int
	var lz77_bytes: int
	var tim2_bytes: int
	var dec_size: int
	var ext: String
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	
	in_file.seek(0x8)
	file_tbl_off = in_file.get_32()
	in_file.seek(file_tbl_off)
	unk1 = in_file.get_32() #num files?
	unk2 = in_file.get_32()
	unk3 = in_file.get_32()
	
	i = 0
	while true:
		in_file.seek((i * 0xC) + file_tbl_off + 0xC)
		f_offset = in_file.get_32()
		f_id = in_file.get_32()
		f_size = in_file.get_32()
		if f_offset == 0:
			break
		
		in_file.seek(f_offset)
		lz77_bytes = in_file.get_32()
		
		if lz77_bytes == 0x37375A4C: #lz77
			dec_size = in_file.get_32()
			f_size = in_file.get_32()
			
			buff = ComFuncs.decompLZSS(in_file.get_buffer(f_size), f_size, dec_size)
			
			tim2_bytes = buff.decode_u32(0)
			if tim2_bytes == 0x324D4954:
				ext = ".TM2"
			else:
				ext = ".BIN"
			
			out_file = FileAccess.open(folder_path + "/%08d" % f_id + ext, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			buff.clear()
			
			print("0x%08X " % f_offset, "0x%08X " % dec_size + "%s" % folder_path + "/%08d" % f_id + ext)
			
			i += 1
			continue
		elif lz77_bytes == 0x64685353: #SShd
			in_file.seek(f_offset)
			
			buff = in_file.get_buffer(f_size)
			
			ext = ".ADS"
			
			out_file = FileAccess.open(folder_path + "/%08d" % f_id + ext, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			buff.clear()
			
			print("0x%08X " % f_offset, "0x%08X " % dec_size + "%s" % folder_path + "/%08d" % f_id + ext)
			i += 1
			continue
		elif lz77_bytes == 0xBA010000: #PSS video header
			in_file.seek(f_offset)
			
			buff = in_file.get_buffer(f_size)
			
			ext = ".PSS"
			
			out_file = FileAccess.open(folder_path + "/%08d" % f_id + ext, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			buff.clear()
			
			print("0x%08X " % f_offset, "0x%08X " % dec_size + "%s" % folder_path + "/%08d" % f_id + ext)
			i += 1
			continue
		else:
			in_file.seek(f_offset)
			
			buff = in_file.get_buffer(f_size)
			
			ext = ".BIN"
			
			out_file = FileAccess.open(folder_path + "/%08d" % f_id + ext, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			buff.clear()
			
			print("0x%08X " % f_offset, "0x%08X " % dec_size + "%s" % folder_path + "/%08d" % f_id + ext)
			i += 1
			continue
				
	print_rich("[color=green]Finished![/color]")


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
	
	for i in range(0, selected_bins.size()):
		in_file = FileAccess.open(selected_bins[i], FileAccess.READ)
		file_name = selected_bins[i].get_file()
		
		search_results.clear()
		pos = 0
		last_pos = 0
		f_id = 0
		entry_count = 0
		
		print_rich("[color=yellow]Searching for LZ77 and TIM2 files in %s. Please wait...[/color]" % file_name)
		
		while in_file.get_position() < in_file.get_length():
			in_file.seek(pos)
			if in_file.eof_reached():
				break
				
			bytes = in_file.get_32()
			last_pos = in_file.get_position()
			if bytes == lz77_bytes:
				search_results.append(last_pos - 4)
				
				dec_size = in_file.get_32()
				f_size = in_file.get_32()
					
				buff = ComFuncs.decompLZSS(in_file.get_buffer(f_size), f_size, dec_size)
				
				last_pos = in_file.get_position()
				if !last_pos % 16 == 0: #align to 0x10 boundary
					last_pos = (last_pos + 15) & ~15
					
				out_file = FileAccess.open(folder_path + "/%s" % file_name + "_%04d" % entry_count + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				buff.clear()
				
				print("0x%08X " % search_results[entry_count], "0x%08X " % f_size + "%s" % folder_path + "/%s" % file_name + "_%04d" % f_id + ".BIN")
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
			
		print_rich("[color=%s]Found %d LZ77 compressed entries in %s[/color]" % [color, search_results.size(), file_name])
		
		search_results.clear()
		
		pos = 0
		last_pos = 0
		f_id = 0
		entry_count = 0
		in_file.seek(pos)
		# TIM2 search
		
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
	
	
func _on_load_bin_pressed() -> void:
	file_load_bin.visible = true


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_file_load_bin_file_selected(path: String) -> void:
	file_load_bin.visible = false
	file_load_folder.visible = true
	selected_file = path


func _on_load_ex_bin_pressed() -> void:
	file_load_ex_bins.visible = true


func _on_file_load_ex_bins_files_selected(paths: PackedStringArray) -> void:
	file_load_ex_bins.visible = false
	file_load_folder.visible = true
	selected_bins = paths
