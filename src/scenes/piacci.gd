extends Control

# 株式会社クオン dev is Kuon? Qon?

@onready var load_exe: FileDialog = $LoadEXE
@onready var load_tmz: FileDialog = $LoadTMZ
@onready var load_folder: FileDialog = $LoadFOLDER

var exe_path: String
var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extract_tmz()
		chose_folder = false
		chose_file = false
		selected_files.clear()

func extract_tmz() -> void:
	var entry_point: int = 0x1FFF00
	var in_file: FileAccess
	var out_file: FileAccess
	var exe_file: FileAccess
	var buff: PackedByteArray
	var f_name: String
	var f_offset: int
	var f_size: int
	var f_dec_size: int
	var tmz_tbl_start: int
	var tmz_tbl_end: int
	
	for file in range(selected_files.size()):
		if exe_path == "":
			OS.alert("Please load SLPM_669.20 first.")
			return
			
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file()
		
		if selected_files[file].get_file() == "BG.TMZ":
			tmz_tbl_start = 0x00257320 - entry_point
			tmz_tbl_end = 0x00259190 - entry_point
		elif selected_files[file].get_file() == "BU_S0.TMZ":
			tmz_tbl_start = 0x002a2c20 - entry_point
			tmz_tbl_end = 0x002A46F0  - entry_point
		elif selected_files[file].get_file() == "BU_S1.TMZ":
			tmz_tbl_start = 0x002A46F0 - entry_point
			tmz_tbl_end = 0x002A61B0  - entry_point
		elif selected_files[file].get_file() == "BU_S2.TMZ":
			tmz_tbl_start = 0x002A61B0 - entry_point
			tmz_tbl_end = 0x002A7C70  - entry_point
		elif selected_files[file].get_file() == "BU_M0.TMZ":
			tmz_tbl_start = 0x002A7C70 - entry_point
			tmz_tbl_end = 0x002A9790  - entry_point
		elif selected_files[file].get_file() == "BU_M1.TMZ":
			tmz_tbl_start = 0x002A9790 - entry_point
			tmz_tbl_end = 0x002AB250  - entry_point
		elif selected_files[file].get_file() == "BU_M2.TMZ":
			tmz_tbl_start = 0x002AB250 - entry_point
			tmz_tbl_end = 0x002ACD10  - entry_point
		elif selected_files[file].get_file() == "BU_L0.TMZ":
			tmz_tbl_start = 0x002ACD10 - entry_point
			tmz_tbl_end = 0x002AE7D0  - entry_point
		elif selected_files[file].get_file() == "BU_L1.TMZ":
			tmz_tbl_start = 0x002AE7D0 - entry_point
			tmz_tbl_end = 0x002B0290  - entry_point
		elif selected_files[file].get_file() == "BU_L2.TMZ":
			tmz_tbl_start = 0x002B0290 - entry_point
			tmz_tbl_end = 0x002B1D50  - entry_point
		elif selected_files[file].get_file() == "DAT.TMZ":
			tmz_tbl_start = 0x002B3750 - entry_point
			tmz_tbl_end = 0x002B4140  - entry_point
		
		for pos in range(tmz_tbl_start, tmz_tbl_end, 0x10):
			exe_file.seek(pos)
			var f_name_off: int = exe_file.get_32()
			f_offset = exe_file.get_32()
			f_size = exe_file.get_32()
			f_dec_size = exe_file.get_32()
			if f_dec_size < 0x00040440:
				f_dec_size = 0x00040440
			
			exe_file.seek(f_name_off - entry_point)
			f_name = exe_file.get_line() + ".TM2"
			
			in_file.seek(f_offset)
			buff = decompress_lz77(in_file.get_buffer(f_size), f_dec_size)
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + arc_name)
			
			out_file = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
			
			print("%08X %08X %s/%s/%s" % [f_offset, f_size, folder_path, arc_name, f_name])
	
	print_rich("[color=green]Finished![/color]")
	
	
func decompress_lz77(compressed: PackedByteArray, dec_size: int) -> PackedByteArray:
	var out: PackedByteArray
	var v0: int
	var v1: int
	var a0: int = 0 # in off
	var a1: int = compressed.size()
	var a2: int = 0 # out off
	var a3: int
	var t0: int 
	var t1: int
	var t2: int
	var t3: int
	var t4: int
	
	out.resize(dec_size)
	t3 = 0xFFFFFFFF
	a3 = 0xFFFFFF00
	t0 = 0x100
	t1 = 0x00010000
	var goto: String = "00252730"
	while true:
		match goto:
			"00252730":
				t3 = (t3 << 1) & 0xFFFFFFFF
				goto = "00252734"
			"00252734":
				v0 = t3 & t1
				v0 = v0 > 0
				v0 ^= 1
				if v0 != 0:
					goto = "00252768"
				else:
					a1 -= 1
					if a1 >= 0:
						v0 = compressed.decode_u8(a0)
						goto = "0025275C"
					else:
						break
			"0025275C":
				t3 = t0 | v0
				a0 += 1
				goto = "00252768"
			"00252768":
				v0 = t3 & 0x80
				if v0 == 0:
					goto = "00252790"
				else:
					v0 = compressed.decode_s8(a0)
					a1 -= 1
					out.encode_s8(a2, v0)
					a0 += 1
					goto = "00252730"
					a2 += 1
			"00252790":
				a1 -= 2
				if a1 >= 0:
					goto = "002527A4"
					v1 = compressed.decode_u8(a0)
				else:
					break
			"002527A4":
				v0 = compressed.decode_u8(a0 + 1)
				t2 = v1 & 0xF
				v1 <<= 4
				a0 += 2
				v1 = v1 & a3
				v0 = v1 | v0
				v1 = a2 - v0
				v0 = out.decode_s8(v1)
				t4 = v1 + 2
				out.encode_s8(a2, v0)
				v0 = out.decode_s8(v1 + 1)
				out.encode_s8(a2 + 1, v0)
				a2 += 2
				while t2 >= 0:
					v0 = out.decode_s8(t4)
					t2 -= 1
					out.encode_s8(a2, v0)
					t4 += 1
					a2 += 1
				goto = "00252734"
				t3 <<= 1
				
	return out


func _on_load_exe_pressed() -> void:
	load_exe.show()


func _on_load_tmz_pressed() -> void:
	load_tmz.show()


func _on_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_load_tmz_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	chose_file = true
	load_folder.show()


func _on_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
	chose_folder = true
