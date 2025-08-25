extends Node

@onready var load_bin: FileDialog = $LoadBIN
@onready var load_folder: FileDialog = $LoadFOLDER
@onready var load_exe: FileDialog = $LoadExe
@onready var load_image: FileDialog = $LoadIMAGE
@onready var debug_output_button: CheckBox = $VBoxContainer/DebugOutput
@onready var remove_alpha_1: CheckBox = $VBoxContainer/RemoveAlpha1
@onready var remove_alpha_2: CheckBox = $VBoxContainer/RemoveAlpha2
@onready var load_exe_button: Button = $HBoxContainer/LoadExe
@onready var load_cd_bin_file: Button = $HBoxContainer/LoadCdBinFile
@onready var tiled_output: CheckBox = $VBoxContainer/TiledOutput
@onready var load_image_button: Button = $HBoxContainer/LoadImage
@onready var load_databin: FileDialog = $LoadDATABIN
@onready var load_databin_button: Button = $HBoxContainer/LoadDatabin
@onready var load_biz: Button = $HBoxContainer/LoadBiz
@onready var load_biz_file: FileDialog = $LoadBIZ
@onready var load_hfu_2bin: FileDialog = $LoadHFU2BIN
@onready var load_hfu_2_button: Button = $HBoxContainer/LoadHFU2Bin


var folder_path: String
var selected_file: String
var selected_bizs: PackedStringArray
var selected_hfu2s: PackedStringArray
var selected_imgs: PackedStringArray
var data_bin_path: String
var exe_path: String
var debug_output: bool = false
var tile_output: bool = false
var remove_alpha: bool = true
var keep_alpha_char: bool = false

var type2_game_types: PackedInt32Array = [
	Main.RAMUNE, Main.FATESTAY, 
	Main.HARUNOASHIOTO, Main.ONETWENTYYEN,
	Main.SCARLETNICHIJOU, Main.MAPLECOLORS,
	Main.SUZUNONE, Main.SEKIREI,
	Main.KOMOREBI
	]
var type3_game_types: PackedInt32Array = [
	Main.IZUMO2TAKEKI, Main.IZAYOI
	]
var type4_game_types: PackedInt32Array = [
	Main.CANARIA, Main.MIZUIRO, Main.THREADCOLORS, 
	Main.WIND
	]

#TODO: Image DATA2.BIN_00000016.MF_00003280.MF, DATA2.BIN_00000016.MF_00005021.MF in Fate Stay Night

func _ready() -> void:
	load_exe.filters = [
		"SLPM_657.17, SLPM_655.85, SLPM_655.45, SLPM_550.98, SLPM_661.65, SLPM_664.37, SLPM_661.92, MAIN.ELF"
		]
		
	if Main.game_type in type2_game_types:
		load_exe_button.hide()
		load_cd_bin_file.hide()
		debug_output_button.hide()
		load_biz.hide()
		if Main.game_type != Main.KOMOREBI:
			load_hfu_2_button.hide()
	elif Main.game_type in type3_game_types:
		remove_alpha_1.hide()
		remove_alpha_2.hide()
		load_image_button.hide()
		load_databin_button.hide()
		load_cd_bin_file.hide()
		load_hfu_2_button.hide()
	elif Main.game_type in type4_game_types:
		remove_alpha_1.hide()
		remove_alpha_2.hide()
		load_image_button.hide()
		load_databin_button.hide()
		load_cd_bin_file.hide()
		load_exe_button.hide()
		load_biz.hide()
	elif Main.game_type not in type2_game_types:
		remove_alpha_1.hide()
		remove_alpha_2.hide()
		tiled_output.hide()
		load_image_button.hide()
		load_databin_button.hide()
		load_biz.hide()
		load_hfu_2_button.hide()
		
		
func _process(_delta):
	if selected_file and folder_path:
		extract_cd_bin()
		_clear_strings()
	elif selected_bizs and folder_path:
		extract_biz()
		_clear_strings()
	elif data_bin_path and folder_path:
		extract_mf_uffa()
		_clear_strings()
	elif selected_hfu2s and folder_path:
		extract_hfu2_pack()
		_clear_strings()
	elif selected_imgs and folder_path:
		convert_imgs()
		_clear_strings()


func _clear_strings() -> void:
	folder_path = ""
	selected_file = ""
	selected_imgs.clear()
	data_bin_path = ""
	selected_bizs.clear()
	selected_hfu2s.clear()
	return
	
	
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
	exe_file = FileAccess.open(exe_path, FileAccess.READ)
	
	if exe_path.get_file() == "SLPM_550.98": # Koi suru Otome to Shugo no Tate: The Shield of AIGIS
		tbl_start = 0x45480
		tbl_end = 0x7D820
	elif exe_path.get_file() == "SLPM_655.85": # Princess Holiday - Korogaru Ringo Tei Sen'ya Ichiya
		tbl_start = 0x51A00
		tbl_end = 0x65DC8
	elif exe_path.get_file() == "SLPM_657.17": # Tsuki wa Higashi ni Hi wa Nishi ni - Operation Sanctuary
		tbl_start = 0x4A780
		tbl_end = 0x76188
	elif exe_path.get_file() == "SLPM_661.65": # Otome wa Boku ni Koishiteru
		tbl_start = 0x4B800
		tbl_end = 0x6C768
	elif exe_path.get_file() == "SLPM_664.37": # Soul Link Extension
		tbl_start = 0x56200
		tbl_end = 0x6B5C0
	elif exe_path.get_file() == "MAIN.ELF": # Tsuki wa Higashi ni Hi wa Nishi ni - Operation Sanctuary (Dengeki D73 demo)
		tbl_start = 0x60810
		tbl_end = 0x61378
	
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
	
	
func extract_mf_uffa() -> void:
	const BUFFER_SIZE = 8 * 1024 * 1024
	
	var in_file: FileAccess = FileAccess.open(data_bin_path, FileAccess.READ)
	var f_name: String = data_bin_path.get_file()
	var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
	
	if hdr == "MF":
		var ext: String = "BIN"
		
		in_file.seek(4)
		var num_files: int = in_file.get_32()
		var base_off: int = in_file.get_32()
		var mf_pos: int = 0x10
		var uffa_id: int = 0
		for mf_i in range(num_files):
			in_file.seek(mf_pos)
			var f_comp_size: int = in_file.get_32()
			var f_offset: int = in_file.get_32()
			var is_comp: bool = in_file.get_32()
			var f_size: int = in_file.get_32()
			mf_pos += 0x10
			if Main.game_type != Main.KOMOREBI and (f_offset == 0 or f_size == 0):
				continue
			
			if is_comp:
				in_file.seek(f_offset)
				var buff: PackedByteArray = in_file.get_buffer(f_comp_size)
				
				in_file.seek(f_offset + 8)
				f_size = in_file.get_32()
				
				in_file.seek(f_offset + 16)
				buff = ComFuncs.decompLZSS(buff.slice(16), f_comp_size - 16, f_size)
				if buff.decode_u32(0) == 0x0000464D:
					ext = "MF"
					
				uffa_id += 1
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [mf_i, ext], FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			else:
				if Main.game_type == Main.KOMOREBI: f_size = f_comp_size
				in_file.seek(f_offset)
				var hdr_bytes: int = in_file.get_32()
				in_file.seek(f_offset)
				var hdr_arr: PackedByteArray = in_file.get_buffer(16)
				var is_adpcm: bool = true
				for b in hdr_arr:
					if b != 0:
						is_adpcm = false
						break
				if hdr_bytes == 0xBA010000:
					ext = "PSS"
				elif hdr_bytes == 0x0000464D:
					ext = "MF"
				elif hdr_bytes == 0x32554648:
					ext = "HFU2"
				elif is_adpcm:
					ext = "ADPCM"
				else:
					ext = "BIN"
					
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [mf_i, ext], FileAccess.WRITE)
				in_file.seek(f_offset)
				while in_file.get_position() < f_offset + f_size:
					var read_size: int = min(BUFFER_SIZE, (f_offset + f_size) - in_file.get_position())
					var buff: PackedByteArray = in_file.get_buffer(read_size)
					out_file.store_buffer(buff)
				out_file.close()
				
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name + "_%04d.%s" % [mf_i, ext]])
	else:
		print_rich("[color=red]%s does not have a valid header!" % f_name)
	print_rich("[color=green]Finished![/color]")
	
	
func extract_hfu2_pack() -> void:
	#TODO: Images in SYSDAT.BIN from Canaria seem to have hardcoded dimensions
	#TODO: Komorebi DATA0019 contains early format type 2 image data
	
	const BUFFER_SIZE = 8 * 1024 * 1024
	
	for file in selected_hfu2s.size():
		var in_file: FileAccess = FileAccess.open(selected_hfu2s[file], FileAccess.READ)
		var f_name: String = selected_hfu2s[file].get_file()
		var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
		
		if hdr == "HFU2":
			var ext: String = "BIN"
			
			in_file.seek(4)
			var num_files: int = in_file.get_32()
			var base_off: int = in_file.get_32()
			var hfu_pos: int = 0x10
			var hfu_id: int = 0
			for hfu_i in range(num_files):
				in_file.seek(hfu_pos)
				var f_offset: int = in_file.get_32() + base_off
				var f_comp_size: int = in_file.get_32()
				var f_dec_size: int = in_file.get_32()
				var f_crc: int = in_file.get_32()
				hfu_pos += 0x10
				
				if f_comp_size == 0:
					continue
					
				#if hfu_i != 4:
					#continue
					
				var buff: PackedByteArray
				var is_comp: bool = false
				
				if f_comp_size != f_dec_size:
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_comp_size)
					f_comp_size = buff.decode_u32(4)
					f_dec_size = buff.decode_u32(8)
					buff = ComFuncs.decompLZSS(buff.slice(16), f_comp_size, f_dec_size)
					is_comp = true
				else:
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_comp_size)
					
				var hdr_bytes: String = buff.slice(0, 4).get_string_from_ascii()
				if hdr_bytes == "HEP":
					if debug_output:
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						
					if tile_output:
						var pngs: Array[Image] = make_img_hed(buff)
						for img in range(0, pngs.size()):
							var png: Image = pngs[img]
							png.save_png(folder_path + "/%s" % f_name + "_%04d_%04d" % [hfu_i, img] + ".PNG")
					else:
						var png: Image = make_img_hed_full(f_name, hfu_i, buff)
						png.save_png(folder_path + "/%s" % f_name + "_%04d" % hfu_i + ".PNG")
						
					print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [hfu_i, ext]])
					continue
				elif hdr_bytes == "HFU2":
					ext = "HFU2"
					
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				else:
					if Main.game_type == Main.CANARIA and (f_name == "IMAGE.BIN" or f_name == "SYSDAT.BIN"):
						if debug_output:
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
							out_file.store_buffer(buff)
							out_file.close()
						var w: int = 640
						var h: int = 448
						var bpp: int 
						if (w*h) < buff.size():
							bpp = 8
						elif (w*h) / 2 < buff.size():
							bpp = 4
						else:
							print_rich("[color=yellow]%s_%04d.%s is a dummy image?" % [f_name, hfu_i, ext])
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
							out_file.store_buffer(buff)
							out_file.close()
							continue
						var png: Image = make_img_canaria(w, h, bpp, buff)
						png.save_png(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, "PNG"])
					else:
						in_file.seek(f_offset)
						var hdr_arr: PackedByteArray = in_file.get_buffer(16)
						var is_adpcm: bool = true
						for b in hdr_arr:
							if b != 0:
								is_adpcm = false
								break
						if Main.game_type == Main.KOMOREBI and (
							f_name.contains("DATA.BIN_0008") or 
							f_name.contains("DATA.BIN_0009") or 
							f_name.contains("DATA.BIN_0010") or
							f_name.contains("DATA.BIN_0017")):
							ext = "IMG"
						elif is_adpcm:
							ext = "ADPCM"
						else:
							ext = "BIN"
						
						if is_comp:
							var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
							out_file.store_buffer(buff)
							out_file.close()
							
							print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [hfu_i, ext]])
							continue
							
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [hfu_i, ext], FileAccess.WRITE)
						in_file.seek(f_offset)
						while in_file.get_position() < f_offset + f_comp_size:
							var read_size: int = min(BUFFER_SIZE, (f_offset + f_comp_size) - in_file.get_position())
							buff = in_file.get_buffer(read_size)
							out_file.store_buffer(buff)
						out_file.close()
					
				print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [hfu_i, ext]])
		elif hdr == "PACK":
			var ext: String = "BIN"
			var pack_size: int = in_file.get_length()
			
			in_file.seek(4)
			var num_files: int = in_file.get_32()
			var base_off: int = in_file.get_32()
			var pack_type: int = in_file.get_32() # if 2, has compressed files and theres only 1?
			var pack_pos: int = 0x10
			var hfu_id: int = 0
			for pack_i in range(num_files):
				if pack_type == 2 and pack_i == 1: break
				in_file.seek(pack_pos)
				
				var f_offset: int = in_file.get_32() + base_off
				var f_comp_size: int = in_file.get_32()
				
				pack_pos += 0x8
				
				if f_comp_size == 0:
					continue
					
				#if pack_i != 353:
					#continue
					
				var buff: PackedByteArray
				
				if pack_type == 2:
					in_file.seek(f_offset)
					buff = in_file.get_buffer(pack_size - base_off)
				else:
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_comp_size)
				
				
				var hdr_bytes: String = buff.slice(0, 4).get_string_from_ascii()
				if hdr_bytes == "PACK":
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [pack_i, "PACK"], FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [pack_i, "PACK"]])
					continue
				elif hdr_bytes == "LZSS":
					f_comp_size = buff.decode_u32(4)
					var f_dec_size: int = buff.decode_u32(8)
					buff = ComFuncs.decompLZSS(buff.slice(16), f_comp_size, f_dec_size)
					
					hdr_bytes = buff.slice(0, 4).get_string_from_ascii()
				if hdr_bytes == "HEP":
					if debug_output:
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [pack_i, ext], FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						
					var pngs: Array[Image] = make_img_hed(buff)
					var png: Image = arrange_images_side_by_side(pngs)
					png.save_png(folder_path + "/%s" % f_name + "_%04d" % pack_i + ".PNG")
						
					print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [pack_i, ext]])
					continue
				elif hdr_bytes == "hss":
					print_rich("[color=red]BUSTUP HSS images currently not supported!")
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [pack_i, "HSS"], FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				else:
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + "_%04d.%s" % [pack_i, "PACK"], FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				
				print("%08X %08X %s/%s" % [f_offset, f_comp_size, folder_path, f_name + "_%04d.%s" % [pack_i, ext]])
		else:
			print_rich("[color=red]%s does not have a valid header!" % f_name)
	print_rich("[color=green]Finished![/color]")
	
	
func extract_biz() -> void:
	for file: int in selected_bizs.size():
		var in_file: FileAccess = FileAccess.open(selected_bizs[file], FileAccess.READ)
		var exe_file: FileAccess = FileAccess.open(exe_path, FileAccess.READ)
		var arc_name: String = selected_bizs[file].get_file().get_basename()
		
		var compressed_arc: bool = false
		var tbl_start: int
		var tbl_end: int
		if arc_name == "PACK_SYS":
			tbl_start = 0x276340
			tbl_end = 0x276F40
			compressed_arc = true
		elif arc_name == "PACK_EGP":
			tbl_start = 0x276F40
			tbl_end = 0x278BC0
			compressed_arc = true
		elif arc_name == "PACK_MPK":
			tbl_start = 0x278BC0
			tbl_end = 0x2790E0
			compressed_arc = true
		elif arc_name == "PACK_BG":
			tbl_start = 0x279140
			tbl_end = 0x27A120
			compressed_arc = true
		elif arc_name == "PACK_BGE":
			tbl_start = 0x523000
			tbl_end = 0x523CB0
			compressed_arc = true
		elif arc_name == "PACK_BUP":
			if Main.game_type == Main.IZUMO2TAKEKI:
				tbl_start = 0x27A120
				tbl_end = 0x27B200
				compressed_arc = true
			elif Main.game_type == Main.IZAYOI:
				tbl_start = 0x523CB0
				tbl_end = 0x524A88
				compressed_arc = true
		elif arc_name == "PACK_BTL":
			tbl_start = 0x27B200
			tbl_end = 0x27B390
			compressed_arc = true
		elif arc_name == "PACK_BTL":
			tbl_start = 0x27B200
			tbl_end = 0x27B390
			compressed_arc = true
			
		var id: int = 0
		var step_mod: int = 16
		if Main.game_type == Main.IZAYOI:
			step_mod == 8
			
		for i in range(tbl_start, tbl_end, step_mod):
			exe_file.seek(i)
			
			#if id != 71:
				#id += 1
				#continue
			
			var f_name: String = "%s_%04d.BIN" % [arc_name, id]
			var f_off: int = exe_file.get_32()
			var f_sec_off: int 
			var f_dec_size: int
			var f_size: int
			
			if Main.game_type == Main.IZUMO2TAKEKI:
				f_sec_off = exe_file.get_32() * 0x800
				f_dec_size = exe_file.get_32()
				f_size = exe_file.get_32()
			elif Main.game_type == Main.IZAYOI:
				f_off *= 0x800
				f_size = exe_file.get_32()
			
			in_file.seek(f_off)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			var buff_dec_size: int = 0
			
			print("%08X %08X %s" % [f_off, f_size, folder_path + "/%s" % f_name])
			if arc_name == "PACK_SYS" and (id == 184 or id == 185):
				print_rich("[color=red]PACK_SYS_%04d is a multi packed M2D file (TODO)" % id)
				buff = decompress_lz(buff, f_dec_size)
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				id += 1
				continue
			
			if compressed_arc:
				buff_dec_size = buff.decode_u32(0)
				if Main.game_type != Main.IZAYOI and (buff_dec_size != f_dec_size):
					push_error("Decompressed sizes don't match!")
					
				if Main.game_type == Main.IZAYOI:
					buff = decompress_lz(buff, buff_dec_size)
				else:
					buff = decompress_lz(buff, f_dec_size)
					
				if debug_output:
					var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
			else:
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			if buff.slice(0, 3).get_string_from_ascii() == "M2D":
				var pngs: Array[Image] = make_img_biz(buff)
				for img in range(0, pngs.size()):
					var png: Image = pngs[img]
					if tile_output:
						png.save_png(folder_path + "/%s" % f_name + "_%04d" % img + ".PNG")
					else:
						png = arrange_images_in_pairs(pngs)
						png.save_png(folder_path + "/%s" % f_name + ".PNG")
						break
			elif buff.slice(0, 4).get_string_from_ascii() == "LPKT":
				var num_files: int = buff.decode_u32(4)
				var pos: int = 8
				for k in range(0, num_files):
					f_name = "%s_%04d.BIN_%04d.BIN" % [arc_name, id, k]
					var off: int = buff.decode_u32((pos * k) + 8)
					var size_t: int = buff.decode_u32((pos * k) + 8 + 4)
					var t_buff: PackedByteArray = buff.slice(off, off + size_t)
					if t_buff.slice(0, 3).get_string_from_ascii() == "M2D":
						var pngs: Array[Image] = make_img_biz(t_buff)
						for img in range(0, pngs.size()):
							var png: Image = pngs[img]
							if tile_output:
								png.save_png(folder_path + "/%s" % f_name + "_%04d" % img + ".PNG")
							else:
								png = arrange_images_in_pairs(pngs)
								png.save_png(folder_path + "/%s" % f_name + ".PNG")
								break
					else:
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + ".BIN", FileAccess.WRITE)
						out_file.store_buffer(t_buff)
						out_file.close()
			elif buff.slice(0, 8).get_string_from_ascii() == "EGA_PACK":
				var num_files: int = buff.decode_u32(8)
				var pos: int = 16
				for k in range(0, num_files + 1):
					f_name = "%s_%04d.BIN_%04d.BIN" % [arc_name, id, k]
					var off: int = buff.decode_u32(pos)
					var size_t: int = buff.decode_u32(pos + 4)
					if size_t == 0:
						size_t = buff.size()
					else:
						size_t -= off
					var t_buff: PackedByteArray = buff.slice(off, off + size_t)
					if t_buff.slice(0, 3).get_string_from_ascii() == "M2D":
						var pngs: Array[Image] = make_img_biz(t_buff)
						for img in range(0, pngs.size()):
							var png: Image = pngs[img]
							if tile_output:
								png.save_png(folder_path + "/%s" % f_name + "_%04d" % img + ".PNG")
							else:
								png = arrange_images_in_pairs(pngs)
								png.save_png(folder_path + "/%s" % f_name + ".PNG")
								break
					else:
						var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name + ".BIN", FileAccess.WRITE)
						out_file.store_buffer(t_buff)
						out_file.close()
					pos += 4
			elif buff.slice(0, 4).get_string_from_ascii() == "MGrp":
				if tile_output:
					var png: Image = make_img_biz_izayoi(buff)
					png.save_png(folder_path + "/%s" % f_name + ".PNG")
			else:
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
						
			id += 1
	print_rich("[color=green]Finished![/color]")
	
	
func make_img_canaria(w: int, h: int, bpp: int, data: PackedByteArray) -> Image:
	var img_size: int = w*h if bpp == 8 else (w*h) / 2
	var img_dat: PackedByteArray = data.slice(0, img_size)
	var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(img_size), 32) if bpp == 8 else data.slice(img_size)
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	if bpp == 8:
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				a = int((a / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	elif bpp == 4:
		for y in range(h):
			for x in range(0, w, 2):  # Two pixels per byte
				var byte_index: int  = (x + y * w) / 2
				var byte_value: int  = data[byte_index]

				# Extract two 4-bit indices (little-endian order)
				var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
				var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

				# Set first pixel
				var r1: int = pal[pixel_index_1 * 4 + 0]
				var g1: int = pal[pixel_index_1 * 4 + 1]
				var b1: int = pal[pixel_index_1 * 4 + 2]
				var a1: int = pal[pixel_index_1 * 4 + 3]
				a1 = int((a1 / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

				# Set second pixel (only if within bounds)
				if x + 1 < w:
					var r2: int = pal[pixel_index_2 * 4 + 0]
					var g2: int = pal[pixel_index_2 * 4 + 1]
					var b2: int = pal[pixel_index_2 * 4 + 2]
					var a2: int = pal[pixel_index_2 * 4 + 3]
					a2 = int((a2 / 128.0) * 255.0)
					
					image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	return image
	
	
func arrange_images_side_by_side(images: Array[Image]) -> Image:
	if images.is_empty():
		return null
	
	# Assume all images are the same size
	var img_width: int = images[0].get_width()
	var img_height: int = images[0].get_height()
	
	# Calculate final dimensions
	var final_width: int = img_width * images.size()
	var final_height: int = img_height
	
	# Create the final image
	var final_img: Image = Image.create_empty(final_width, final_height, false, images[0].get_format())
	
	# Place each image horizontally
	for i in range(images.size()):
		var pos_x: int = i * img_width
		final_img.blit_rect(images[i], Rect2i(Vector2i(0, 0), images[i].get_size()), Vector2i(pos_x, 0))
	
	return final_img
	
	
func arrange_images_in_pairs(images: Array[Image]) -> Image:
	if images.is_empty():
		return null
	
	# Assume all images are the same size
	var img_width: int = images[0].get_width()
	var img_height: int = images[0].get_height()
	
	# Calculate rows (2 images per row)
	var rows: int = int(ceil(images.size() / 2.0))
	var final_width: int = img_width * 2
	var final_height: int = img_height * rows
	
	# Create the final image
	var final_img: Image = Image.create_empty(final_width, final_height, false, images[0].get_format())
	
	# Draw each image in the correct position
	for i in range(images.size()):
		var row: int = i / 2
		var col: int = i % 2
		var pos_x: int = col * img_width
		var pos_y: int = row * img_height
		final_img.blit_rect(images[i], Rect2i(Vector2i(0, 0), images[i].get_size()), Vector2i(pos_x, pos_y))
	
	return final_img
	
	
func make_img_hed_full(pack_name: String, image_id: int, data: PackedByteArray) -> Image:
	var data_size: int = data.size()
	var off: int = 0
	var tiles: Array[Dictionary] = []  # store { image, vecs }
	var layout_flag: int = 0  # will update when we read
	
	while off < data_size:
		if off != 0 and data.slice(off, off + 4).get_string_from_ascii() != "HEP":
			print_rich("[color=red]Premature end of image?")
			break
		
		var section_end: int = data.decode_u32(off + 4)
		var flag_offset: int = section_end + 0xC0
		if flag_offset < data_size:
			layout_flag = data.decode_u8(flag_offset)
		
		var img_type: int = data.decode_u32(off + 0x10)
		var w: int = data.decode_u32(off + 0x14)
		var h: int = data.decode_u32(off + 0x18)

		var img_data: PackedByteArray
		var pal: PackedByteArray
		
		if img_type == 0x10:
			# 8-bit indexed, 256-color palette (0x400 bytes)
			var img_size: int = w * h
			img_data = data.slice(off + 0x20, off + 0x20 + img_size)
			pal = ComFuncs.unswizzle_palette(
				data.slice(off + img_size + 0x20, off + img_size + 0x420), 32
			)
		elif img_type == 0x20:
			# 4-bit indexed, 16-color palette (0x40 bytes)
			var packed_size: int = int(ceil((w * h) / 2.0))
			img_data = data.slice(off + 0x20, off + 0x20 + packed_size)
			pal = data.slice(off + packed_size + 0x20, off + packed_size + 0x60)
		else:
			print_rich("[color=yellow]Unknown img_type: %d" % img_type)
			break
		
		# --- decode to RGBA image ---
		var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		
		for y in range(h):
			for x in range(w):
				var pixel_index: int
				if img_type == 0x10:
					pixel_index = img_data[x + y * w]
				else:
					var idx: int = (x + y * w) / 2
					var byte_val: int = img_data[idx]
					if (x % 2) == 0:
						pixel_index = byte_val & 0x0F
					else:
						pixel_index = (byte_val >> 4) & 0x0F
				
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				a = int((a / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		
		# --- read float placement data ---
		var floats: PackedFloat32Array = []
		if section_end >= data_size: 
			var vecs: Array[Vector4] = []
			vecs.append(Vector4(-1, -1, -1, -1))
			tiles.append({ "img": image, "vecs": vecs })
			break
		for i in range(0xC0 / 4): # up to 48 floats
			floats.append(data.decode_float(off + section_end + i * 4))
		
		# group into Vector4s
		var vecs: Array[Vector4] = []
		for i in range(0, floats.size(), 4):
			vecs.append(Vector4(floats[i], floats[i+1], floats[i+2], floats[i+3]))
		
		tiles.append({ "img": image, "vecs": vecs })
		
		off += section_end + 0xD0
	
	# --- check for "just first tile" case ---
	if tiles[0]["vecs"].size() > 0 and int(tiles[0]["vecs"][0].x) == -1:
		return tiles[0]["img"].duplicate()
		
	# --- construct final composite image ---
	if tiles.is_empty():
		return null
	
	var final_img: Image
	
	if (Main.game_type == Main.WIND and 
		pack_name == "PCG.BIN" and 
		image_id == 160 and 
		layout_flag == 0x6):
		# horizontal layout (all in one row)
		var tile_w: int = tiles[0]["img"].get_width()
		var tile_h: int = tiles[0]["img"].get_height()
		var final_w: int = tile_w * tiles.size()
		var final_h: int = tile_h
		final_img = Image.create_empty(final_w, final_h, false, Image.FORMAT_RGBA8)
		
		for i in range(tiles.size()):
			var pos_x: int = i * tile_w
			final_img.blit_rect(tiles[i]["img"], Rect2i(Vector2i(0, 0), tiles[i]["img"].get_size()), Vector2i(pos_x, 0))
	else: #layout_flag == 0x2?
		# default: place based on vec positions
		var max_x: int = 0
		var max_y: int = 0
		for t in tiles:
			for v in t["vecs"]:
				if v.x > max_x: max_x = int(v.x)
				if v.y > max_y: max_y = int(v.y)
		
		final_img = Image.create_empty(max_x, max_y, false, Image.FORMAT_RGBA8)
		
		for t in tiles:
			var img: Image = t["img"]
			var v0: Vector4 = t["vecs"][0]   # should be top-left
			var pos_x: int = int(v0.x)
			var pos_y: int = int(v0.y)
			final_img.blit_rect(img, Rect2i(Vector2i(0, 0), img.get_size()), Vector2i(pos_x, pos_y))
	
	return final_img
	
	
func make_img_hed(data: PackedByteArray) -> Array[Image]:
	var imgs: Array[Image]
	var data_size: int = data.size()
	var off: int = 0
	while off < data_size:
		if off != 0 and data.slice(off, off + 4).get_string_from_ascii() != "HEP":
			print_rich("[color=red]Premature end of image?")
			return imgs
		var section_end: int = data.decode_u32(off + 4)
		var img_type: int = data.decode_u32(off + 0x10)
		var w: int = data.decode_u32(off + 0x14)
		var h: int = data.decode_u32(off + 0x18)
		var img_size: int = w * h
		var pal: PackedByteArray
		var img_data: PackedByteArray
		
		if img_type == 0x10:
			# 8-bit indexed, 256-color palette (0x400 bytes)
			img_data = data.slice(off + 0x20, off + 0x20 + img_size)
			if Main.game_type == Main.MIZUIRO or Main.game_type == Main.THREADCOLORS:
				pal = data.slice(off + img_size + 0x20, off + img_size + 0x420)
			else:
				pal = ComFuncs.unswizzle_palette(
					data.slice(off + img_size + 0x20, off + img_size + 0x420), 32
				)
		elif img_type == 0x20:
			# 4-bit indexed, 16-color palette (0x40 bytes)
			var packed_size: int = int(ceil((w * h) / 2.0))
			img_data = data.slice(off + 0x20, off + 0x20 + packed_size)
			pal = data.slice(off + packed_size + 0x20, off + packed_size + 0x60)
		else:
			print_rich("[color=yellow]Unknown img_type: %d" % img_type)
			break
			
		var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w):
				var pixel_index: int
				if img_type == 0x10:
					pixel_index = img_data[x + y * w]
				else:
					var idx: int = (x + y * w) / 2
					var byte_val: int = img_data[idx]
					if (x % 2) == 0:
						pixel_index = byte_val & 0x0F
					else:
						pixel_index = (byte_val >> 4) & 0x0F
				
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				a = int((a / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		imgs.append(image)
		
		if Main.game_type == Main.MIZUIRO or Main.game_type == Main.THREADCOLORS: # no float section
			off += section_end
		else:
			off += section_end + 0xD0
	return imgs
	
	
func make_img_biz(data: PackedByteArray) -> Array[Image]:
	var imgs: Array[Image]
	var data_size: int = data.size()
	var off: int = 0x20
	while off < data_size:
		var w: int = data.decode_u32(off + 0x10)
		if w == 0:
			print_rich("[color=red]Premature end of image?")
			return imgs
		var h: int = data.decode_u32(off + 0x14)
		var img_size: int = (w * h) + off + 0x420
		var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(off + 0x20, off + 0x420), 32)
		var img_data: PackedByteArray = unswizzle8(data.slice(off + 0x420, img_size), w, h)
		var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_data[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				a = int((a / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		imgs.append(image)
		off = img_size
	return imgs
	
	
func make_img_biz_izayoi(data: PackedByteArray) -> Image:
	var data_size: int = data.size()
	#var off: int = 0x20
	var img_dat_off: int = data.decode_u32(0x18)
	var pal_off: int = data.decode_u32(0x10)
	var w: int = data.decode_u16(0x20) << 2 #((data.decode_u8(0x28) - 1) * data.decode_u16(0xA)) + data.decode_u16(0x20) # also valid by the game
	var h: int = data.decode_u16(0x22) << 2 #((data.decode_u8(0x29) - 1) * data.decode_u16(0xC)) + data.decode_u16(0x22) # also valid by the game
	var img_size: int = (w * h) + img_dat_off
	var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(pal_off, img_dat_off), 32)
	var img_data: PackedByteArray = unswizzle8(data.slice(img_dat_off, img_size + img_dat_off), w, h) #unswizzle_ps2_psmt8(data.slice(img_dat_off, img_size + img_dat_off), w, h, 0)
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var pixel_index: int = img_data[x + y * w]
			var r: int = pal[pixel_index * 4 + 0]
			var g: int = pal[pixel_index * 4 + 1]
			var b: int = pal[pixel_index * 4 + 2]
			var a: int = pal[pixel_index * 4 + 3]
			a = int((a / 128.0) * 255.0)
			
			image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	return image
	
	
func unswizzle_ps2_psmt8(data: PackedByteArray, w: int, h: int, pitch: int = 0) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(w * h)

	# Align pitch to GS requirement if not given
	var p: int = pitch
	if p <= 0:
		p = int(ceil(float(w) / 64.0)) * 64

	for y in range(h):
		for x in range(w):
			# --- page base (128x64 pixels) ---
			var page_x: int = (x & ~127)
			var page_y: int = (y & ~63)
			var page_index: int = (page_y * p + page_x * 64)

			# --- block base inside page (16x8) ---
			var bx: int = (x & 127) >> 4  # block X index (0..7)
			var by: int = (y & 63) >> 3   # block Y index (0..7)
			var block_index: int = by * 8 + bx
			var block_base: int = block_index * 128  # 128 bytes per block

			# --- position inside block (16x8) ---
			var ix: int = x & 15
			var iy: int = y & 7

			# GS bank swap pattern
			var bs: int = ((iy >> 1) & 1) * 4
			var cell: int = (((ix + bs) & 7) << 2) + ((iy & 1) + ((ix >> 2) & 2))

			# right half of block (ix >= 8) offset
			if ix >= 8:
				cell += 32
			# row offset inside block (iy >> 1) * 16
			cell += (iy >> 1) * 16

			# final source address
			var src_index: int = page_index + block_base + cell
			var dst_index: int = y * w + x

			if src_index < data.size() and dst_index < out.size():
				out[dst_index] = data[src_index]

	return out
	
	
func unswizzle8(data: PackedByteArray, w: int, h: int, swizz: bool = false) -> PackedByteArray:
	# Original code from: https://github.com/leeao/PS2Textures/blob/583f68411b4f6cca491730fbb18cb064822f1017/PS2Textures.py#L266
	# Unknown license
	
	var out: PackedByteArray = data.duplicate()
	for y in range(h):
		for x in range(w):
			var bs: int = ((y + 2) >> 2 & 1) * 4
			var idx: int = \
				((y & ~0xF) * w) + ((x & ~0xF) * 2) + \
				( ((((y & ~3) >> 1) + (y & 1)) & 7) * w * 2 ) + \
				(((x + bs) & 7) * 4) + \
				(((y >> 1) & 1) + ((x >> 2) & 2))
			if swizz:
				out[idx] = data[y * w + x]
			else:
				out[y * w + x] = data[idx]
	return out
	
	
func decompress_lz(input_buffer: PackedByteArray, output_size: int) -> PackedByteArray:
	var output: PackedByteArray = PackedByteArray()
	output.resize(output_size)
	var temp_buff: PackedByteArray = PackedByteArray()
	temp_buff.resize(0x800)
	
	for i in range(0x7EF):
		temp_buff.encode_u8(i, 0x20)
		
	var gp: PackedByteArray = PackedByteArray()
	gp.resize(0x50)
	
	var a0: int = 0
	var a1: int = 0
	var a2: int = 0
	var t2: int = 0
	var t3: int = 0
	var t4: int = 0
	var t5: int = 0
	var t6: int = 0
	var t7: int = 0
	var v0: int = 0
	
	gp.encode_u32(0, 4) #input pos
	gp.encode_u32(4, 0) # output pos
	gp.encode_u32(0x34, 0x7EF)
	gp.encode_u32(0x20, output_size)
	var pc: int = 0x00101FA0  # starting label
	while true:
		match pc:
			0x00101FA0:
				a1 = 1
				gp = _decompress_lz(input_buffer, gp, a1)
				v0 = gp.decode_u32(0x48)
				gp.encode_s32(0x38, v0)
				if v0 == 0:
					pc = 0x001020dc
					continue
				a1 = 8
				gp = _decompress_lz(input_buffer, gp, a1)
				v0 = gp.decode_u32(0x48)
				gp.encode_s32(0x38, v0)
				t3 = gp.decode_s32(4)
				t6 = 0
				t7 = gp.decode_u8(0x38)#gpd738 & 0xFF #load_byte_unsigned(gp + 0xd738)
				output.encode_s8(t3, t7)#store_byte(t3 + 0x0000, t7)
				t4 = gp.decode_s32(0x34)#gpd734#load_word(gp + 0xd734)
				t3 = t3 + 1
				t5 = gp.decode_s32(0x24)#gpd724 #load_word(gp + 0xd724)
				t6 = t4 + t6
				t7 = gp.decode_u8(0x38)#gpd738 & 0xFF#load_byte_unsigned(gp + 0xd738)
				t4 = t4 + 1
				gp.encode_s32(4, t3)#gp8024 = t3#store_word(gp + 0x8024, t3)
				t5 = t5 + 1
				temp_buff.encode_s8(t6, t7)#store_byte(t6 + 0x0000, t7)
				t4 = t4 & 2047
				gp.encode_s32(0x24, t5)#gpd724 = t5#store_word(gp + 0xd724, t5)
				gp.encode_s32(0x34, t4)#gpd734 = t4#store_word(gp + 0xd734, t4)
				pc = 0x00102008
				continue
			0x00102008:
				t6 = gp.decode_s32(0x24)#gpd724#load_word(gp + 0xd724)
				pc = 0x0010200C
				continue
			0x0010200C:
				t7 = gp.decode_s32(0x20)#gpd720#load_word(gp + 0xd720)
				v0 = t6# daddu             v0, t6, zero
				if t6 == t7:
					pc = 0x001020c8
					continue
				pc = 0x00101FA0
				continue
			0x001020C8:
				break
			0x001020DC:
				a1 = 11
				gp = _decompress_lz(input_buffer, gp, a1)
				v0 = gp.decode_u32(0x48)
				gp.encode_s32(0x28, v0)#gpd728 = v0#store_word(gp + 0xd728, v0)
				a1 = 4
				gp = _decompress_lz(input_buffer, gp, a1)
				v0 = gp.decode_u32(0x48)
				gp.encode_s32(0x2C, v0)#gpd72c = v0#store_word(gp + 0xd72c, v0)
				v0 = v0 + 1
				gp.encode_u32(0x30, 0)#gpd730 = 0
				if v0 < 0 or v0 >= 0xFFFFFFFF:
					pc = 0x00102008
					continue
				pc = 0x00102108
				continue
			0x00102108:
				t6 = gp.decode_s32(0x30)#gpd730#load_word(gp + 0xd730)
				# lui               t3, $003e
				t7 = gp.decode_s32(0x28)#gpd728#load_word(gp + 0xd728)
				t3 = 0 #t3 + -30384
				t2 = gp.decode_s32(0x4)#gp8024#load_word(gp + 0x8024)
				t7 = t7 + t6
				t7 = t7 & 2047
				t7 = t7 + t3
				t7 = temp_buff.decode_u8(t7)#load_byte_unsigned(t7 + 0x0000)
				gp.encode_s32(0x38, t7)#gpd738 = t7#store_word(gp + 0xd738, t7)
				t7 = gp.decode_u8(0x38)#gpd738 & 0xFF#load_byte_unsigned(gp + 0xd738)
				output.encode_s8(t2, t7)#store_byte(t2 + 0x0000, t7)
				t5 = gp.decode_s32(0x34)#gpd734#load_word(gp + 0xd734)
				t2 = t2 + 1
				t7 = gp.decode_u8(0x38)#gpd738 & 0xFF#load_byte_unsigned(gp + 0xd738)
				t3 = t5 + t3
				t4 = gp.decode_s32(0x30)#gpd730#load_word(gp + 0xd730)
				temp_buff.encode_s8(t3, t7)#store_byte(t3 + 0x0000, t7)
				t5 = t5 + 1
				t6 = gp.decode_s32(0x24)#gpd724#load_word(gp + 0xd724)
				t4 = t4 + 1
				t7 = gp.decode_s32(0x2C)#gpd72c#load_word(gp + 0xd72c)
				t5 = t5 & 2047
				t6 = t6 + 1
				gp.encode_s32(4, t2)#gp8024 = t2#store_word(gp + 0x8024, t2)
				t7 = t7 + 1
				gp.encode_s32(0x24, t6)#gpd724 = t6#store_word(gp + 0xd724, t6)
				gp.encode_s32(0x34, t5)#gpd734 = t5#store_word(gp + 0xd734, t5)
				t7 = 1 if t7 < t4 else 0
				gp.encode_s32(0x30, t4)#gpd730 = t4#store_word(gp + 0xd730, t4)
				if t7 == 0:
					pc = 0x00102108
					continue
				t6 = gp.decode_s32(0x24)#gpd724#load_word(gp + 0xd724)
				pc = 0x0010200c
				continue

	return output
	
	
func _decompress_lz(input: PackedByteArray, gp: PackedByteArray, a1: int) -> PackedByteArray:
	var a0: int = 0
	var t4: int = 0
	var t5: int = 0
	var t6: int = 0
	var t7: int = 0
	var v0: int = 0
	# return v0 in gp 0x48
	#D5E0 is its own counter (as gp 0x44)
	#DC48 is input read from input pos (as 0x4C)

	var pc: int = 0x002141D8  # starting label
	while true:
		match pc:
			0x002141D8:
				v0 = 0
				if a1 <= 0:
					pc = 0x00214234
					continue
				# blez              a1, $00214234
				# nop
				pc = 0x002141E0
				continue
			0x002141E0:
				t7 = gp.decode_s32(0x44)#load_word(gp + 0xd5e0)
				if t7 != 0:
					t6 = gp.decode_s32(0x44)#load_word(gp + 0xd5e0)
					pc = 0x00214210
					continue
				t7 = gp.decode_s32(0)#load_word(a0 + 0x0000)
				t7 = input.decode_u8(t7)#t7 = load_byte_unsigned(t7 + 0x0000)
				gp.encode_s32(0x4C, t7)#DC48 = t7#store_word(gp + 0xdc48, t7)
				t7 = gp.decode_s32(0)#load_word(a0 + 0x0000)
				t7 = t7 + 1
				gp.encode_s32(0, t7)#store_word(a0 + 0x0000, t7)
				t7 = 0 + 128
				gp.encode_s32(0x44, t7)#store_word(gp + 0xd5e0, t7)
				t6 = gp.decode_s32(0x44)#load_word(gp + 0xd5e0)
				pc = 0x00214210
				continue
			0x00214210:
				v0 = v0 << 1
				t7 = gp.decode_s32(0x4C)#t7 = DC48#load_word(gp + 0xdc48)
				t5 = v0 + 1
				t4 = t6 >> 1  # arithmetic shift
				a1 = a1 + -1
				t7 = t7 & t6 # and               t7, t7, t6
				gp.encode_s32(0x44, t4)#store_word(gp + 0xd5e0, t4)
				# movn              v0, t5, t7
				if t7 != 0: v0 = t5
				if a1 != 0:
					pc = 0x002141e0
					continue
				break
			0x00214234:
				break
	gp.encode_s32(0x48, v0)
	return gp
	
	
func convert_imgs() -> void:
	for file in range(selected_imgs.size()):
		var in_file: FileAccess = FileAccess.open(selected_imgs[file], FileAccess.READ)
		var f_name: String = selected_imgs[file].get_file()
		var f_ext: String = selected_imgs[file].get_extension()
		var hdr: String = in_file.get_buffer(4).get_string_from_ascii()
		if hdr == "MF":
			in_file.seek(0x14)
			var first_off: int = in_file.get_32()
			
			in_file.seek(first_off)
			hdr = in_file.get_buffer(3).get_string_from_ascii().strip_escapes()
			if hdr == "IMG" or hdr == "STD" or hdr == "1" or hdr == "2" or hdr == "0":
				var is_std: bool = false
				if hdr == "STD":
					is_std = true # For character images, though likely not needed
				in_file.seek(0)
				var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
				var num_files: int = buff.decode_u32(4)
					
				var img_tex_off: int = buff.decode_u32(8)
				var str_size: int = buff.decode_u32(0x10)
				var img_str: String = buff.slice(img_tex_off + 4, img_tex_off + 4 + str_size - 4).get_string_from_ascii()
				if buff.decode_u8(img_tex_off + 3) == 0xD:
					str_size -= 2
					img_str = buff.slice(img_tex_off + 5, img_tex_off + 5 + str_size - 5).get_string_from_ascii()
				elif buff.decode_u8(img_tex_off + 2) == 0xA:
					str_size -= 2
					img_str = buff.slice(img_tex_off + 3, img_tex_off + 3 + str_size - 3).get_string_from_ascii()
				var width_end: int = img_str.find(",")
				var height_end: int = img_str.find("\n")
				var f_w: int = img_str.substr(0, width_end).to_int()
				var f_h: int = img_str.substr(width_end, height_end - width_end).to_int()
				if height_end == -1:
					f_h = img_str.substr(width_end).to_int()
				
				var mf_pos: int = 0x20
				for hdr_i in range(num_files - 1):
					var tbl_start: int = buff.decode_u32(mf_pos + 4)
					if tbl_start == 0:
						mf_pos += 0x10
						continue
						
					var img_arr: Array[Image]
					var pos: int = 0x1C
					var hdr_buff: PackedByteArray = buff.slice(tbl_start)
					var num_imgs: int = hdr_buff.decode_u32(4)
					if num_imgs > 800:
						print_rich("[color=yellow]Palette data(and only that?) found in %s/%s_%03d skipping." % [folder_path, f_name, hdr_i])
						mf_pos += 0x10
						continue
					elif num_imgs > 1:
						# Mainly for Fate Stay Night checks for multiple images that are different dims from the rest. Improve detection later.
						var temp_w1: int = hdr_buff.decode_u32(pos + 4)
						var temp_h1: int = hdr_buff.decode_u32(pos + 8)
						var temp_w2: int = hdr_buff.decode_u32(pos + 0x24)
						var temp_h2: int = hdr_buff.decode_u32(pos + 0x28)
						if temp_h1 != temp_h2 or temp_w1 != temp_w2:
							is_std = true
					var img_format: int
					for img_i in range(num_imgs):
						img_format = hdr_buff.decode_u32(pos)
						var w: int = hdr_buff.decode_u32(pos + 4)
						var h: int = hdr_buff.decode_u32(pos + 8)
						var pal_off: int =  hdr_buff.decode_u32(pos + 12)
						var img_off: int =  hdr_buff.decode_u32(pos + 16)
						var unk: int = hdr_buff.decode_u32(pos + 0x1C)
						
						var img_size: int = w * h
						var pal_size: int = 0x400
						var pal: PackedByteArray
						if img_format == 0x13: # 8 bit
							pal = ComFuncs.unswizzle_palette(hdr_buff.slice(pal_off, pal_off + pal_size), 32)
						elif img_format == 0x14: # 4 bit
							pal_size = 0x40
							pal = hdr_buff.slice(pal_off, pal_off + pal_size)
						
						var img_buff: PackedByteArray = hdr_buff.slice(img_off, img_off + img_size)
						var png: Image = make_img2(img_buff, pal, is_std, img_i, w, h, img_format)
						if tile_output:
							png.save_png(folder_path + "/%s" % f_name + "_%03d_%03d.PNG" % [hdr_i, img_i])
						if is_std and img_i == 0:
							png.save_png(folder_path + "/%s" % f_name + "_%03d_mask.PNG" % hdr_i)
							pos += 0x20
							continue
						img_arr.append(png)
						pos += 0x20
						
					if is_std:
						print("0x%02X %02d %d x %d %s" % [img_format, num_imgs - 1, f_w, f_h, folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i])
					else:
						print("0x%02X %02d %d x %d %s" % [img_format, num_imgs, f_w, f_h, folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i])
						
					var png: Image
					if num_imgs > 2:
						var img_id: int = f_name.substr(f_name.length() - 7, f_name.length() - 7 + 5).to_int()
						png = tile_images_by_batch(img_arr, f_w, f_h, img_id, is_std)
					else:
						png = img_arr[0]
						
					png.save_png(folder_path + "/%s" % f_name + "_%03d.PNG" % hdr_i)
					mf_pos += 0x10
			elif hdr == "MF":
				print_rich("[color=yellow]%s has MF archive(s) in it. Please extract it first." % [folder_path + "/%s" % f_name])
			else:
				print_rich("[color=red]%s is not a valid image!" % [folder_path + "/%s" % f_name])
		elif f_ext == "IMG": # Komorebi
				in_file.seek(0)
				var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
				var img_buff: PackedByteArray
				var pal: PackedByteArray
				var w: int = buff.decode_u16(0x10)
				var h: int = buff.decode_u16(0x14)
				var img_format: int = buff.decode_u32(0xC)
				if img_format == 0x13:
					pal = ComFuncs.unswizzle_palette(buff.slice(0x20, 0x420), 32)
					img_buff = buff.slice(0x420)
				elif img_format == 0x14:
					pal = buff.slice(0x20, 0x60)
					img_buff = buff.slice(0x60)
				
				print("0x%02X %d x %d %s" % [img_format, w, h, folder_path + "/%s" % f_name + "_%04d.PNG" % file])
				
				var png: Image = make_img2(img_buff, pal, false, -1, w, h, img_format)
				png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" % file)
		else:
			print_rich("[color=red]%s does not have a valid header!" % [folder_path + "/%s" % f_name])
			
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
	
	
func make_img2(data: PackedByteArray, pal: PackedByteArray, is_std: bool, img_id: int, w: int, h: int, img_format: int) -> Image:
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	if img_format == 0x13 or img_format == 0x14:
		if img_format == 0x13:
			for y in range(h):
				for x in range(w):
					var pixel_index: int = data[x + y * w]
					var r: int = pal[pixel_index * 4 + 0]
					var g: int = pal[pixel_index * 4 + 1]
					var b: int = pal[pixel_index * 4 + 2]
					var a: int = pal[pixel_index * 4 + 3]
					a = int((a / 128.0) * 255.0)
					
					image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
		elif img_format == 0x14:
			for y in range(h):
				for x in range(0, w, 2):  # Two pixels per byte
					var byte_index: int  = (x + y * w) / 2
					var byte_value: int  = data[byte_index]

					# Extract two 4-bit indices (little-endian order)
					var pixel_index_1 = byte_value & 0xF  # Low nibble (left pixel)
					var pixel_index_2 = (byte_value >> 4) & 0xF  # High nibble (right pixel)

					# Set first pixel
					var r1: int = pal[pixel_index_1 * 4 + 0]
					var g1: int = pal[pixel_index_1 * 4 + 1]
					var b1: int = pal[pixel_index_1 * 4 + 2]
					var a1: int = pal[pixel_index_1 * 4 + 3]
					a1 = int((a1 / 128.0) * 255.0)
					
					image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

					# Set second pixel (only if within bounds)
					if x + 1 < w:
						var r2: int = pal[pixel_index_2 * 4 + 0]
						var g2: int = pal[pixel_index_2 * 4 + 1]
						var b2: int = pal[pixel_index_2 * 4 + 2]
						var a2: int = pal[pixel_index_2 * 4 + 3]
						a2 = int((a2 / 128.0) * 255.0)
						
						image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	else:
		print_rich("[color=red]Unknown image format 0x%02X!" % img_format)
		return Image.create_empty(1, 1, false, Image.FORMAT_L8)
		
	#if !is_std and remove_alpha:
		#image.convert(Image.FORMAT_RGB8)
	#elif is_std and img_id > 0 and !keep_alpha_char: # always keep alpha in mask parts of character images
		#image.convert(Image.FORMAT_RGB8)
		
	return image
	
	
func make_img(data: PackedByteArray) -> Image:
	var w: int = data.decode_u16(2)
	var h: int = data.decode_u16(4)
	var bpp: int = data.decode_u16(6)
	var img_size: int = data.decode_u32(0xC) << 8
	var pal_size: int = data.decode_u32(img_size + 0x2C) << 8
	
	if bpp != 8 and bpp != 4:
		print_rich("[color=red]Unknown BPP %02d!" % bpp)
		return Image.create_empty(1, 1, false, Image.FORMAT_RGB8)
	
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	
	if bpp == 8:
		var img_dat:PackedByteArray = data.slice(0x20, img_size + 0x20)
		var pal: PackedByteArray = ComFuncs.unswizzle_palette(data.slice(img_size + 0x40, img_size + 0x40 + pal_size), 32)
		
		for y in range(h):
			for x in range(w):
				var pixel_index: int = img_dat[x + y * w]
				var r: int = pal[pixel_index * 4 + 0]
				var g: int = pal[pixel_index * 4 + 1]
				var b: int = pal[pixel_index * 4 + 2]
				var a: int = pal[pixel_index * 4 + 3]
				a = int((a / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	elif bpp == 4:
		pal_size = 0x40
		var img_dat:PackedByteArray = data.slice(0x20, img_size + 0x20)
		var pal: PackedByteArray = data.slice(img_size + 0x40, img_size + 0x40 + pal_size)
		
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
				a1 = int((a1 / 128.0) * 255.0)
				
				image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0, a1 / 255.0))

				# Set second pixel (only if within bounds)
				if x + 1 < w:
					var r2: int = pal[pixel_index_2 * 4 + 0]
					var g2: int = pal[pixel_index_2 * 4 + 1]
					var b2: int = pal[pixel_index_2 * 4 + 2]
					var a2: int = pal[pixel_index_2 * 4 + 3]
					a2 = int((a1 / 128.0) * 255.0)
					
					image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0))
	return image
	
	
func tile_images_by_batch(
	images: Array[Image],
	final_width: int,
	final_height: int,
	img_id: int,
	is_std: bool
	) -> Image:
	var n: int = images.size()
	if n == 0:
		push_error("No images to tile!")
		return Image.create_empty(1, 1, false, Image.FORMAT_L8)
	
	var tile_w: int = images[0].get_width()
	var tile_h: int = images[0].get_height()

	# Optional special exceptions for known truly weird cases
	var exceptions: Dictionary = {
		#148: Vector2i(get_best_divisor_grid(n).x, get_best_divisor_grid(n).y),
		#20:  Vector2i(get_best_divisor_grid(n).y, get_best_divisor_grid(n).x),
		#30:  Vector2i(get_best_divisor_grid(n).y, get_best_divisor_grid(n).x)
	}

	var cols: int
	var rows: int

	if img_id in exceptions:
		cols = exceptions[img_id].x
		rows = exceptions[img_id].y
	elif final_width > 0 and final_height > 0:
		# Use best-fit testing against known dimensions
		var fit: Vector2i = get_best_fit_from_dimensions(n, tile_w, tile_h, final_width, final_height)
		cols = fit.x
		rows = fit.y
	else:
		# Fallback: closest-to-square guess
		var grid: Vector2i = get_best_divisor_grid(n)
		cols = grid.x
		rows = grid.y
		final_width = cols * tile_w
		final_height = rows * tile_h

	# Create final canvas
	var final_image: Image = Image.create_empty(final_width, final_height, false, images[0].get_format())

	# Blit images in row-major order
	var img_i: int = 0
	for y in range(rows):
		for x in range(cols):
			if img_i >= n:
				return final_image
			var dst_x: int = x * tile_w
			var dst_y: int = y * tile_h
			if !is_std:
				final_image.blit_rect(images[img_i], Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
			else:
				final_image.blend_rect(images[img_i], Rect2i(0, 0, tile_w, tile_h), Vector2i(dst_x, dst_y))
			img_i += 1
	
	return final_image
	
	
func get_best_divisor_grid(n: int) -> Vector2i:
	var best: Vector2i = Vector2i(n, 1)
	var best_diff: int = n
	for cols in range(1, n + 1):
		var rows: int = int(ceil(n / float(cols)))
		var diff: int = abs(cols - rows)
		if cols * rows >= n and diff < best_diff:
			best = Vector2i(cols, rows)
			best_diff = diff
	return best
	
	
func get_best_fit_from_dimensions(n: int, tile_w: int, tile_h: int, final_width: int, final_height: int) -> Vector2i:
	var best_cols: int = 1
	var best_rows: int = n
	var best_error: float = 1e9

	for cols in range(1, n + 1):
		var rows: int = int(ceil(n / float(cols)))
		var calc_width: int = cols * tile_w
		var calc_height: int = rows * tile_h
		var error: float = abs(final_width - calc_width) + abs(final_height - calc_height)
		if error < best_error:
			best_cols = cols
			best_rows = rows
			best_error = error
	
	return Vector2i(best_cols, best_rows)
	
	
func _on_load_folder_dir_selected(dir):
	folder_path = dir
	
	
func _on_load_cd_bin_file_pressed():
	if exe_path == "":
		OS.alert("EXE must be selected first.")
		return
		
	load_bin.show()
	
	
func _on_load_exe_pressed() -> void:
	load_exe.show()
	
	
func _on_load_exe_file_selected(path: String) -> void:
	exe_path = path
	
	
func _on_debug_output_pressed() -> void:
	debug_output = !debug_output


func _on_load_bin_file_selected(path: String) -> void:
	selected_file = path
	load_folder.show()


func _on_load_image_pressed() -> void:
	load_image.show()


func _on_load_image_files_selected(paths: PackedStringArray) -> void:
	selected_imgs = paths
	load_folder.show()


func _on_tiled_output_toggled(_toggled_on: bool) -> void:
	tile_output = !tile_output


func _on_remove_alpha_1_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha


func _on_remove_alpha_2_toggled(_toggled_on: bool) -> void:
	keep_alpha_char = !keep_alpha_char


func _on_load_bin_2_file_selected(path: String) -> void:
	data_bin_path = path
	load_folder.show()


func _on_load_databin_pressed() -> void:
	load_databin.show()


func _on_load_biz_pressed() -> void:
	if not exe_path:
		OS.alert("Please load a valid exe first (SLPM_xxx.xx).")
		return
	load_biz_file.show()


func _on_load_biz_files_selected(paths: PackedStringArray) -> void:
	selected_bizs = paths
	load_folder.show()


func _on_load_hfu_2_bin_pressed() -> void:
	load_hfu_2bin.show()


func _on_load_hfu_2bin_files_selected(paths: PackedStringArray) -> void:
	selected_hfu2s = paths
	load_folder.show()
