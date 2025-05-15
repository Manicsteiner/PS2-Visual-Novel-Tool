extends Control

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_gim: FileDialog = $FILELoadGIM

var folder_path: String
var selected_files: PackedStringArray
var selected_gims: PackedStringArray
var out_org_gim: bool = false


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		selected_gims.clear()
	elif folder_path and selected_gims:
		convert_gim()
		folder_path = ""
		selected_files.clear()
		selected_gims.clear()
		

func extract_arc() -> void:
	var f_name: String
	var f_offset: int
	var f_size: int
	var num_files: int
	var name_files: int
	var name_cnt: int
	var in_file: FileAccess
	var tbl_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	
	for file in range(selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		tbl_file = FileAccess.open(selected_files[file].get_basename() + ".TBL", FileAccess.READ)
		if tbl_file == null:
			OS.alert("Could not find %s for %s!" % [selected_files[file].get_basename() + ".TBL", selected_files[file].get_file()])
			continue
			
		num_files = tbl_file.get_32()
		name_files = tbl_file.get_32()
		name_cnt = 0
		
		tbl_file.seek(8)
		for pos in num_files:
			in_file.seek(pos * 8)
			
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			
			f_name = tbl_file.get_line()
			if name_cnt == name_files:
				tbl_file.seek((((tbl_file.get_position() + 15)) & ~15) + 4)
				name_files = tbl_file.get_32()
				f_name = tbl_file.get_line()
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			name_cnt += 1
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			if buff.slice(0, 3).get_string_from_ascii() == "MIG":
				var image: Image = gim_parse(buff)
				image.save_png(folder_path + "/%s" % f_name + ".PNG")
				if out_org_gim:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				continue
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
	
	print_rich("[color=green]Finished![/color]")
	
func convert_gim() -> void:
	var f_name: String 
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	
	for file in range(selected_gims.size()):
		in_file = FileAccess.open(selected_gims[file], FileAccess.READ)
		f_name = selected_gims[file].get_file().get_basename() + ".PNG"
		buff = in_file.get_buffer(in_file.get_length())
		var image: Image = gim_parse(buff)
		image.save_png(folder_path + "/%s" % f_name)
		
		print("%s/%s" % [folder_path, f_name])
	
	print_rich("[color=green]Finished![/color]")
	
	
func gim_parse(buff: PackedByteArray) -> Image:
	var width: int
	var height: int
	var bpp: int
	var image: Image
	var pal: PackedByteArray
	var img_dat: PackedByteArray
	var img_dat_size: int
	var img_start_off: int
	var pal_size: int
	var pal_start_off: int
	
	bpp = buff.decode_u16(0x4C)
	width = (((buff.decode_u16(0x48) * bpp) + 0x7F) & 0xFFFFFF80) >> 3
	height = buff.decode_u16(0x4A)
	if bpp != 8:
		push_error("Unknown BPP %X in image!" % bpp)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		
	# Probably some other way to do this
	img_dat_size = buff.decode_u32(0x60)
	pal_size = buff.decode_u32(0x40 + img_dat_size + 0x30) - 0x40
	img_start_off = 0x80
	pal_start_off = 0x40 + img_dat_size + 0x50
	if img_dat_size == 0x440: 
		img_dat_size = buff.decode_u32(0x40 + img_dat_size + 0x30)
		pal_size = buff.decode_u32(0x60) - 0x40
		img_start_off = 0x40 + img_dat_size + 0x50
		pal_start_off = 0x80
	
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	if bpp == 8:
		img_dat = buff.slice(img_start_off, img_start_off + img_dat_size)
		pal = buff.slice(pal_start_off, pal_start_off + pal_size)
		if pal_size == 0x400:
			for y in range(height):
				for x in range(width):
					var pixel_index: int = img_dat[x + y * width]
					var r: int = pal[pixel_index * 4 + 0]
					var g: int = pal[pixel_index * 4 + 1]
					var b: int = pal[pixel_index * 4 + 2]
					var a: int = pal[pixel_index * 4 + 3]
					image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	return image
			


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_org_gim_toggled(_toggled_on: bool) -> void:
	out_org_gim = !out_org_gim


func _on_load_gim_pressed() -> void:
	file_load_gim.show()


func _on_file_load_gim_files_selected(paths: PackedStringArray) -> void:
	selected_gims = paths
	file_load_folder.show()
