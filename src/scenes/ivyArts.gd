extends Control

@onready var file_load_ipk: FileDialog = $FILELoadIPK
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var selected_ipk: String = ""
var folder_path: String = ""
var output_org_images: bool = false

func _ready() -> void:
	file_load_ipk.filters = ["*.IPK"]


func _process(_delta: float) -> void:
	if selected_ipk and folder_path:
		extract_ipk()
		selected_ipk = ""
		folder_path = ""
	

func extract_ipk() -> void:
	var in_file: FileAccess = FileAccess.open(selected_ipk, FileAccess.READ)
	var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
	if hdr != "IPK1":
		OS.alert("%s doesn't have a valid header! Expected 'IPK1' but got %s" % [selected_ipk, hdr])
		return
		
	var hdr_unk32: int = in_file.get_32()
	var num_files: int = in_file.get_32()
	var arc_size: int = in_file.get_32()
	
	var dir: DirAccess = DirAccess.open(folder_path)
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	for i in range(num_files):
		in_file.seek((i * 0x50) + 16)
		
		var f_name: String = ComFuncs.convert_jis_packed_byte_array(in_file.get_buffer(0x44), shift_jis_dic).get_string_from_utf8()
		#if !f_name.contains("staff00_BC.ivi"): continue
		var f_size: int = in_file.get_32()
		var f_off: int = in_file.get_32()
		var f_size2: int = in_file.get_32()
		
		if f_size != f_size2:
			print_rich("[color=red]Sizes don't match from file %s[/color]" % f_name)
			push_error("Sizes don't match from file %s" % f_name)
			
		in_file.seek(f_off)
		var buff: PackedByteArray = in_file.get_buffer(f_size)
		
		var full_name: String = "%s/%s" % [folder_path, f_name]
		print("%08X %08X %s" % [f_off, f_size, full_name])
		
		dir.make_dir_recursive(f_name.get_base_dir())
		
		if f_name.get_extension().to_lower() == "ivi":
			if output_org_images:
				var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			
			var png:= make_img_ivi(buff)
			png.save_png(full_name + ".PNG")
		else:
			var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
	print_rich("[color=green]Finished![/color]")
	
	
func make_img_ivi(data: PackedByteArray) -> Image:
	var hdr_size: int = 0x20
	var pal_off: int = data.decode_u32(4)
	var img_size: int = data.decode_u32(8)
	var img_dat_off: int = data.decode_u32(0x14)
	var flag_1: int = data.decode_u8(0x18)
	var flag_2: int = data.decode_u8(0x19)
	var w: int = data.decode_u16(0x1A)
	var h: int = data.decode_u16(0x1C)
	if flag_1 == 1:
		pal_off += hdr_size
		var img_dat: PackedByteArray = data.slice(pal_off, img_size - 16)
		return Image.create_from_data(w, h, false, Image.FORMAT_RGB8, img_dat)
	elif flag_1 == 0x13:
		img_dat_off += hdr_size
		pal_off += hdr_size
		
		w = data.decode_u16(img_dat_off + 10)
		h = data.decode_u16(img_dat_off + 12)
		
		var pal: PackedByteArray = data.slice(pal_off, img_dat_off)
		pal = ComFuncs.unswizzle_palette(pal, 32)
		img_dat_off += 16
		
		var img_dat: PackedByteArray = data.slice(img_dat_off, img_size - 16)
		
		var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		
		for i in range(0, 0x400, 4):
			var a: int = int((pal.decode_u8(i + 3) / 128.0) * 255.0)
			pal.encode_u8(i + 3, a)
		
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				img.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		return img
	elif flag_1 == 0:
		pal_off += hdr_size
		var img_dat: PackedByteArray = data.slice(pal_off, img_size - 16)
		return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, img_dat)
	elif flag_1 == 0x14:
		img_dat_off += hdr_size
		pal_off += hdr_size
		
		w = data.decode_u16(img_dat_off + 10)
		h = data.decode_u16(img_dat_off + 12)
		
		var pal: PackedByteArray = data.slice(pal_off, img_dat_off)
		img_dat_off += 16
		
		var img_dat: PackedByteArray = data.slice(img_dat_off, img_size - 16)
		
		var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		
		for i in range(0, 0x40, 4):
			var a: int = int((pal.decode_u8(i + 3) / 128.0) * 255.0)
			pal.encode_u8(i + 3, a)
		
		for y in range(h):
			for x in range(0, w, 2):  # Two pixels per byte
				var byte_index: int  = (x + y * w) / 2
				var byte_value: int  = img_dat[byte_index]

				# Extract two 4-bit indices (little-endian order)
				var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
				var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

				# Set first pixel
				var r1: int = pal[pixel_index_1 * 4 + 0]
				var g1: int = pal[pixel_index_1 * 4 + 1]
				var b1: int = pal[pixel_index_1 * 4 + 2]
				var a1: int = pal[pixel_index_1 * 4 + 3]
				img.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

				# Set second pixel (only if within bounds)
				if x + 1 < w:
					var r2: int = pal[pixel_index_2 * 4 + 0]
					var g2: int = pal[pixel_index_2 * 4 + 1]
					var b2: int = pal[pixel_index_2 * 4 + 2]
					var a2: int = pal[pixel_index_2 * 4 + 3]
					img.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
		return img
	else:
		push_error("Unknown flags %02X, %02X" % [flag_1, flag_2])
	return Image.create_empty(1, 1, false, Image.FORMAT_L8)
		
		
func _on_load_ipk_pressed() -> void:
	file_load_ipk.show()


func _on_file_load_ipk_file_selected(path: String) -> void:
	selected_ipk = path
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	output_org_images = !output_org_images
