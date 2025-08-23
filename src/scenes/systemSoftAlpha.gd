extends Control

@onready var file_load_exe: FileDialog = $FILELoadEXE
@onready var file_load_bin: FileDialog = $FILELoadBIN
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var select_exe: String
var folder_path: String
var selected_bins: PackedStringArray
var output_images: bool = false

func _ready() -> void:
	file_load_exe.filters = ["SLPM_552.25"]
	file_load_bin.filters = ["*.BIN"]


func _process(_delta: float) -> void:
	if selected_bins and folder_path:
		extract_bins()
		selected_bins.clear()
		

func extract_bins() -> void:
	for file: int in selected_bins.size():
		var in_file: FileAccess = FileAccess.open(selected_bins[file], FileAccess.READ)
		var exe_file: FileAccess = FileAccess.open(select_exe, FileAccess.READ)
		var arc_name: String = selected_bins[file].get_file().get_basename()
		
		var entry_point: int = 0xFFF80
		var tbl_start: int = 0
		var name_tbl: int = 0
		var folder_tbl: int = 0
		var num_files: int = 0
		if arc_name == "R_GRAPH":
			tbl_start = 0x0023e9f0 - entry_point
			num_files = 0x0000066B
			name_tbl = 0x00245100 - entry_point
			folder_tbl = 0x002450a0 - entry_point
		elif arc_name == "P_ETC":
			tbl_start = 0x0023E6B0 - entry_point
			num_files = 0x0000002D
			name_tbl = 0x0023E9A0 - entry_point
			folder_tbl = 0x0023E980 - entry_point
		elif arc_name == "P_MUSIC":
			tbl_start = 0x00246950 - entry_point
			num_files = 0x00000016
			name_tbl = 0x00246AB0 - entry_point
			folder_tbl = 0x0030B690 - entry_point
		elif arc_name == "P_SE":
			tbl_start = 0x00246B10 - entry_point
			num_files = 0x000000BF
			name_tbl = 0x00247700 - entry_point
			folder_tbl = 0x0030B698 - entry_point
		elif arc_name == "R_VOICE":
			tbl_start = 0x00247A00 - entry_point
			num_files = 0x00003165
			name_tbl = 0x00279050 - entry_point
			folder_tbl = 0x0030B6A0 - entry_point
			
		var dir: DirAccess = DirAccess.open(folder_path)
		var id: int = 0
		for i in range(num_files):
			if id == num_files: break
			exe_file.seek((i * 16) + tbl_start)
			
			var f_off: int = exe_file.get_32()
			var f_size: int = exe_file.get_32()
			var f_folder_id: int = exe_file.get_32()
			var name_id: int = exe_file.get_32()
			
			in_file.seek(f_off)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			
			exe_file.seek((f_folder_id << 2) + folder_tbl)
			var folder_off: int = exe_file.get_32() - entry_point
			
			exe_file.seek(folder_off)
			var folder_name: String = exe_file.get_line()
			
			exe_file.seek((name_id << 2) + name_tbl)
			var name_off: int = exe_file.get_32() - entry_point
			
			exe_file.seek(name_off)
			var f_name: String = exe_file.get_line()
			
			var full_name: String = "%s/%s/%s" % [folder_path, folder_name, f_name]
			
			print("%08X %08X %02d %s" % [f_off, f_size, f_folder_id, full_name])
			
			dir.make_dir_recursive(folder_name)
			
			if f_name.get_extension().to_lower() == "tm2":
				if output_images:
					var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				var pngs: Array[Image] = ComFuncs.load_tim2_images(buff)
				for png_i in range(pngs.size()):
					var png: Image = pngs[png_i]
					png.save_png(full_name + "_%04d.PNG" % png_i)
			elif f_name.get_extension().to_lower() == "gim":
				if output_images:
					var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				var png: Image = ComFuncs.gim_to_image(buff, f_name, true)
				png.save_png(full_name + ".PNG")
			else:
				var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			id += 1
			
	print_rich("[color=green]Finished![/color]")
	
	
func _on_output_images_toggled(_toggled_on: bool) -> void:
	output_images = !output_images


func _on_file_load_exe_file_selected(path: String) -> void:
	select_exe = path


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	selected_bins = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_load_bin_pressed() -> void:
	if not select_exe:
		OS.alert("Please load an exe first (SLPM_xxx.xx)")
		return
		
	file_load_bin.show()
