extends Control

@onready var file_load_exe: FileDialog = $FILELoadEXE
@onready var file_load_bin: FileDialog = $FILELoadBIN
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var selected_exe: String
var folder_path: String
var selected_pacs: PackedStringArray
var output_images: bool = false

func _ready() -> void:
	file_load_exe.filters = ["SLPS_255.14"]
	file_load_bin.filters = ["*.PAC"]


func _process(_delta: float) -> void:
	if selected_pacs and folder_path:
		extract_pac()
		selected_pacs.clear()
		

func extract_pac() -> void:
	for file: int in selected_pacs.size():
		var in_file: FileAccess = FileAccess.open(selected_pacs[file], FileAccess.READ)
		var exe_file: FileAccess = FileAccess.open(selected_exe, FileAccess.READ)
		var arc_name: String = selected_pacs[file].get_file().get_basename()
		
		var entry_point: int = 0xFFF80
		var tbl_start: int = 0
		if arc_name == "BG":
			tbl_start = 0x0062d230 - entry_point
		elif arc_name == "TITLE":
			tbl_start = 0x0062A320 - entry_point
		elif arc_name == "FACE":
			tbl_start = 0x0062AC40 - entry_point
		elif arc_name == "INIT":
			tbl_start = 0x0062A180 - entry_point
		elif arc_name == "BGM":
			tbl_start = 0x0062BF00 - entry_point
		elif arc_name == "SE0":
			tbl_start = 0x0062C380 - entry_point
		elif arc_name == "MDLS":
			tbl_start = 0x0062C4C0 - entry_point
		elif arc_name == "ICON":
			tbl_start = 0x00631AE0 - entry_point
		elif arc_name == "CHAR":
			tbl_start = 0x0062EF60 - entry_point
		elif arc_name == "STUDIO":
			tbl_start = 0x00633bb0 - entry_point
		elif arc_name == "SHOP":
			tbl_start = 0x00634210 - entry_point
		elif arc_name == "PEOPLE":
			tbl_start = 0x00634420 - entry_point
		elif arc_name == "MAP":
			tbl_start = 0x00634AF0 - entry_point
		elif arc_name == "SCRIPT":
			tbl_start = 0x00635480 - entry_point
		elif arc_name == "OPT":
			tbl_start = 0x00635670 - entry_point
		elif arc_name == "MC":
			tbl_start = 0x00635740 - entry_point
		elif arc_name == "VOICE":
			tbl_start = 0x0063F7A0 - entry_point
		elif arc_name == "SE1":
			tbl_start = 0x00653E00 - entry_point
		elif arc_name == "SMENU":
			tbl_start = 0x00654C70 - entry_point
		elif arc_name == "ALBUM":
			tbl_start = 0x00654D80 - entry_point
		elif arc_name == "ZUKAN":
			tbl_start = 0x00654E60 - entry_point
			
		var dir: DirAccess = DirAccess.open(folder_path)
		var pos: int = tbl_start
		while true:
			exe_file.seek(pos)
			var name_off: int = exe_file.get_64()
			if name_off == 0: break
			var f_off: int = exe_file.get_64()
			var f_off_next: int = exe_file.get_64()
			var f_size: int = exe_file.get_64()
			
			name_off -= entry_point
			
			exe_file.seek(name_off)
			var f_name: String = exe_file.get_line()
			
			var full_name: String = "%s/%s/%s" % [folder_path, arc_name, f_name]
			
			print("%08X %08X %s" % [f_off, f_size, full_name])
			
			in_file.seek(f_off)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			
			dir.make_dir_recursive(arc_name)
			
			if f_name.get_extension().to_lower() == "tm2":
				if output_images:
					var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				var pngs: Array[Image] = ComFuncs.load_tim2_images(buff)
				for png_i in range(pngs.size()):
					var png: Image = pngs[png_i]
					png.save_png(full_name + "_%04d.PNG" % png_i)
			else:
				var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			pos += 0x20
			
	print_rich("[color=green]Finished![/color]")
	
	
func _on_output_images_toggled(_toggled_on: bool) -> void:
	output_images = !output_images


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	selected_exe = path


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	selected_pacs = paths
	file_load_folder.show()


func _on_load_bin_pressed() -> void:
	if not selected_exe:
		OS.alert("Please load an exe first (SLPS_xxx.xx)")
		return
		
	file_load_bin.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
