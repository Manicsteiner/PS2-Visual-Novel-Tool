extends Node

@onready var load_bin: FileDialog = $LoadBIN
@onready var load_folder: FileDialog = $LoadFOLDER
@onready var load_exe: FileDialog = $LoadExe
@onready var debug_output_button: CheckBox = $VBoxContainer/DebugOutput



var folder_path: String
var selected_file: String
var elf_path: String
var debug_output: bool = false


func _ready() -> void:
	load_exe.filters = [
		"SLPM_657.17, SLPM_655.85, SLPM_550.98"
		]
		
		
func _process(_delta):
	if selected_file and folder_path:
		extract_cd_bin()
		folder_path = ""
		selected_file = ""


func extract_cd_bin() -> void:
	var in_file: FileAccess
	var exe_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var tbl_start: int
	var tbl_end: int
	var f_id: int
	var f_offset: int
	var f_size: int
	var f_name: String
	
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	exe_file = FileAccess.open(elf_path, FileAccess.READ)
	
	if elf_path.get_file() == "SLPM_550.98": # Koi suru Otome to Shugo no Tate: The Shield of AIGIS
		tbl_start = 0x45480
		tbl_end = 0x7D820
	elif elf_path.get_file() == "SLPM_655.85": # Princess Holiday - Korogaru Ringo Tei Sen'ya Ichiya
		tbl_start = 0x51A00
		tbl_end = 0x65DC8
	elif elf_path.get_file() == "SLPM_657.17": # Tsuki wa Higashi ni Hi wa Nishi ni - Operation Sanctuary
		tbl_start = 0x4A780
		tbl_end = 0x76188
	
	f_id = 0
	for pos: int in range(tbl_start, tbl_end, 8):
		exe_file.seek(pos)
		f_offset = exe_file.get_32() * 0x800
		f_size = (((exe_file.get_32() + 0x7FF) & 0xFFFFF800) + 0x3FF) & 0xFFFFFC00
		
		in_file.seek(f_offset)
		buff = in_file.get_buffer(f_size)
		
		if buff.slice(0, 4).get_string_from_ascii() == "1bin" or buff.slice(0, 4).get_string_from_ascii() == "1BIN":
			f_name = "%08d.1bin" % f_id
			buff = gplDataSgi(buff)
			if Main.game_type == Main.KOISURU and (f_id == 28074 or f_id == 28206 or f_id == 28249): # Packed images
				var num_files: int = buff.decode_u32(0)
				var mem_pos: int = 8
				for i: int in num_files:
					var mem_off: int = buff.decode_u32(mem_pos)
					var mem_size: int = buff.decode_u32(mem_pos + 4)
					var png: Image = make_img(buff.slice(mem_off, mem_off + mem_size))
					png.save_png(folder_path + "/%s" % f_name + "_%02d" % i + ".PNG")
					mem_pos += 8
		elif buff.slice(0, 4).get_string_from_ascii() == "1tex":
			f_name = "%08d.1tex" % f_id
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			buff = gplDataSgi(buff)
			if debug_output:
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			var png: Image = make_img(buff)
			png.save_png(folder_path + "/%s" % f_name + ".PNG")
			f_id += 1
			continue
		elif buff.decode_u32(0) == 0xBA010000:
			f_name = "%08d.pss" % f_id
		else:
			f_name = "%08d.BIN" % f_id
		
		out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
		out_file.store_buffer(buff)
		out_file.close()
		
		print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		f_id += 1
		
	print_rich("[color=green]Finished![/color]")
		
		
func gplDataSgi(input_data: PackedByteArray) -> PackedByteArray:
	var input_offset: int = 8
	var output_offset: int = 0
	var output_size: int = (input_data.decode_u8(4) << 24) | (input_data.decode_u8(5) << 16) | (input_data.decode_u8(6) << 8) | input_data.decode_u8(7)
	var output_data: PackedByteArray
	output_data.resize(output_size)
	
	while input_offset < input_data.size():
		var control: int = input_data.decode_s8(input_offset)
		input_offset += 1
		if control == 0:
			break
		
		if control > 0:  # Literal copy
			for _i in range(control):
				if input_offset >= input_data.size():
					break
				output_data.encode_s8(output_offset, input_data.decode_s8(input_offset))
				input_offset += 1
				output_offset += 1
		else:  # Back-reference copy
			if input_offset >= input_data.size():
				break
			var copy_offset: int = input_data.decode_u8(input_offset)
			input_offset += 1
			var copy_source: int = output_offset - copy_offset - 1
			for _i in range(2 - control):
				output_data.encode_s8(output_offset, output_data.decode_s8(copy_source))
				copy_source += 1
				output_offset += 1
	
	return output_data
	
	
func make_img(data: PackedByteArray) -> Image:
	var w: int = data.decode_u16(2)
	var h: int = data.decode_u16(4)
	var bpp: int = data.decode_u16(6)
	var img_size: int = data.decode_u32(0xC) << 8
	var pal_size: int = data.decode_u32(img_size + 0x2C) << 8
	
	if bpp != 8:
		print_rich("[color=red]Unknown BPP %02d!" % bpp)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGB8)
		
	var img_dat:PackedByteArray = data.slice(0x20, img_size + 0x20)
	var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(img_size + 0x40, img_size + 0x40 + pal_size), 32)
	
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		for x in range(w):
			var pixel_index: int = img_dat[x + y * w]
			var r: int = pal[pixel_index * 4 + 0]
			var g: int = pal[pixel_index * 4 + 1]
			var b: int = pal[pixel_index * 4 + 2]
			#var a: int = palette[pixel_index * 4 + 3]
			image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
	return image
	
	
func _on_load_folder_dir_selected(dir):
	folder_path = dir
	
	
func _on_load_cd_bin_file_pressed():
	if elf_path == "":
		OS.alert("EXE must be selected first.")
		return
		
	load_bin.show()
	
	
func _on_load_exe_pressed() -> void:
	load_exe.show()
	
	
func _on_load_exe_file_selected(path: String) -> void:
	elf_path = path
	
	
func _on_debug_output_pressed() -> void:
	debug_output = !debug_output


func _on_load_bin_file_selected(path: String) -> void:
	selected_file = path
	load_folder.show()
