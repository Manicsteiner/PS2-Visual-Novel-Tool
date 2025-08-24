extends Control

@onready var file_load_folder: FileDialog = $FILELoadFolder
@onready var file_load_tm_2: FileDialog = $FILELoadTM2
@onready var file_load_gim: FileDialog = $FILELoadGIM
@onready var file_load_search: FileDialog = $FILELoadSearch

var selected_files: PackedStringArray
var selected_tm2s: PackedStringArray
var selected_gims: PackedStringArray
var folder_path: String
var tm2_toggle: bool = true
var bmp_toggle: bool = false

var tm2_fix_alpha: bool = true
var tm2_swizzle: bool = true
var tm2_swap_rgb: bool = true

var gim_ps2_mode: bool = false


func _process(_delta: float) -> void:
	if selected_tm2s and folder_path:
		parse_tm2()
		selected_tm2s.clear()
		folder_path = ""
	elif selected_gims and folder_path:
		parse_gim()
		selected_gims.clear()
		folder_path = ""
	elif selected_files:
		search_extract()
		selected_files.clear()
		folder_path = ""
	
	
func parse_tm2() -> void:
	for file in selected_tm2s.size():
		var in_file: FileAccess = FileAccess.open(selected_tm2s[file], FileAccess.READ)
		var f_name: String = selected_tm2s[file].get_file()
		
		in_file.seek(0)
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		
		var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, tm2_fix_alpha, tm2_swizzle, tm2_swap_rgb)
		for i in range(pngs.size()):
			var png: Image = pngs[i]
			png.save_png(folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
			print("%s" % folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
	print_rich("[color=green]Finished![/color]")
	
	
func parse_gim() -> void:
	for file in selected_gims.size():
		var in_file: FileAccess = FileAccess.open(selected_gims[file], FileAccess.READ)
		var f_name: String = selected_gims[file].get_file()
		
		in_file.seek(0)
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		
		var png: Image = ComFuncs.gim_to_image(buff, f_name, gim_ps2_mode)
		png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" % file)
		print("%s" % folder_path + "/%s" % f_name + "_%04d.PNG" % file)
	print_rich("[color=green]Finished![/color]")
	
	
func search_extract() -> void:
	if tm2_toggle:
		for file in selected_files.size():
			var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
			var f_name: String = selected_files[file].get_file()
			
			in_file.seek(0)
			ComFuncs.tim2_scan_file(in_file)
			
			print_rich("[color=green]Finished searching in %s[/color]" % f_name)
	print_rich("[color=green]Finished![/color]")
	
func _on_tm_2_toggle_toggled(_toggled_on: bool) -> void:
	tm2_toggle = !tm2_toggle


func _on_bmp_toggle_toggled(_toggled_on: bool) -> void:
	bmp_toggle = !bmp_toggle


func _on_load_tm_2_pressed() -> void:
	file_load_tm_2.show()


func _on_file_load_tm_2_files_selected(paths: PackedStringArray) -> void:
	selected_tm2s = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_tm_2_fix_alpha_toggled(_toggled_on: bool) -> void:
	tm2_fix_alpha = !tm2_fix_alpha


func _on_tm_2_swizzle_toggled(_toggled_on: bool) -> void:
	tm2_swizzle = !tm2_swizzle


func _on_tm_2rg_bswap_toggled(_toggled_on: bool) -> void:
	tm2_swap_rgb = !tm2_swap_rgb


func _on_gimps_2_width_toggled(_toggled_on: bool) -> void:
	gim_ps2_mode = !gim_ps2_mode


func _on_file_load_gim_files_selected(paths: PackedStringArray) -> void:
	selected_gims = paths
	file_load_folder.show()


func _on_load_gim_pressed() -> void:
	file_load_gim.show()


func _on_search_in_files_button_pressed() -> void:
	file_load_search.show()


func _on_file_load_search_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
