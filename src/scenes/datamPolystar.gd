extends Control

@onready var file_load_image: FileDialog = $FILELoadIMAGE
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path:String
var selected_files: PackedStringArray
var chose_files: bool = false
var chose_folder: bool = false
var remove_alpha: bool = false


func _process(_delta: float) -> void:
	if chose_files and chose_folder:
		convertImages()
		selected_files.clear()
		chose_files = false
		chose_folder = false
		

func convertImages() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var tga_header: PackedByteArray
	var swap: PackedByteArray
	var f_size: int
	var f_ext: String
	var width: int
	var height: int
	var bpp: int
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		f_name = selected_files[i].get_file()
		f_ext = selected_files[i].get_extension()
		
		buff = in_file.get_buffer(in_file.get_length())
		var bytes: int = buff.decode_u64(0)
		if bytes == 0x5D326567616D695B: # [image2]
			width = buff.decode_u16(0x08)
			height = buff.decode_u16(0x0C) - 1 #???
			var has_pal: bool = false
			var img_type: int = 2
			var file_type: int 
			var bits_per_color: int = 32
			bpp = 32
			
			if (Main.game_type == Main.NORTHWIND or Main.game_type == Main.PUREPURE) and f_ext == "ps2":
				file_type = buff.decode_u32(0x10)
				buff = buff.slice(0x20)
				
				if file_type == 3:
					bpp = 16
					buff = ComFuncs.convert_palette16_bgr_to_rgb(buff)
					tga_header = ComFuncs.makeTGAHeader(has_pal, img_type, bits_per_color, bpp, width, height)
					tga_header.append_array(buff)
					
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
					out_file.store_buffer(tga_header)
					out_file.close()
					
					print("0x%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
					buff.clear()
					tga_header.clear()
					continue
				elif file_type == 2:
					bpp = 8
					has_pal = true
					img_type = 1
					
					var pal: PackedByteArray = buff.slice(0, 0x400)
					buff = buff.slice(0x400)
					
					tga_header = ComFuncs.makeTGAHeader(has_pal, img_type, bits_per_color, bpp, width, height)
					tga_header.append_array(pal)
					tga_header.append_array(buff)
					
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
					out_file.store_buffer(tga_header)
					out_file.close()
					
					print("0x%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
					buff.clear()
					tga_header.clear()
					continue
			else:
				buff = buff.slice(0x10)
				
			#buff = ComFuncs.rgba_to_bgra(buff)
			if remove_alpha:
				for a in range(0, buff.size(), 4):
					buff.encode_u8(a + 3, 0xFF)
					
			var png: Image = Image.create_from_data(width, height + 1, false, Image.FORMAT_RGBA8, buff)
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			
			print("0x%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
			
			buff.clear()
			#tga_header = ComFuncs.makeTGAHeader(has_pal, img_type, bits_per_color, bpp, width, height)
			#tga_header.append_array(buff)
			#
			#out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
			#out_file.store_buffer(tga_header)
			#out_file.close()
			#
			#print("0x%08X %s/%s" % [buff.size(), folder_path, f_name])
			#buff.clear()
			#tga_header.clear()
		elif f_ext == "psi" or f_ext == "p16":
			width = buff.decode_u16(0)
			height = buff.decode_u16(2)
			bpp = buff.decode_u16(4)
			
			buff = buff.slice(0x800)
			if bpp == 16:
				buff = ComFuncs.convert_palette16_bgr_to_rgb(buff)
			elif bpp == 32:
				buff = ComFuncs.rgba_to_bgra(buff)
				
				if remove_alpha:
					for a in range(0, buff.size(), 4):
						buff.encode_u8(a + 3, 0xFF)
			else:
				print("Unsupported BPP %02d in %s!" % [bpp, f_name])
				buff.clear()
				continue
				
			tga_header = ComFuncs.makeTGAHeader(false, 2, bpp, bpp, width, height)
			tga_header.append_array(buff)
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
			out_file.store_buffer(tga_header)
			out_file.close()
			
			print("0x%08X %02d %s/%s" % [buff.size(), bpp, folder_path, f_name])
			buff.clear()
			tga_header.clear()
		else:
			print("Invalid header in %s. Expected '[image2]'" % f_name)
			buff.clear()
			continue
		
	print_rich("[color=green]Finished![/color]")


func _on_load_image_pressed() -> void:
	file_load_image.visible = true


func _on_file_load_image_files_selected(paths: PackedStringArray) -> void:
	file_load_image.visible = false
	file_load_folder.visible = true
	selected_files = paths
	chose_files = true


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir


func _on_remove_alpha_button_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
