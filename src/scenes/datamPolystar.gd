extends Control

@onready var file_load_image: FileDialog = $FILELoadIMAGE
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var remove_alpha: bool = true


func _process(_delta: float) -> void:
	if selected_files and folder_path:
		convertImages()
		selected_files.clear()
		folder_path = ""
		

func convertImages() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var f_ext: String
	var width: int
	var height: int
	var bpp: int
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		f_name = selected_files[i].get_file()
		f_ext = selected_files[i].get_extension()
		
		buff = in_file.get_buffer(in_file.get_length())
		if buff.slice(0, 8).get_string_from_ascii() == "[image2]":
			width = buff.decode_u16(0x08)
			height = buff.decode_u16(0x0C)
			bpp = 32
			
			if (Main.game_type == Main.NORTHWIND or 
			Main.game_type == Main.PUREPURE or 
			Main.game_type == Main.DOUBLEREACTION or
			Main.game_type == Main.SOSHITEKONO or 
			Main.game_type == Main.SOSHITEKONOXXX) and f_ext == "ps2":
				var file_type: int = buff.decode_u32(0x10)
				buff = buff.slice(0x20)
				
				if file_type == 3:
					bpp = 16
				elif file_type == 2:
					bpp = 8
			else:
				buff = buff.slice(0x10)
				
			var png: Image = make_img(buff, width, height, bpp)
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			
			print("%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
		elif f_ext == "psi" or f_ext == "p16":
			width = buff.decode_u16(0)
			height = buff.decode_u16(2)
			bpp = buff.decode_u16(4)
			
			buff = buff.slice(0x800)
			var png: Image = make_img(buff, width, height, bpp)
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			
			print("%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
		else:
			print("Invalid header in %s. Expected '[image2]'" % f_name)
			continue
		
	print_rich("[color=green]Finished![/color]")


func make_img(buff: PackedByteArray, width: int, height: int, bpp: int) -> Image:
	var png: Image
	if bpp == 8:
		png = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		var pal: PackedByteArray = buff.slice(0, 0x400)
		var img_dat: PackedByteArray = buff.slice(0x400)
		for y in range(height):
			for x in range(width):
				var pixel_index: int = img_dat[x + y * width]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				png.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
	elif bpp == 16:
		buff = buff.slice(0, width * height * 2)
		png = ComFuncs.convert_rgb555_to_image(buff, width, height, true)
	elif bpp == 32:
		buff = buff.slice(0, width * height * 4)
		png = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
	else:
		push_error("Unsupported BPP %02d!" % bpp)
		return Image.create_empty(1, 1, false, Image.FORMAT_L8)
		
	if remove_alpha:
		png.convert(Image.FORMAT_RGB8)
	return png
	
	
func _on_load_image_pressed() -> void:
	file_load_image.visible = true


func _on_file_load_image_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
