extends Control

@onready var file_load_gsl: FileDialog = $FILELoadGSL
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_bin: FileDialog = $FILELoadBIN

var folder_path:String
var selected_files: PackedStringArray
var chose_files: bool = false
var chose_bins: bool = false
var chose_folder: bool = false
var remove_alpha: bool = false


func _process(_delta: float) -> void:
	if chose_files and chose_folder:
		convertGSL()
		selected_files.clear()
		chose_files = false
		chose_folder = false
	elif chose_bins and chose_folder:
		extractBin()
		selected_files.clear()
		chose_bins = false
		chose_folder = false
		
func convertGSL() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var f_name: String
	var f_size: int
	var tga_header: PackedByteArray
	var tga_img: PackedByteArray
	var swap: PackedByteArray
	var width: int
	var height: int
	var bpp: int
	var pal_dat: PackedByteArray
	var pal_size: int
	var pal_start: int
	var img_size: int
	var img_dats: Array[PackedByteArray]
	var pos: int
	
	# Some images are 4bit and currently not supported
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		f_name = selected_files[i].get_file()
		f_size = in_file.get_length()
		#var ext: String = selected_files[i].get_extension()
		
		#if f_size % 16 == 0:
			#push_error("Unsupported 4 bit image in %s!" % f_name)
			#in_file.close()
			#continue
			
		img_size = 0
		var marker: int = 0
		pos = 0
		
		while true:
			in_file.seek(pos)
			img_size = (in_file.get_16() << 4) - 0x60
			in_file.seek(pos + 3)
			
			marker = in_file.get_8()
			if marker == 0x70:
				break
				
			in_file.seek(pos + 0x70)
			img_dats.append(in_file.get_buffer(img_size))
			pos = in_file.get_position()
		
		pos = in_file.get_position() - 4
		var final_img: PackedByteArray
		
		for img in range(img_dats.size()):
			final_img.append_array(img_dats[img])
			
		pal_dat = img_dats[img_dats.size() - 1]
		pal_dat = ComFuncs.unswizzle_palette(pal_dat, 32)
		pal_dat = ComFuncs.rgba_to_bgra(pal_dat)

		
		in_file.seek(pos + 0x3C)
		width = in_file.get_16()
		height = in_file.get_16()
		
		tga_header = ComFuncs.makeTGAHeader(true, 1, 32, 8, width, height)
		tga_header.append_array(pal_dat)
		tga_header.append_array(final_img)
		
		out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
		out_file.store_buffer(tga_header)
		out_file.close()
		
		pal_dat.clear()
		final_img.clear()
		tga_header.clear()
		img_dats.clear()
		
		print("0x%08X %s/%s" % [f_size, folder_path, f_name])
		
		in_file.close()
		
	print_rich("[color=green]Finished![/color]")
		

func extractBin() -> void:
	var in_file: FileAccess
	var in_file_size: int
	var out_file: FileAccess
	var f_name: String
	var f_offset: int
	var f_size: int
	var pos: int
	var files: int
	var buff: PackedByteArray
	
	for i in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[i], FileAccess.READ)
		f_name = selected_files[i].get_file()
		in_file_size = in_file.get_length()
		
		f_offset = in_file.get_32()
		f_size = in_file.get_32()
		if f_offset > in_file_size:
			print("%s does not contain .GSLs" % f_name)
			in_file.close()
			continue
				
		pos = 0
		files = 0
		while true:
			in_file.seek(pos)
			f_offset = in_file.get_32()
			f_size = in_file.get_32() - f_offset
			if f_offset == 0 or f_size < 0:
				break
				
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name + "_%02d" % files + ".GSL", FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			files += 1
			pos += 4
			
			print("%08X %08X " % [f_offset, f_size] + folder_path + "/%s" % f_name + "_%02d" % files + ".GSL")
			
	
func _on_load_gsl_pressed() -> void:
	file_load_gsl.visible = true


func _on_file_load_gsl_files_selected(paths: PackedStringArray) -> void:
	file_load_gsl.visible = false
	file_load_folder.visible = true
	selected_files = paths
	chose_files = true


func _on_file_load_folder_dir_selected(dir: String) -> void:
	file_load_folder.visible = false
	chose_folder = true
	folder_path = dir


func _on_load_bin_pressed() -> void:
	file_load_bin.visible = true


func _on_file_load_bin_files_selected(paths: PackedStringArray) -> void:
	file_load_bin.visible = false
	file_load_folder.visible = true
	selected_files = paths
	chose_bins = true
