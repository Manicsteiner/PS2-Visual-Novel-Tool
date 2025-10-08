extends Control

@onready var file_load_d: FileDialog = $FILELoadD
@onready var file_load_tm_2: FileDialog = $FILELoadTM2
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_cvm: FileDialog = $FILELoadCVM

var selected_tm2s: PackedStringArray
var selected_ds: PackedStringArray
var folder_path: String = ""


func _ready() -> void:
	file_load_d.filters = ["*.D"]
	file_load_tm_2.filters = ["*.TM2"]


func _process(_delta: float) -> void:
	if selected_tm2s and folder_path:
		parse_tm2()
		selected_tm2s.clear()
		folder_path = ""
	elif selected_ds and folder_path:
		extract_d()
		selected_ds.clear()
		folder_path = ""


func parse_tm2() -> void:
	for file in selected_tm2s.size():
		var in_file: FileAccess = FileAccess.open(selected_tm2s[file], FileAccess.READ)
		var f_name: String = selected_tm2s[file].get_file()
		
		in_file.seek(0)
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		
		var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, true)
		for i in range(pngs.size()):
			var png: Image = pngs[i]
			png.save_png(folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
			print("%s" % folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
	print_rich("[color=green]Finished![/color]")


func extract_d() -> void:
	for file: int in selected_ds.size():
		var in_file: FileAccess = FileAccess.open(selected_ds[file], FileAccess.READ)
		var arc_name: String = selected_ds[file].get_file().get_basename()
		var arc_size: int = in_file.get_length()
		
		in_file.seek(0)
		var num_files: int = in_file.get_32()
		var name_off: int = in_file.get_32()
		
		var dir: DirAccess = DirAccess.open(folder_path)
		for i in range(num_files - 1):
			in_file.seek((i * 4) + 8)
			
			var f_off: int = in_file.get_32()
			var f_size: int = in_file.get_32() - f_off
			if i == num_files - 1: f_size = arc_size
			
			in_file.seek(name_off)
			var unk_byte: int = in_file.get_8()
			var name_size: int = in_file.get_8()
			var f_name: String = in_file.get_buffer(name_size).get_string_from_ascii()
			name_off = in_file.get_position()
			
			in_file.seek(f_off)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			
			if arc_name.to_lower() == "sysdata":
				f_size = buff.decode_u32(0)
				buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size)
				
			var buff_hdr: String = buff.slice(0, 4).get_string_from_ascii()
			
			dir.make_dir_recursive(arc_name)
			
			var temp_n: String = get_unique_filename(folder_path + "/%s" % arc_name, f_name.get_basename(), f_name.get_extension())
			if !temp_n == "":
				f_name = temp_n
			
			var full_name: String = "%s/%s/%s" % [folder_path, arc_name, f_name]
			print("%08X %08X %s" % [f_off, f_size, full_name])
			
			var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			if buff_hdr == "TIM2":
				var pngs: Array[Image] = ComFuncs.load_tim2_images(buff)
				for png_i in range(pngs.size()):
					var png: Image = pngs[png_i]
					png.save_png(full_name + "_%04d.PNG" % png_i)
					
	print_rich("[color=green]Finished![/color]")
	
	
func get_unique_filename(folder_path: String, base_name: String, extension: String) -> String:
	var dir: DirAccess = DirAccess.open(folder_path)
	if not dir:
		return ""
	
	var highest_id: int = 0
	var base_file: String = "%s.%s" % [base_name, extension]
	var file_pattern: String = "%s_" % base_name
	var file_found: bool = false

	# Scan folder for matching files
	for file in dir.get_files():
		if file == base_file:
			file_found = true
			highest_id = max(highest_id, 1)  # Base file exists, start IDs from 1
		elif file.begins_with(file_pattern) and file.ends_with("." + extension):
			var id_str: String = file.trim_prefix(file_pattern).trim_suffix("." + extension)
			var id: int = id_str.to_int()
			if id > 0:
				highest_id = max(highest_id, id)
				file_found = true

	if file_found:
		return "%s_%05d.%s" % [base_name, highest_id + 1, extension]
	
	return ""
	
	
func _on_file_load_cvm_dir_selected(dir: String) -> void:
	var cvm_name: String = "DATA.CVM"
	var exe_path: String = dir + "/cvm_tool.exe"
	var temp: FileAccess = FileAccess.open(exe_path, FileAccess.READ)
	if temp == null:
		OS.alert("Could not open %s" % exe_path)
		return
	
	temp.close()
	var input_path: String = dir + "/%s" % cvm_name
	temp = FileAccess.open(input_path, FileAccess.READ)
	if temp == null:
		OS.alert("Could not open %s" % input_path)
		return
	
	temp.close()
	var output_path: String = dir + "/OUT.ISO"
	temp = FileAccess.open(output_path, FileAccess.WRITE)
	if temp == null:
		OS.alert("Could not open %s for writting" % output_path)
		return
	temp.close()
	
	print_rich("[color=yellow]Converting CVM...")
	
	var args: PackedStringArray = ["split", input_path, output_path]
	var output: Array = []
	
	var exit_code: int = OS.execute(exe_path, args, output, true, false)

	print("Exit code: %d" % exit_code)
	print(output)
	print_rich("[color=green]Finished![/color]")


func _on_load_tm_2_pressed() -> void:
	file_load_tm_2.show()


func _on_load_d_pressed() -> void:
	file_load_d.show()


func _on_file_load_tm_2_files_selected(paths: PackedStringArray) -> void:
	selected_tm2s = paths
	file_load_folder.show()


func _on_file_load_d_files_selected(paths: PackedStringArray) -> void:
	selected_ds = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_cvm_pressed() -> void:
	file_load_cvm.show()
