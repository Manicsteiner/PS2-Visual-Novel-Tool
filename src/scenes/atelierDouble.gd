extends Control

@onready var file_load_idx: FileDialog = $FILELoadIDX
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var extract_zlib: CheckBox = $"VBoxContainer/Extract Zlib"

var folder_path: String
var selected_file: String
var comp_scan: bool = true

func _ready() -> void:
	if Main.game_type == Main.SUZUMIYA:
		extract_zlib.show()
	else:
		extract_zlib.hide()
		comp_scan = false
		
		
func _process(_delta: float) -> void:
	if folder_path and selected_file:
		extract_idx()
		selected_file = ""
		folder_path = ""
	
	
func extract_idx() -> void:
	var buff: PackedByteArray
	var idx_file: FileAccess
	var img_file: FileAccess
	var out_file: FileAccess
	var f_name: String
	var f_name_off: int
	var arc_name: String
	var f_offset: int
	var is_folder: bool
	var next_folder_off: int
	var f_size: int
	var folder: String
	var tbl_pos: int
	var hdr_end: int
	
	arc_name = selected_file.get_file().get_basename()
	idx_file = FileAccess.open(selected_file, FileAccess.READ)
	img_file = FileAccess.open(selected_file.get_basename() + ".IMG", FileAccess.READ)
	if img_file == null:
		OS.alert("Could not load %s" % selected_file.get_basename() + ".IMG")
		return
		
	tbl_pos = 16
	idx_file.seek(tbl_pos + 4)
	hdr_end = idx_file.get_32() + tbl_pos
	
	for pos: int in range(tbl_pos, hdr_end, 16):
		idx_file.seek(pos)
		is_folder = idx_file.get_16()
		next_folder_off = idx_file.get_16()
		f_name_off = idx_file.get_32() + pos
		if is_folder:
			idx_file.seek(f_name_off)
			folder += "/%s" % idx_file.get_line()
			continue
			
		f_offset = idx_file.get_32() * 0x800
		f_size = idx_file.get_32()
		if f_size == 0:
			continue
		
		idx_file.seek(f_name_off)
		f_name = idx_file.get_line()
		
		print("%08X %08X %s/%s%s/%s" % [f_offset, f_size, folder_path, arc_name, folder, f_name])
		
		img_file.seek(f_offset)
		buff = img_file.get_buffer(f_size)
		
		var dir: DirAccess = DirAccess.open(folder_path)
		dir.make_dir_recursive(folder_path + "/%s" % arc_name + "/%s" % folder)
		
		out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % folder + "/%s" % f_name, FileAccess.WRITE)
		out_file.store_buffer(buff)
		out_file.close()
		
		if not f_name.get_extension() in ["vag", "ads", "pss", "tm2"]:
			var tm2s: Array[PackedByteArray] = tim2_scan_buffer_mod(buff, 16)
			var id: int = 0
			for tm2 in tm2s:
				out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % folder + "/%s_%02d.TM2" % [f_name, id], FileAccess.WRITE)
				out_file.store_buffer(tm2)
				out_file.close()
				id += 1
			tm2s.clear()
			if comp_scan and f_name.get_extension() != "ebg":
				var offs: Array[int] = scan_packed_offsets(buff)
				id = 0
				var id_2: int = 0
				for off in offs:
					var comp_size: int = buff.decode_u32(off + 8)
					var dec_size: int = buff.decode_u32(off + 12)
					var zlib_file: PackedByteArray =  ComFuncs.decompress_raw_zlib(buff.slice(off + 0x10, off + 0x10 + comp_size))
					out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % folder + "/%s_%02d.DEC" % [f_name, id], FileAccess.WRITE)
					out_file.store_buffer(zlib_file)
					out_file.close()
					id += 1
					
					tm2s = tim2_scan_buffer_mod(zlib_file, 16)
					
					for tm2 in tm2s:
						out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % folder + "/%s_%02d.TM2" % [f_name, id_2], FileAccess.WRITE)
						out_file.store_buffer(tm2)
						out_file.close()
						id_2 += 1
				tm2s.clear()
		
		if next_folder_off == 0:
			folder = ""
			
		#next_folder_off = (next_folder_off << 4) + pos
	
	print_rich("[color=green]Finished![/color]")

func scan_packed_offsets(buffer: PackedByteArray) -> Array[int]:
	# Scans a PackedByteArray for the string "Packed" and records its offsets.
	# Returns an array of offsets where "Packed" is found.
	
	var packed_offsets: Array[int] = []
	var buffer_size: int = buffer.size()
	var packed_string: PackedByteArray = PackedByteArray([0x50, 0x61, 0x63, 0x6B, 0x65, 0x64])
	var packed_length: int = packed_string.size()
	
	for pos: int in range(buffer_size - packed_length + 1):
		if buffer.slice(pos, pos + packed_length) == packed_string:
			packed_offsets.append(pos)
	
	return packed_offsets
	
	
func tim2_scan_buffer_mod(buffer: PackedByteArray, alignment: int) -> Array[PackedByteArray]:
	var extracted_tm2: Array[PackedByteArray] = []
	var pos: int = 0
	var buffer_size: int = buffer.size()
	
	while pos < buffer_size:
		if pos + 4 > buffer_size:
			break
		
		var tm2_bytes: int = buffer.decode_u32(pos)
		var last_pos: int = pos + 4
		
		if tm2_bytes == 0x324D4954:
			if last_pos + 0x10 > buffer_size:
				break
			
			var tm2_size: int = buffer.decode_u32(last_pos + 0xC)
			var total_size: int = tm2_size + 0x10
			
			if tm2_size == 0: # Check for custom TIM2s
				tm2_size = buffer.decode_u32(last_pos + 0x7C)
				total_size = tm2_size + 0x10
				
				var tm2_half: PackedByteArray = buffer.slice(pos + 0x80, pos + 0x80 + tm2_size)
				var new_tm2: PackedByteArray = buffer.slice(pos, pos + 0x10)
				new_tm2.append_array(tm2_half)
				
				if pos + total_size > buffer_size:
					break
					
				extracted_tm2.append(new_tm2)
				
				last_pos = pos + total_size
				if last_pos % alignment != 0:
					last_pos = (last_pos + (alignment - 1)) & ~(alignment - 1)
					
				pos = last_pos
				continue
			if pos + total_size > buffer_size:
				break
			
			extracted_tm2.append(buffer.slice(pos, pos + total_size))
			
			last_pos = pos + total_size
			if last_pos % alignment != 0:  # Align to specified boundary
				last_pos = (last_pos + (alignment - 1)) & ~(alignment - 1)
		else:
			if last_pos % alignment != 0:  # Align to specified boundary
				last_pos = (last_pos + (alignment - 1)) & ~(alignment - 1)
		
		pos = last_pos
	
	return extracted_tm2
	
	
func _on_load_idx_pressed() -> void:
	file_load_idx.show()


func _on_file_load_idx_file_selected(path: String) -> void:
	selected_file = path
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_extract_zlib_toggled(_toggled_on: bool) -> void:
	comp_scan = !comp_scan
