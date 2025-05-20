extends Control

var folder_path: String
var selected_file: String

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

#TODO: Some images may have multiple images in them. See RC000.TXG.

func _process(_delta: float) -> void:
	if folder_path and selected_file:
		extract_arc()
		folder_path = ""
		selected_file = ""
		
		
func extract_arc() -> void:
	var f_name: String
	var f_start: int
	var f_offset: int
	var f_size: int
	var f_tbl: int
	var raw_tbl: int
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var off_tbl_buff: PackedByteArray
	var tbl_start: int
	var tbl_end: int
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	var temp_file: FileAccess = FileAccess.open(selected_file.get_base_dir() + "DIRLIST.BIN", FileAccess.READ)
	if temp_file == null:
		OS.alert("Could not find %s!" % selected_file.get_base_dir() + "DIRLIST.BIN")
		return
		
	print_rich("[color=yellow]Extracting...")
	
	off_tbl_buff = temp_file.get_buffer(temp_file.get_length())
	temp_file.close()
	
	var tbl_hdr_pos: int = 0
	var tbl_hdr_end: int = off_tbl_buff.decode_u32(0)
	while true:
		var kssg_tbl_off: int = off_tbl_buff.decode_u32(tbl_hdr_pos)
		if tbl_hdr_pos == tbl_hdr_end:
			break
		tbl_start = off_tbl_buff.decode_u32(kssg_tbl_off + 4)
		tbl_end = off_tbl_buff.decode_u32(kssg_tbl_off + 8) 
		
		tbl_start *= 0x800
		tbl_end *= 0x800
		
		var tbl_size: = tbl_end - tbl_start
		var pos: int = tbl_start
		while true:
			in_file.seek(pos)
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			if f_size == 0 and f_offset == 0:
				break
				
			f_offset = (f_offset * 0x800) + tbl_size + tbl_start
			f_name = in_file.get_buffer(16).get_string_from_ascii()
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			in_file.seek(f_offset)
			buff = in_file.get_buffer(f_size)
			
			out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			if f_name.get_extension().to_lower() == "txf" or f_name.get_extension().to_lower() == "txg":
				var png: Image = make_img(buff, f_name)
				png.save_png(folder_path + "/%s" % f_name + ".PNG")
			
			buff.clear()
			pos += 0x18
		tbl_hdr_pos += 4
	print_rich("[color=green]Finished![/color]")
	
	
func make_img(buff: PackedByteArray, f_name: String) -> Image:
	var type: int = buff.decode_u32(0x0)
	var pal_off: int
	var pal_size: int
	var pal: PackedByteArray
	var off_mod: int = 0
	
	if (
		f_name.contains("BB") or 
		f_name.contains("BC") or 
		f_name.contains("BE") or 
		#f_name.contains("RB") or
		f_name.contains("RC")
		):
		off_mod = (type << 3) + 8
		if !off_mod % 16 == 0:
			off_mod = (off_mod + 15) & ~15
		type = buff.decode_u32(off_mod)
		
	if type == 0 or type == 0x0100: # 4 bit
		pal_off = off_mod + 0x10
		pal_size = 0x40
		pal = buff.slice(pal_off, pal_off + pal_size)
	elif type == 1: # 8 bit
		pal_off = off_mod + 0x10
		pal_size = 0x400
		pal = ComFuncs.unswizzle_palette(buff.slice(pal_off, pal_off + pal_size), 32)
	elif type > 2:
		push_error("%s is an unknown image format!" % f_name)
		return Image.create_empty(1, 1, false,Image.FORMAT_L8)
		
	var w: int = buff.decode_u16(off_mod + 0xC)
	var h: int = buff.decode_u16(off_mod + 0xE)
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var img_dat: PackedByteArray = buff.slice(pal_size + pal_off)
	if pal_size == 0x400:
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	elif pal_size == 0x40:
		for i in range(pal.size()):
			var byte_val: int = img_dat[i]
			img_dat[i] = ((byte_val & 0x0F) << 4) | ((byte_val & 0xF0) >> 4)  
			# Swaps high and low nibbles
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[(x + y * w) >> 1]  # 2 pixels per byte
				if x % 2 == 0:
					pixel_index = (pixel_index >> 4) & 0xF  # Higher nibble
				else:
					pixel_index = pixel_index & 0xF         # Lower nibble
				var base_index: int = pixel_index * 4
				var r: int = pal[base_index + 0]
				var g: int = pal[base_index + 1]
				var b: int = pal[base_index + 2]
				var a: int = pal[base_index + 3]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	image.convert(Image.FORMAT_RGB8)
	return image
	


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_file_selected(path: String) -> void:
	selected_file = path
	file_load_folder.show()

func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
