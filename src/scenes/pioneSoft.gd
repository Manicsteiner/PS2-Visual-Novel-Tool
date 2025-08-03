extends Control

@onready var pione_load_folder: FileDialog = $PIONELoadFOLDER
@onready var pione_load_saf: FileDialog = $PIONELoadSAF
@onready var load_exe: Button = $HBoxContainer/LoadEXE
@onready var pione_load_exe: FileDialog = $PIONELoadEXE


var chose_file: bool = false
var chose_folder: bool = false
var folder_path: String
var chose_saf: bool = false
var usr_files: PackedStringArray
var fix_alpha: bool = true
var out_decomp: bool = false
var exe_path: String = ""

func _ready() -> void:
	if Main.game_type == Main.ORANGEPOCKET:
		load_exe.visible = true
	else:
		load_exe.visible = false
		
	
func _process(_delta):
	if chose_saf and chose_folder:
		makeFiles()
		usr_files.clear()
		chose_folder = false
		chose_saf = false
		exe_path = ""
	elif exe_path and chose_folder:
		extractFromExe()
		usr_files.clear()
		chose_folder = false
		chose_saf = false
		exe_path = ""
		
	
func makeFiles() -> void:
	var file: FileAccess
	var new_file: FileAccess
	var file_name: String
	var img_type: int
	var img_bpp_type: int
	var buff: PackedByteArray
	var num_files: int
	var f_name: String
	var f_size: int
	var f_offset: int
	var dec_size: int
	var unk32: int
	var out_file: FileAccess
	var saf_type: int
	var saf_file_tbl_size: int
	var ext: String
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	
	# TODO: Proper zlib decompression.
	
	for i in range(0, usr_files.size()):
		file = FileAccess.open(usr_files[i], FileAccess.READ)
		file_name = usr_files[i].get_file()
		if file.get_32() != 0x30464153:
			OS.alert("Invalid SAF archive %s" % file_name)
			file.close()
			continue
			
		saf_type = file.get_32()
		if saf_type == 1:
			saf_file_tbl_size = 0x20
		elif saf_type == 2:
			saf_file_tbl_size = 0x30
		else:
			OS.alert("Unknown SAF type %04X" % saf_type)
			file.close()
			continue
			
		file.seek(0xC)
		num_files = file.get_32()
		for saf_files in range(0, num_files):
			file.seek((saf_files * saf_file_tbl_size) + 0x10)
			unk32 = file.get_32()
			f_offset = file.get_32()
			f_size = file.get_32()
			dec_size = file.get_32()
			f_name = ComFuncs.convert_jis_packed_byte_array(ComFuncs.find_end_bytes_file(file, 0)[1], shift_jis_dic).get_string_from_utf8()
			
			file.seek(f_offset)
			if f_size != dec_size:
				buff = ComFuncs.decompress_raw_zlib(file.get_buffer(f_size), dec_size, true)
			else:
				buff = file.get_buffer(f_size)
			
			# for images
			if buff.decode_u16(0) == 0x3254:
				if out_decomp:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				var png: Image = make_image(buff)
				png.save_png(folder_path + "/%s" % f_name + ".PNG")
				
				print("%08X " % f_offset, "%08X " % dec_size + "%02X " % img_type + "%02X " % img_bpp_type + "%s" % folder_path + "/%s" % f_name)
			else:
				if buff.decode_u32(0) == 0x324D4954:
					ext = ".TM2"
				elif buff.decode_u32(0) == 0x30464153:
					ext = ".SAF"
				else:
					ext = ".BIN"
					
				out_file = FileAccess.open(folder_path + "/%s" % f_name + ext, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				buff.clear()
			
				print("%08X " % f_offset, "%08X " % dec_size + "%s" % folder_path + "/%s" % f_name)
		
		
	print_rich("[color=green]Finished![/color]")


func extractFromExe() -> void:
	# Extract unused scripts that is likely from another game
	
	var script_saf_name: String = "SCRIPT.SAF"
	var saf_off: int = 0x0013A6A0
	var out_file: FileAccess
	var file: FileAccess
	var saf_size: int
	var buff: PackedByteArray
	
	file = FileAccess.open(exe_path, FileAccess.READ)
	
	file.seek(saf_off + 0x8)
	saf_size = file.get_32()
	file.seek(saf_off)
	buff = file.get_buffer(saf_size)
	
	file.close()
	
	out_file = FileAccess.open(folder_path + "/%s" % script_saf_name, FileAccess.WRITE)
	out_file.store_buffer(buff)
	out_file.close()
	buff.clear()
	
	print("%08X " % saf_off, "%08X " % saf_size + "%s" % folder_path + "/%s" % script_saf_name)
	print_rich("[color=green]Finished![/color]")
	
	
func make_image(data: PackedByteArray) -> Image:
	var img_bpp_type: int = data.decode_u8(2)
	var img_type: int = data.decode_u8(3)
	var image_width: int = data.decode_u16(0xC) & 0xFFF
	var image_height: int = data.decode_u16(0xE) & 0xFFF
	var palette_size: int
	
	if img_type == 0x13:
		image_width = (image_width + 7) >> 3 << 19 >> 16
	elif img_type == 0x14:
		image_width = (image_width + 0xF) >> 4 << 20 >> 16
	elif img_type == 2:
		image_width = (image_width + 3) >> 2 << 18 >> 16
		
	if img_bpp_type & 1 == 1:
		palette_size = 0x400
		if img_bpp_type & 2 == 0: palette_size = 0x40
		
	if (image_width * image_height) + palette_size + 0x10 != data.size(): # Safety check if zlib decompression messes up
		print_rich("[color=red]Image decompression likely failed. Expected: %08X, but got: %08X[/color]" % [(image_width * image_height) + palette_size + 0x10, data.size()])
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
		
	var palette_offset: int = 0x10
	var palette: PackedByteArray = PackedByteArray()
	for i in range(0, palette_size):
		palette.append(data.decode_u8(palette_offset + i))

	palette = ComFuncs.unswizzle_palette(palette, 32)
	if fix_alpha:
		for i in range(0, palette_size, 4):
			palette.encode_u8(i + 3, int((palette.decode_u8(i + 3) / 128.0) * 255.0))

	# Extract raw pixel data
	var image_data_offset: int = palette_offset + 0x400
	var pixel_data: PackedByteArray = data.slice(image_data_offset, image_data_offset + image_width * image_height)

	# Create the image object
	var image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)

	# Process the pixel data and apply the palette
	for y in range(image_height):
		for x in range(image_width):
			var pixel_index: int = pixel_data[x + y * image_width]
			var r: int = palette[pixel_index * 4 + 0]
			var g: int = palette[pixel_index * 4 + 1]
			var b: int = palette[pixel_index * 4 + 2]
			var a: int = palette[pixel_index * 4 + 3]
			image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))

	return image
	
	
func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp


func _on_load_saf_pressed() -> void:
	pione_load_saf.visible = true
	
	
func _on_pione_load_folder_dir_selected(dir):
	folder_path = dir
	chose_folder = true
	
	
func _on_pione_load_saf_files_selected(paths):
	pione_load_saf.visible = false
	pione_load_folder.visible = true
	usr_files = paths
	chose_saf = true


func _on_load_exe_pressed() -> void:
	pione_load_exe.visible = true


func _on_pione_load_exe_file_selected(path: String) -> void:
	pione_load_exe.visible = false
	pione_load_folder.visible = true
	exe_path = path


func _on_fix_alpha_toggled(_toggled_on: bool) -> void:
	fix_alpha = !fix_alpha
