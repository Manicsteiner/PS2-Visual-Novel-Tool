extends Control

var folder_path: String
var selected_file: String
var exe_path: String

@onready var file_load_iso: FileDialog = $FILELoadISO
@onready var file_load_exe: FileDialog = $FILELoadEXE
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

func _process(_delta: float) -> void:
	if folder_path and selected_file:
		extract_arc()
		folder_path = ""
		selected_file = ""
		
		
func extract_arc() -> void:
	var f_name: String
	var f_offset: int
	var f_size: int
	var f_tbl_s: int
	var f_tbl_e: int
	var in_file: FileAccess
	var exe_file: FileAccess
	var out_file: FileAccess
	var arc_id: int = 0
	var f_id: int
	var entry_point: int = 0xFF000
	var buff: PackedByteArray
	
	
	exe_file = FileAccess.open(exe_path, FileAccess.READ)
	if exe_file == null:
		OS.alert("Please load an exe first (SLPS_252.45).")
		return
		
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	in_file.seek(0x828F0)
	if in_file.get_line() != "SLPS_252.45;1":
		OS.alert("Invalid ISO.")
		return
		
	while arc_id < 10:
		if arc_id == 0:
			f_tbl_s = 0x001ef5d0 - entry_point
			f_tbl_e = 0x001ef7b0 - entry_point
		if arc_id == 1:
			f_tbl_s = 0x001ef7b0 - entry_point
			f_tbl_e = 0x001f1ed8 - entry_point
		if arc_id == 2:
			f_tbl_s = 0x001f1ed8 - entry_point
			f_tbl_e = 0x001f44e8 - entry_point
		if arc_id == 3:
			f_tbl_s = 0x001f44e8 - entry_point
			f_tbl_e = 0x001f6488 - entry_point
		if arc_id == 4:
			f_tbl_s = 0x001f6488 - entry_point
			f_tbl_e = 0x001f88d0 - entry_point
		if arc_id == 5:
			f_tbl_s = 0x001f88d0 - entry_point
			f_tbl_e = 0x001fb0b8 - entry_point
		if arc_id == 6:
			f_tbl_s = 0x001fb0b8 - entry_point
			f_tbl_e = 0x001fd1a8 - entry_point
		if arc_id == 7:
			f_tbl_s = 0x001fd1a8 - entry_point
			f_tbl_e = 0x001fdd80 - entry_point
		if arc_id == 8:
			f_tbl_s = 0x001fdd80 - entry_point
			f_tbl_e = 0x001FFC00 - entry_point
		if arc_id == 9:
			f_tbl_s = 0x001ffc28 - entry_point
			f_tbl_e = 0x0020aad0 - entry_point
			
		f_id = 0
		for off in range(f_tbl_s, f_tbl_e, 8):
			exe_file.seek(off)
			f_offset = exe_file.get_32()
			f_size = exe_file.get_32()
			if f_offset == 0 or f_size == 0 or f_offset == 0xFFFFFFFF or f_size == 0xFFFFFFFF:
				continue
				
			f_offset *= 0x800
			if arc_id == 9:
				f_size *= 0x800
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
				f_name = "%02d_%08d.TM2" % [arc_id, f_id]
			else:
				f_name = "%02d_%08d.BIN" % [arc_id, f_id]
				
			print("%02d %08X %08X %s/%s" % [arc_id, f_offset, f_size, folder_path, f_name])
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			f_id += 1
		arc_id += 1
	print_rich("[color=green]Finished![/color]")
	


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_load_iso_pressed() -> void:
	file_load_iso.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_file_load_iso_file_selected(path: String) -> void:
	selected_file = path
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
