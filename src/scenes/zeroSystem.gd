extends Control

@onready var zero_load_exe: FileDialog = $ZEROLoadEXE
@onready var zero_load_pac: FileDialog = $ZEROLoadPAC
@onready var zero_load_folder: FileDialog = $ZEROLoadFOLDER

var exe_path: String
var chose_folder:bool = false
var folder_path:String

var chose_pac:bool = false
var selected_file: String

var out_decomp:bool = false


func _process(_delta: float) -> void:
	if chose_pac and chose_folder:
		extractBin()
		chose_folder = false
		chose_pac = false
		selected_file = ""
	
	
func _on_load_exe_pressed() -> void:
	zero_load_exe.visible = true


func _on_zero_load_exe_file_selected(path: String) -> void:
	zero_load_exe.visible = false
	exe_path = path


func _on_load_pac_pressed() -> void:
	zero_load_pac.visible = true


func _on_zero_load_pac_file_selected(path: String) -> void:
	zero_load_pac.visible = false
	zero_load_folder.visible = true
	selected_file = path
	chose_pac = true


func _on_zero_load_folder_dir_selected(dir: String) -> void:
	zero_load_folder.visible = false
	folder_path = dir
	chose_folder = true
	
	
func extractBin() -> void:
	var f_name: String
	var hash1: int
	var hash2: int
	var offset: int
	var exe_start: int
	var exe_file: FileAccess
	var in_file: FileAccess
	var out_file: FileAccess
	var f_size: int
	var id: int
	var null_byte: int
	var null_32: int
	var type: int
	var buff: PackedByteArray
	var lzr_bytes: int
	var is_pac_bin: bool
	
	if selected_file.get_file() == "PAC.BIN":
		is_pac_bin = true
	elif selected_file.ends_with(".PAC"):
		is_pac_bin = false
	
	match is_pac_bin:
		true:
			if exe_path == "":
				OS.alert("Load an EXE (SLPM_XXX.XX) first.")
				return
				
			if exe_path.get_file() == "SLPM_666.18": # Yumemishi
				exe_start = 0xBB9E0
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_669.42" or exe_path.get_file() == "SLPM_669.43": # Final Approach 2 - 1st Priority
				exe_start = 0xBDCD8
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_656.07" or exe_path.get_file() == "SLPM_656.08": # 3LDK - Shiawase ni Narouyo
				exe_start = 0x91200
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_656.71": # Double Wish
				exe_start = 0x9C940
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif  exe_path.get_file() == "SLPS_257.19": # Happiness! De-Lucks
				exe_start = 0xF92B8
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_659.68" or exe_path.get_file() == "SLPM_659.69": # Love Doll: Lovely Idol
				exe_start = 0xB0D48
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_664.40": # Hokenshitsu he Youkoso
				exe_start = 0xADC10
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_550.70" or exe_path.get_file() == "SLPM_550.71": # Yumemi Hakusho: Second Dream
				exe_start = 0xBBA48
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_667.32" or exe_path.get_file() == "SLPM_667.33": # Iinazuke
				exe_start = 0xC0418
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_659.65": # Magical Tale: Chiicha na Mahoutsukai
				exe_start = 0x9E658
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPS_256.70": # School Rumble Ni-Gakki
				exe_start = 0xB7790
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_666.25": # Trouble Fortune Company:  Happy Cure
				exe_start = 0xC3E60
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_663.76": # KimiSuta: Kimi to Study
				exe_start = 0xB14F8
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_665.08": # Otome no Jijou
				exe_start = 0xBEC78
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			elif exe_path.get_file() == "SLPM_668.60": # Nettai Teikiatsu Shoujo
				exe_start = 0xBB6C0
				exe_file = FileAccess.open(exe_path, FileAccess.READ)
			else:
				OS.alert("Unknown EXE found.")
				return
			
			exe_file.seek(exe_start)
			in_file = FileAccess.open(selected_file, FileAccess.READ)
			while true:
				hash1 = exe_file.get_32()
				hash2 = exe_file.get_32()
				offset = exe_file.get_32() * 0x800
				f_size = exe_file.get_32()
				null_byte = exe_file.get_8()
				type = exe_file.get_8()
				id = exe_file.get_16()
				null_32 = exe_file.get_32()
				
				if f_size < 0 or f_size == 0xFFFFFFFF:
					break
					
				in_file.seek(offset)
				buff = in_file.get_buffer(f_size)
				
				lzr_bytes = ComFuncs.swapNumber(buff.decode_u32(0), "32")
				if lzr_bytes == 0x4C5A5300: #LZS
					f_size = buff.decode_u32(4)
					buff = buff.slice(8)
					buff = ComFuncs.decompLZSS(buff, buff.size(), f_size)
					
				if type == 0x0A:
					f_name = "MOV%05d.PSS" % id
				elif type == 0x0C:
					f_name = "ANM%05d.BIN" % id
				elif type == 0xFA:
					var num: int = 0
					var tak_data_start: int = buff.decode_u32(0)
					var tak_data_comp_size = buff.decode_u32(4)
					var i: int = 0
					
					while tak_data_start != tak_data_comp_size:
						var header_check: int = ComFuncs.swapNumber(buff.decode_u32(tak_data_start), "32")
						if header_check == 0x4C5A5300: #LZS
							var tak_data: PackedByteArray = (PackedByteArray(buff.slice(tak_data_start, tak_data_start + tak_data_comp_size)))
							var tak_decomp_size: int = tak_data.decode_u32(0x4)
							tak_data = tak_data.slice(8)
							tak_data = ComFuncs.decompLZSS(tak_data, tak_data_comp_size, tak_decomp_size)
							
							header_check = ComFuncs.swapNumber(tak_data.decode_u32(0), "32")
							if header_check == 0x54494D32: #TIM2
								f_name = "TAK%05d_%02d.TM2" % [id, num]
							else:
								f_name = "TAK%05d_%02d.BIN" % [id, num]
								
							out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(tak_data)
							out_file.close()
							tak_data.clear()
							i += 0xC
							num += 1
						else:
							var tak_data: PackedByteArray = (PackedByteArray(buff.slice(tak_data_start, tak_data_start + tak_data_comp_size)))
							
							f_name = "TAK%05d_%02d.BIN" % [id, num]
							out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
							out_file.store_buffer(tak_data)
							out_file.close()
							tak_data.clear()
							i += 0xC
							num += 1
						print("0x%08X " % tak_data_start + "0x%08X " % tak_data_comp_size + folder_path + "/%s" % f_name)
						tak_data_start = buff.decode_u32(i)
						tak_data_comp_size = buff.decode_u32(i + 4)
					f_name = "TAK%05d.BIN" % id
				elif type == 0x01:
					f_name = "VIS%05d.TM2" % id
				elif type == 0x02:
					f_name = "STR%05d.VGS" % id
				elif type == 0x06:
					f_name = "_SE%05d.HBD" % id
				elif type == 0x08:
					f_name = "VCE%05d.HBD" % id
				elif type == 0x10:
					# todo
					f_name = "SRE%05d.BIN" % id
				elif type == 0xFF:
					f_name = "DMY%05d.BIN" % id
				elif type == 0x67:
					f_name = "FNT%05d.BIN" % id
				else:
					f_name = "UNK%05d.BIN" % id
					
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				buff.clear()
				
				print("0x%08X " % offset + "0x%08X " % f_size + "0x%02X " % type + folder_path + "/%s" % f_name)
				
		false:
			if Main.game_type == Main.NATSUIROSUNADOKEI:
				var f_ext: String
				
				in_file = FileAccess.open(selected_file, FileAccess.READ)
				var pac_hed: FileAccess = FileAccess.open(selected_file.get_basename() + ".HED", FileAccess.READ)
				if pac_hed == null:
					OS.alert("Couldn't find .HED file for %s!" % selected_file)
					return
					
				var unk_32: int = pac_hed.get_32()
				var next_pos: int = pac_hed.get_position()
				while pac_hed.get_position() < pac_hed.get_length():
					pac_hed.seek(next_pos)
					offset = pac_hed.get_32()
					f_size = pac_hed.get_32()
					var f_id: int = pac_hed.get_32()
					
					next_pos = pac_hed.get_position()
					if pac_hed.eof_reached():
						break
					
					in_file.seek(offset)
					buff = in_file.get_buffer(f_size)
					
					var bytes: int = ComFuncs.swapNumber(buff.decode_u32(0), "32")
					if bytes == 0x54494D32:
						f_ext = ".TM2"
					elif bytes == 0x49454353:
						f_ext = ".HBD"
					else:
						f_ext = ".BIN"
					
					f_name = "/%08d" % f_id + f_ext
					out_file = FileAccess.open(folder_path + "%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					buff.clear()
					
					print("0x%08X " % offset + "0x%08X " % f_size + folder_path + "%s" % f_name)
			else:
				in_file = FileAccess.open(selected_file, FileAccess.READ)
				
				var pac_bytes: int = in_file.get_32()
				if pac_bytes != 0x00434150: #PAC
					OS.alert("Invalid PAC header.")
					return
					
				var name_tbl_off: int = in_file.get_32()
				var num_files: int = in_file.get_32()
				var file_tbl: int = in_file.get_position()
				
				for files in range(0, num_files):
					in_file.seek((files * 8) + file_tbl)
					offset = in_file.get_32()
					f_size = in_file.get_32()
					
					in_file.seek((files * 0x40) + name_tbl_off)
					f_name = in_file.get_line()
					
					in_file.seek(offset)
					buff = in_file.get_buffer(f_size)
					
					lzr_bytes = ComFuncs.swapNumber(buff.decode_u32(0), "32")
					if lzr_bytes == 0x4C5A5300: #LZS
						f_size = buff.decode_u32(4)
						buff = buff.slice(8)
						buff = ComFuncs.decompLZSS(buff, buff.size(), f_size)
						
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					buff.clear()
					
					print("0x%08X " % offset + "0x%08X " % f_size + folder_path + "/%s" % f_name)
				

	print_rich("[color=green]Finished![/color]")
