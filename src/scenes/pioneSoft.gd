extends Control

@onready var pione_load_folder: FileDialog = $PIONELoadFOLDER
@onready var pione_load_saf: FileDialog = $PIONELoadSAF
@onready var load_exe: Button = $HBoxContainer/LoadEXE
@onready var pione_load_exe: FileDialog = $PIONELoadEXE


var chose_file:bool = false
var chose_folder:bool = false
var folder_path:String
var chose_saf:bool = false
var usr_files:PackedStringArray
var out_decomp:bool = false
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
	var file:FileAccess
	var new_file:FileAccess
	var file_size:int
	var file_name:String
	var pallete_data:PackedByteArray
	var image_data:PackedByteArray
	var new_pal:PackedByteArray
	var tga_header:PackedByteArray
	var final_image:PackedByteArray
	var palette_size: int
	var img_type: int
	var img_bpp_type: int #?
	var buff: PackedByteArray
	var width:int
	var height:int
	var has_palette:bool
	var bits_per_color:int
	var bpp:int
	var bit_depth:int
	var image_type:int
	var swap:PackedByteArray
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
			
			# dumb check for not putting Shift-JIS text in names because Godot does not support that encoding.
			if saf_type == 1:
				f_name = file.get_line()
			elif saf_type == 2:
				f_name = str(saf_files)
				
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
					
				img_bpp_type = buff.decode_u8(2)
				img_type = buff.decode_u8(3)
				if img_bpp_type == 0x51 and img_type == 0x14:
					print_rich("[color=yellow]Skipping %s as image bpp %02X and image type %02X are unsupported.[/color]" % [f_name, img_bpp_type, img_type])
					continue
					
				width = buff.decode_u16(0xC)
				height = buff.decode_u16(0xE)
				if img_type == 0x13:
					width = (width + 7) >> 3 << 19 >> 16
				elif img_type == 0x14:
					width = (width + 0xF) >> 4 << 20 >> 16
				elif img_type == 2:
					width = (width + 3) >> 2 << 18 >> 16
					
				# Not sure what to do about the smaller palettes
				if img_bpp_type == 0x53 & 2:
					palette_size = 0x400
				elif img_bpp_type == 0x51 & 2:
					palette_size = 0x40
					
				if width == 24 and height == 22:
					print_rich("[color=yellow]Skipping %s I have no clue what these are[/color]" % f_name)
					continue
					
				pallete_data = ComFuncs.unswizzle_palette(buff.slice(0x10, 0x410), 32)
				image_data = buff.slice(0x410)
				
				swap.resize(4)
				for j in range(0, pallete_data.size(), 4):
					swap[0] = pallete_data.decode_u8(j)
					swap[1] = pallete_data.decode_u8(j + 1)
					swap[2] = pallete_data.decode_u8(j + 2)
					pallete_data.encode_u8(j, swap[2])
					pallete_data.encode_u8(j + 1, swap[1])
					pallete_data.encode_u8(j + 2, swap[0])
					
				has_palette = true
				bits_per_color = 32
				bpp = 8
				image_type = 1
			
				tga_header = ComFuncs.makeTGAHeader(has_palette, image_type, bits_per_color, bpp, width, height)
				final_image.append_array(tga_header)
				final_image.append_array(pallete_data)
				final_image.append_array(image_data)
				
				tga_header.clear()
				image_data.clear()
				pallete_data.clear()
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name + ".TGA", FileAccess.WRITE)
				out_file.store_buffer(final_image)
				out_file.close()
				final_image.clear()
				buff.clear()
				
				print("0x%08X " % f_offset, "0x%08X " % dec_size + "0x%02X " % img_type + "0x%02X " % img_bpp_type + "%s" % folder_path + "/%s" % f_name)
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
			
				print("0x%08X " % f_offset, "0x%08X " % dec_size + "%s" % folder_path + "/%s" % f_name)
		
		
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
	
	print("0x%08X " % saf_off, "0x%08X " % saf_size + "%s" % folder_path + "/%s" % script_saf_name)
	print_rich("[color=green]Finished![/color]")
	
	
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
	
