extends Control

@onready var zero_load_exe: FileDialog = $ZEROLoadEXE
@onready var zero_load_pac: FileDialog = $ZEROLoadPAC
@onready var zero_load_folder: FileDialog = $ZEROLoadFOLDER

var exe_path: String
var folder_path:String
var selected_file: String


func _ready() -> void:
	zero_load_exe.filters = [
	"SLPM_666.18,
	SLPM_669.42,SLPM_669.43,
	SLPM_656.07, SLPM_656.08,
	SLPM_656.71,
	SLPS_257.19,
	SLPM_659.68, SLPM_659.69,
	SLPM_664.40,
	SLPM_550.70, SLPM_550.71,
	SLPM_667.32, SLPM_667.33,
	SLPM_659.65,
	SLPS_256.70,
	SLPM_666.25,
	SLPM_663.76,
	SLPM_665.08,
	SLPM_668.60"]
	

func _process(_delta: float) -> void:
	if selected_file and folder_path:
		extractBin()
		selected_file = ""
		folder_path = ""
		
		
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
			elif exe_path.get_file() == "SLPM_669.42" or exe_path.get_file() == "SLPM_669.43": # Final Approach 2 - 1st Priority
				exe_start = 0xBDCD8
			elif exe_path.get_file() == "SLPM_656.07" or exe_path.get_file() == "SLPM_656.08": # 3LDK - Shiawase ni Narouyo
				exe_start = 0x91200
			elif exe_path.get_file() == "SLPM_656.71": # Double Wish
				exe_start = 0x9C940
			elif  exe_path.get_file() == "SLPS_257.19": # Happiness! De-Lucks
				exe_start = 0xF92B8
			elif exe_path.get_file() == "SLPM_659.68" or exe_path.get_file() == "SLPM_659.69": # Love Doll: Lovely Idol
				exe_start = 0xB0D48
			elif exe_path.get_file() == "SLPM_664.40": # Hokenshitsu he Youkoso
				exe_start = 0xADC10
			elif exe_path.get_file() == "SLPM_550.70" or exe_path.get_file() == "SLPM_550.71": # Yumemi Hakusho: Second Dream
				exe_start = 0xBBA48
			elif exe_path.get_file() == "SLPM_667.32" or exe_path.get_file() == "SLPM_667.33": # Iinazuke
				exe_start = 0xC0418
			elif exe_path.get_file() == "SLPM_659.65": # Magical Tale: Chiicha na Mahoutsukai
				exe_start = 0x9E658
			elif exe_path.get_file() == "SLPS_256.70": # School Rumble Ni-Gakki
				exe_start = 0xB7790
			elif exe_path.get_file() == "SLPM_666.25": # Trouble Fortune Company:  Happy Cure
				exe_start = 0xC3E60
			elif exe_path.get_file() == "SLPM_663.76": # KimiSuta: Kimi to Study
				exe_start = 0xB14F8
			elif exe_path.get_file() == "SLPM_665.08": # Otome no Jijou
				exe_start = 0xBEC78
			elif exe_path.get_file() == "SLPM_668.60": # Nettai Teikiatsu Shoujo
				exe_start = 0xBB6C0
			else:
				OS.alert("Unknown EXE found.")
				return
			
			exe_file = FileAccess.open(exe_path, FileAccess.READ)
			in_file = FileAccess.open(selected_file, FileAccess.READ)
			exe_file.seek(exe_start)
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
				
				if buff.slice(0, 3).get_string_from_ascii() == "LZS":
					f_size = buff.decode_u32(4)
					buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size)
					
				if type == 0x0A:
					f_name = "MOV%05d.PSS" % id
				elif type == 0x0C:
					f_name = "ANM%05d.BIN" % id
				elif type == 0xFA:
					var num: int = 0
					var i: int = 0
					var tak_data_start: int = buff.decode_u32(0)
					var tak_data_comp_size: int = buff.decode_u32(4)
					
					while tak_data_start != tak_data_comp_size:
						if buff.slice(tak_data_start, tak_data_start + 3).get_string_from_ascii() == "LZS":
							var tak_data: PackedByteArray = (PackedByteArray(buff.slice(tak_data_start, tak_data_start + tak_data_comp_size)))
							var tak_decomp_size: int = tak_data.decode_u32(4)
							tak_data = ComFuncs.decompLZSS(tak_data.slice(8), tak_data_comp_size, tak_decomp_size)
							
							if tak_data.slice(0, 4).get_string_from_ascii() == "TIM2":
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
						print("%08X %08X %s/%s" % [tak_data_start, tak_data_comp_size, folder_path, f_name])
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
						var arr: Array = upac_parse(buff)
						if arr[0]:
							f_name = "SRE%05d.TM2" % id
							f_size = arr[1]
							buff = arr[2]
						else:
							f_name = "SRE%05d.BIN" % id
							if arr[1] != 0:
								f_size = arr[1]
								buff = arr[2]
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
				
				print("%08X %08X %02X %s/%s" % [offset, f_size, type, folder_path, f_name])
				
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
					
					if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
						f_ext = ".TM2"
					elif buff.slice(0, 4).get_string_from_ascii() == "IECS":
						f_ext = ".HBD"
					else:
						f_ext = ".BIN"
					
					f_name = "/%08d" % f_id + f_ext
					out_file = FileAccess.open(folder_path + "%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					buff.clear()
					
					print("%08X %08X %s%s" % [offset, f_size, folder_path, f_name])
			else:
				in_file = FileAccess.open(selected_file, FileAccess.READ)
				
				if in_file.get_buffer(4).get_string_from_ascii() != "PAC":
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
					
					if buff.slice(0, 3).get_string_from_ascii() == "LZS":
						f_size = buff.decode_u32(4)
						buff = ComFuncs.decompLZSS(buff.slice(8), buff.size() - 8, f_size)
						
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
					buff.clear()
					
					print("%08X %08X %s/%s" % [offset, f_size, folder_path, f_name])
				
	print_rich("[color=green]Finished![/color]")
	
	
func upac_parse(buff: PackedByteArray) -> Array:
	var f_name: String
	var f_size: int = 0
	var is_tm2: bool = false
	
	if buff.slice(0, 4).get_string_from_ascii() == "UPAC":
		var start_off: int = buff.decode_u32(8)
		var unk_flag: int = buff.decode_u32(0xC)
		if buff.slice(start_off + 8, start_off + 11).get_string_from_ascii() == "LZS":
			f_size = buff.decode_u32(start_off + 0xC)
			buff = ComFuncs.decompLZSS(buff.slice(start_off + 0x10), buff.size() - start_off - 0x10, f_size)
			if buff.slice(0, 4).get_string_from_ascii() == "TIM2":
				is_tm2 = true
		else:
			if buff.slice(start_off + 8, start_off + 12).get_string_from_ascii() == "TIM2":
				is_tm2 = true
				
	var buffer: Array
	buffer.append(is_tm2)
	buffer.append(f_size)
	buffer.append(buff)
	return buffer
	
	
func _on_load_exe_pressed() -> void:
	zero_load_exe.show()


func _on_zero_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_load_pac_pressed() -> void:
	zero_load_pac.show()


func _on_zero_load_pac_file_selected(path: String) -> void:
	zero_load_folder.show()
	selected_file = path


func _on_zero_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
