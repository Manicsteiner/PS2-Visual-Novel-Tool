extends Control

@onready var file_load_obj: FileDialog = $FILELoadOBJ
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var debug_out: bool = false
var remove_alpha: bool = true

func _ready() -> void:
	if Main.game_type == Main.SHINE:
		file_load_obj.filters = [
			"*.obj"
			]
	else:
		file_load_obj.filters = [
			"*.obj"
			]
			
			
func _process(_delta: float) -> void:
	if folder_path and selected_files:
		convert_obj()
		folder_path = ""
		selected_files.clear()
		
		
func convert_obj() -> void:
	var buff: PackedByteArray
	var img_dat: PackedByteArray
	var palette: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var f_name: String
	var img_off_tbl: int
	var part_off: int
	var part_size: int
	var part_dec_size: int
	var num_sections: int
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		f_name = selected_files[file].get_file()
		
		var sections_off: int = 0x800
		
		if Main.game_type != Main.SHINE:
			in_file.seek(0)
			palette = ComFuncs.unswizzle_palette(in_file.get_buffer(0x400), 32)
		if Main.game_type == Main.SHAKUGAN or Main.game_type == Main.NOGIZAKA:
			sections_off = 0x1800
		elif Main.game_type == Main.SHINE or Main.game_type == Main.GUARDIANANGEL:
			sections_off = 0
			if Main.game_type == Main.GUARDIANANGEL and f_name.begins_with("BU_"):
				sections_off = 0x400
				in_file.seek(0)
				palette = ComFuncs.unswizzle_palette(in_file.get_buffer(0x400), 32)
			elif Main.game_type == Main.GUARDIANANGEL and !f_name.begins_with("BU_"):
				palette.clear()
		
		in_file.seek(sections_off)
		num_sections = in_file.get_32()
		img_off_tbl = in_file.get_position()
		if num_sections > 32 or num_sections == 0:
			push_error("Unknown or invalid .obj in %s" % f_name)
			continue
		
		for pos: int in range(0, num_sections):
			in_file.seek((pos * 4) + img_off_tbl)
			part_off = in_file.get_32() + sections_off
			part_size = in_file.get_32() - part_off + sections_off
			
			in_file.seek(part_off)
			part_dec_size = in_file.get_32()
			buff = ComFuncs.decompLZSS(in_file.get_buffer(part_size - 4), part_size - 4, part_dec_size)
			
			if debug_out:
				out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%02d" % pos + ".prt", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			img_dat.append_array(buff)
		
		print("%08X %02X /%s/%s" % [img_dat.size(), num_sections, folder_path, f_name])
		
		if debug_out:
			out_file = FileAccess.open(folder_path + "/%s" % f_name + ".com", FileAccess.WRITE)
			out_file.store_buffer(img_dat)
			out_file.close()
			
		var w: int = 640
		var h: int = 448
		if Main.game_type == Main.SHUFFLE and f_name.begins_with("SG"):
			w = 512
			h = 448
		elif Main.game_type == Main.GUARDIANANGEL and f_name.begins_with("BU_"):
			w = 512
			h = 512
			
		in_file.seek(0x400)
		if in_file.get_buffer(3).get_string_from_ascii() == "MAP":
			print_rich("[color=yellow]Character MAP sorting not supported.")
			in_file.seek(0x41C)
			w = in_file.get_16()
			h = in_file.get_16()
			
		if palette:
			var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
			for y in range(h):
				for x in range(w):
					var pixel_index: int = img_dat[x + y * w]
					var r: int = palette[pixel_index * 4 + 0]
					var g: int = palette[pixel_index * 4 + 1]
					var b: int = palette[pixel_index * 4 + 2]
					#var a: int = palette[pixel_index * 4 + 3]
					image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
			f_name += ".PNG"
			image.save_png(folder_path + "/%s" % f_name)
		elif Main.game_type == Main.SHINE or Main.game_type == Main.GUARDIANANGEL:
			var image: Image = ComFuncs.convert_rgb555_to_image(img_dat, w, h, true)
			f_name += ".PNG"
			image.save_png(folder_path + "/%s" % f_name)
			
		img_dat.clear()
		
	print_rich("[color=green]Finished![/color]")
	
	
func _on_load_obj_pressed() -> void:
	file_load_obj.show()


func _on_file_load_obj_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
