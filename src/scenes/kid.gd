extends Control

@onready var file_load_afs: FileDialog = $FILELoadAFS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var chose_file: bool = false
var chose_folder: bool = false
var debug_out: bool = false
var remove_alpha: bool = true

var scr_names: PackedStringArray

func _ready() -> void:
	#var in_file: FileAccess = FileAccess.open("G:/SLPM_668.64", FileAccess.READ)
	#var ent_pnt: int = 0xFF000
	#var tbl_s: int = 0x001c12e0 - ent_pnt
	#var tbl_e: int = 0x001c1390 - ent_pnt
	#var off: int = tbl_s
	#while off < tbl_e:
		#in_file.seek(off)
		#var scr_off: int = in_file.get_32()
		#if scr_off == 0:
			#break
		#scr_off -= ent_pnt
		#
		#in_file.seek(scr_off)
		#print(in_file.get_line() + ",")
		#off += 4
	if Main.game_type == Main.KANOKON:
		scr_names = [
		"macrosys.scr", "macrosys2.scr", "main00.scr", "mstart.scr",
		"S1_00A.scr", "S1_00B.scr", "S1_00C.scr", "S1_00D.scr", "S1_00E.scr", "S1_00F.scr", "S1_00G.scr", "S1_00H.scr", "S1_00I.scr", "S1_00J.scr",
		"S1_00K.scr", "S1_00L.scr", "S1_00M.scr", "S1_00N.scr", "S1_00O.scr", "S1_00P.scr", "S1_00Q.scr", "S1_00R.scr", "S1_00S.scr",
		"S2_00A.scr", "S2_00B.scr", "S2_00C.scr", "S2_00D.scr", "S2_00E.scr", "S2_00F.scr", "S2_00G.scr", "S2_00H.scr", "S2_00I.scr", "S2_00J.scr",
		"S2_00K.scr", "S2_00L.scr", "S2_00M.scr", "S2_00N.scr", "S2_00O.scr", "S2_00P.scr", "S2_00Q.scr", "S2_03A.scr", "S2_05A.scr",
		"S3_00A.scr", "S3_00B.scr", "S3_00C.scr", "S3_00D.scr", "S3_00E.scr", "S3_00F.scr", "S3_00G.scr", "S3_00H.scr", "S3_00I.scr", "S3_00J.scr",
		"S3_00K.scr", "S3_00L.scr", "S3_00M.scr", "S3_00N.scr", "S3_00O.scr", "S3_00P.scr", "S3_00Q.scr", "S3_01A.scr", "S3_01B.scr", "S3_01C.scr",
		"S3_01D.scr", "S3_01E.scr", "S3_01F.scr", "S3_04A.scr", "S3_05A.scr",
		"S4_00A.scr", "S4_00B.scr", "S4_00C.scr", "S4_00D.scr", "S4_00E.scr", "S4_00F.scr", "S4_00G.scr", "S4_00H.scr", "S4_00I.scr", "S4_00J.scr",
		"S4_00K.scr", "S4_01A.scr", "S4_01B.scr", "S4_01C.scr", "S4_01D.scr", "S4_01E.scr", "S4_02A.scr", "S4_03A.scr", "S4_04A.scr", "S4_05A.scr",
		"S5_00A.scr", "S5_00B.scr", "S5_01A.scr", "S5_01B.scr", "S5_01C.scr", "S5_01D.scr", "S5_01E.scr", "S5_01F.scr", "S5_01G.scr", "S5_02A.scr",
		"S5_02B.scr", "S5_02C.scr", "S5_02D.scr", "S5_02E.scr", "S5_03A.scr", "S5_03B.scr", "S5_04A.scr", "S5_04B.scr", "S5_05A.scr", "S5_05B.scr",
		"S5_06A.scr", "S5_06B.scr", "S5_07A.scr",
		"S6_01A.scr", "S6_01B.scr", "S6_01C.scr", "S6_01D.scr", "S6_01E.scr", "S6_02A.scr", "S6_02B.scr", "S6_02C.scr", "S6_03A.scr", "S6_03B.scr",
		"S6_03C.scr", "S6_03D.scr", "S6_04A.scr", "S6_04B.scr", "S6_05A.scr", "S6_05B.scr",
		"S7_01A.scr", "S7_02A.scr", "S7_03A.scr", "S7_04A.scr", "S7_05A.scr",
		"Startup.scr", "system.scr",
		"Xcharatest.scr", "XDBG00.scr", "XDBG01.scr", "XDBG02.scr", "XDBG03.scr", "XDMENU.scr", "ZZZ.scr"
		]
	elif Main.game_type == Main.NURSEWITCH:
		scr_names = [
		"komugi1.scr", "komugi1a.scr", "komugi2.scr", "komugi2a.scr",
		"komugi3.scr", "komugi3a.scr", "komugi4.scr", "komugi4a.scr",
		"macrosys.scr", "macrosys2.scr", "mstart.scr", "Startup.scr",
		"system.scr", "zzz.scr"
		]
	elif Main.game_type == Main.CARTAGRA:
		scr_names = [
		"0000_00_00.scr", "0206_01_00.scr", "0206_03_00.scr", "0206_06_00.scr",
		"0206_10_00.scr", "0207_00_00.scr", "0207_05_00.scr", "0207_12_00.scr",
		"0208_01_00.scr", "0208_04_00.scr", "0208_12_00.scr", "0208_15_00.scr",
		"0209_01_00.scr", "0209_09_00.scr", "0210_01_00.scr", "0210_04_00.scr",
		"0210_07_00.scr", "0210_08_00.scr", "0210_09_00.scr", "0210_10_00.scr",
		"0210_10_01.scr", "0210_NN_00.scr", "0214_00_00.scr", "0214_00_01.scr",
		"0214_02_00.scr", "0214_03_05.scr", "0214_YR_00.scr", "0215_00_00.scr",
		"0215_03_00.scr", "0215_04_00.scr", "0215_05_00.scr", "0215_06_00.scr",
		"0215_07_00.scr", "0215_10_00.scr", "0215_TW_00.scr", "0215_TW_01.scr",
		"0215_TW_02.scr", "0215_TW_08.scr", "0215_TW_09.scr", "0216_00_00.scr",
		"0216_01_00.scr", "0216_02_00.scr", "0216_04_03H.scr", "0216_04_04.scr",
		"0216_04_05.scr", "0216_05_05ED.scr", "0217_01_00.scr", "0217_01_09.scr",
		"0217_02_00.scr", "0217_02_02.scr", "0217_02_03.scr", "0217_02_04.scr",
		"0217_02_09.scr", "0217_HT_00.scr", "0217_HT_02.scr", "0217_YR_00.scr",
		"0217_YR_01.scr", "0218_01_00.scr", "0218_02_00.scr", "0218_02_04.scr",
		"0218_02_05.scr", "0219_02_00.scr", "0219_02_02.scr", "0219_SH_00.scr",
		"0219_TK_00.scr", "0220_02_00.scr", "0220_02_04.scr", "0220_02_05.scr",
		"0220_02_07.scr", "0220_02_08.scr", "0220_02_10.scr", "0220_02_13.scr",
		"0220_SH_01.scr", "0220_TK_00.scr", "0220_TK_ED.scr", "0220_TK_EP.scr",
		"0220_YR_00.scr", "0221_02_00.scr", "0221_02_02.scr", "0222_02_00.scr",
		"0222_02_12.scr", "0222_02_13.scr", "0222_TJ_00.scr", "0222_TJ_01.scr",
		"0222_TJ_02.scr", "0223_01_00.scr", "0223_01_01.scr", "0308_01_00.scr",
		"0308_01_01.scr", "0308_02_00.scr", "0308_KZ_ED.scr", "0308_YR_00.scr",
		"0308_YR_ED.scr", "macrosys.scr", "macrosys2.scr", "MAIN00.scr",
		"mstart.scr", "Startup.scr", "system.scr", "ZZZ.scr"
		]
	elif Main.game_type == Main.UMISHO:
		scr_names = [
		"astable.scr", "macrosys.scr", "macrosys2.scr", "main00.scr", "mstart.scr",
		"S1_00.scr", "S2_03.scr", "S2_04.scr", "S3_00.scr", "S3_01.scr",
		"S3_02.scr", "S3_03.scr", "S3_04.scr", "S3_06.scr", "S4_01.scr",
		"S4_02.scr", "S4_03.scr", "S4_04.scr", "S5_00.scr", "S6_01.scr",
		"S6_02.scr", "S6_03.scr", "S6_04.scr", "S7_00.scr", "S7_01.scr",
		"S7_02.scr", "S7_03.scr", "S7_04.scr", "S8_00.scr", "S8_01.scr",
		"S8_02.scr", "S8_03.scr", "S8_04.scr", "S8_05.scr", "S8_06.scr",
		"Startup.scr", "system.scr", "Xcharatest.scr", "XDBG00.scr", "XDBG01.scr",
		"XDBG02.scr", "XDBG03.scr", "XDMENU.scr", "ZZZ.scr"
		]
	elif Main.game_type == Main.AIYORIAOSHI:
		scr_names = [
		"ai01.scr", "ai02.scr", "ai03.scr", "ai04.scr", "aoi01.scr", "aoi02.scr", "aoi03.scr", "aoi04.scr",
		"aoi05.scr", "aoi06.scr", "aoi07.scr", "aoi08.scr", "aoi09.scr", "aoi10.scr", "aoi11.scr", "aoi12.scr",
		"aoi13.scr", "aoi14.scr", "aoi15.scr", "aoi16.scr", "aoi17.scr", "aoi18.scr", "aoi19.scr", "macrosys.scr",
		"may01.scr", "may02.scr", "mstart.scr", "op01.scr", "op02.scr", "startup.scr", "system.scr", "tae01.scr",
		"tae02.scr", "tati01.scr", "tati02.scr", "tati03.scr", "tati04.scr", "tati05.scr", "tati06.scr", "tati07.scr",
		"tati08.scr", "tik01.scr", "tik02.scr", "tima01.scr", "tima02.scr", "tima03.scr", "tima04.scr", "tima05.scr",
		"tima06.scr", "tima07.scr", "tima08.scr", "tima09.scr", "tima10.scr", "tima11.scr", "tima12.scr", "tima13.scr",
		"tin01.scr", "tin02.scr", "tin03.scr", "tin04.scr", "tin05.scr", "tin06.scr", "zzz.scr"
		]
		# These are from some other game?
		#scr_names = [
		#"21225_01", "k1101_02", "ura_n", "11128_02", "01122_05", "21226_01", "info_03", "11213_01",
		#"11102_01", "k1102_01", "open_01", "61217_01", "41116_01", "61121_01", "h1222_01", "00201_01",
		#"k1102_02", "01223_02", "01130_02", "k1108_02", "51114_01", "01031_02", "01115_01", "11207_01",
		#"01121_01", "01122_03", "01122_02", "01122_01", "open_04", "01122_04", "01126_01", "01122_06",
		#"01202_01", "01224_01", "41224_01", "51203_01", "01130_06", "01201_01", "k1111_02", "01206_02",
		#"01212_02", "01210_01", "10109_01", "11101_01", "01219_02", "51208_02", "01221_02", "01223_01",
		#"11109_01", "11205_01", "21224_03", "41107_01", "11103_01", "11128_01", "11120_03", "11123_01",
		#"11127_01", "11124_01", "11214_01", "21203_01", "11203_02", "11217_01", "50109_01", "11112_01",
		#"11209_01", "21224_02", "11129_01", "11222_02", "11219_01", "11220_01", "11224_03", "21207_02",
		#"11224_01", "11120_02", "41119_01", "51206_01", "21202_01", "21204_01", "21210_01", "21206_01",
		#"21207_01", "21217_02", "21217_01", "21214_01", "21221_02", "61115_01", "21221_01", "31203_01",
		#"21223_01", "21224_01", "31202_01", "01129_01", "h1113_02", "31224_03", "open_07", "31207_01",
		#"31204_01", "11224_04", "31210_01", "31222_01", "31217_01", "31219_01", "31223_01", "11231_01",
		#"31224_01", "31224_02", "01125_01", "open_03", "info_06", "61107_01", "61216_01", "41107_02",
		#"41114_02", "41119_02", "41114_01", "51110_01", "51202_01", "51112_01", "41105_01", "41125_01",
		#"51224_03", "ura_e", "31225_02", "sel_01", "01031_01", "51118_01", "61206_01", "info_02",
		#"51124_01", "ura_y", "open_05", "51215_01", "51212_01", "h1117_01", "51219_01", "51217_01",
		#"51224_02", "51221_02", "51221_01", "31225_01", "51224_01", "h1119_01", "01107_01", "61129_01",
		#"61109_01", "k1112_02", "51207_01", "h1114_01", "61122_01", "61202_02", "21225_02", "61213_01",
		#"h1112_01", "61219_01", "61214_01", "info_04", "h1111_01", "h1104_02", "11224_05", "h1104_01",
		#"info_05", "01215_01", "k1104_01", "h1106_01", "h1118_01", "k1108_01", "51208_01", "01102_01",
		#"01104_01", "h1115_02", "h1116_01", "k1123_01", "h1117_02", "61125_01", "k1105_02", "k1104_02",
		#"info_01", "k1115_01", "41111_01", "k1101_01", "01108_01", "k1115_02", "k1111_01", "k1103_01",
		#"k1103_02", "k1107_01", "60101_01", "k1105_01", "k1127_01", "k1106_01", "k1106_02", "k1109_01",
		#"k1107_02", "open_02", "01208_01", "k1114_02", "k1109_02", "k1110_01", "k1110_02", "k1112_01",
		#"k1119_01", "k1114_01", "h1115_01", "k1113_02", "k1113_01", "sel_00", "open_06", "k1119_02",
		#"k1117_01", "k1116_01", "k1116_02", "k1117_02", "k1125_01", "k1118_02", "k1121_02", "k1121_01",
		#"51115_01", "k1120_01", "k1120_02", "k1122_01", "k1128_01", "k1122_02", "k1124_01", "k1118_01",
		#"k1123_02", "k1124_02", "ura_a", "k1125_02", "61224_01", "k1126_01", "k1126_02", "k1127_02",
		#"baded_01", "61221_01", "k1128_02", "k1129_01", "00214_01", "01111_01", "01130_05", "31214_01",
		#"01101_01", "Startup", "System"
		#]


func _process(_delta: float) -> void:
	if chose_file and chose_folder:
		extract_arcs()
		selected_files.clear()
		chose_file = false
		chose_folder = false
	
	
func extract_arcs() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var arc_name: String
	var buff: PackedByteArray
	var num_files: int
	var off_tbl: int
	var name_tbl: int
	var name_tbl_size: int
	var f_offset: int
	var f_name: String
	var f_size: int
	var f_ext: String
	var ext: String
	
	for file in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		arc_name = selected_files[file].get_file().get_basename()
		
		if selected_files[file].get_extension().to_lower() == "afs":
			in_file.seek(4)
			num_files = in_file.get_32()
			
			off_tbl = 8
			
			in_file.seek((num_files * 8) + off_tbl)
			name_tbl = in_file.get_32()
			name_tbl_size = in_file.get_32()
			
			if name_tbl == 0 or name_tbl_size == 0:
				# check for odd cases where name table isn't the last in the offset table
				in_file.seek(8)
				f_offset = in_file.get_32()
				
				in_file.seek(f_offset - 8)
				name_tbl = in_file.get_32()
				name_tbl_size = in_file.get_32()
				if name_tbl == 0 or name_tbl_size == 0:
					print_rich("[color=red]Couldn't find name table in %s" % selected_files[file])
			
			for files in range(num_files - 1):
				in_file.seek((files * 8) + off_tbl)
				
				f_offset = in_file.get_32()
				f_size = in_file.get_32()
				
				if name_tbl != 0 or name_tbl_size != 0:
					in_file.seek((files * 0x30) + name_tbl)
					f_name = in_file.get_line()
					f_ext = f_name.get_extension()
				else:
					f_name = "%04d" % files
					
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				if f_ext == "KLZ":
					if debug_out:
						out_file = FileAccess.open(folder_path + "/%s" % f_name + ".COMP", FileAccess.WRITE)
						out_file.store_buffer(buff)
						
					buff = lzh_decode_mips(buff)
					
					var bytes: int = buff.decode_u32(0)
					if bytes == 0x324D4954: #TIM2
						#f_name += ".TM2"
						out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
						out_file.store_buffer(buff)
						
						# TIM2 search
						ComFuncs.tim2_scan_file(FileAccess.open(folder_path + "/%s" % f_name, FileAccess.READ))
						
						print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
						continue
					else:
						f_name += ".BIN"
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				
				print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
		elif selected_files[file].get_extension().to_lower() == "dat":
			var start_off: int = 0x8000
			var f_id: int = 0
			var pos: int = 0
			while true:
				in_file.seek(pos)
				f_name = "%04d" % f_id
				f_offset = (in_file.get_32() * 0x800) + start_off
				f_size = (in_file.get_32() * 0x800)
				if f_size == 0:
					break
				
				if arc_name == "SCRIPT" and scr_names:
					f_name = scr_names[f_id]
					
				print("%08X %08X /%s/%s/%s" % [f_offset, f_size, folder_path, arc_name, f_name])
				
				var dir: DirAccess = DirAccess.open(folder_path)
				dir.make_dir_recursive(folder_path + "/" + arc_name)
					
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				if buff.slice(0, 3).get_string_from_ascii() == "CPS":
					buff = GSLmeltData(buff)
					
					if debug_out:
						out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % f_name + ".DEC", FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
						
					var w: int = buff.decode_u16(0)
					var h: int = buff.decode_u16(2)
					var bpp: int = buff.decode_u32(4)
					
					if bpp == 8:
						var palette: PackedByteArray = ComFuncs.unswizzle_palette(buff.slice(8, 0x408), 32)
						var pixel_data: PackedByteArray = buff.slice(0x408, 0x408 + w * h)
						var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
						for y in range(h):
							for x in range(w):
								var pixel_index: int = pixel_data[x + y * w]
								var r: int = palette[pixel_index * 4 + 0]
								var g: int = palette[pixel_index * 4 + 1]
								var b: int = palette[pixel_index * 4 + 2]
								#var a: int = palette[pixel_index * 4 + 3]
								image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
						f_name += ".PNG"
						image.save_png(folder_path + "/" + arc_name + "/%s" % f_name)
					elif bpp == 24:
						buff = buff.slice(8, buff.size() - 8)
						if remove_alpha:
							for i in range(0, buff.size(), 4):
								buff.encode_u8(i + 3, 255)
						var image: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, buff)
						f_name += ".PNG"
						image.save_png(folder_path + "/" + arc_name + "/%s" % f_name)
					else:
						out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % f_name + ".UNK", FileAccess.WRITE)
						out_file.store_buffer(buff)
						out_file.close()
				elif buff.slice(0, 3).get_string_from_ascii() == "SC3":
					if not scr_names:
						f_name += ".scr"
					out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				else:
					f_name += ".BIN"
					out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				
				pos += 8
				f_id += 1
				
	print_rich("[color=green]Finished![/color]")
	
	
func GSLmeltData(buff: PackedByteArray) -> PackedByteArray:
	# Function name taken from debug name in Ai yori Aoshi
	# In Ai Yori Aoshi, name offsets appear to be at memory address 0x001bcc00
	# but don't seem to match. Might be an old list.
	
	var dec_keys: Array[int]
	var in_pos: int
	var needs_keys: bool
	
	if Main.game_type == Main.KANOKON:
		needs_keys = true
		dec_keys = [
		0x2623A189, 0x146FD8D7, 0x8E6F55FF, 0x1F497BCD,
		0x1BB74F41, 0x0EB731D1, 0x5C031379, 0x64350881
		]
	elif Main.game_type == Main.CARTAGRA:
		needs_keys = true
		dec_keys = [
		0xB739A245, 0x9D95B93F, 0x44C3F5DF, 0x0E870733,
		0xDBB9EA9B, 0x7C31C2ED, 0x5D95284D, 0x14C5ACCB
		]
	elif Main.game_type == Main.UMISHO:
		needs_keys = true
		dec_keys = [
		0xBB6F4087, 0x16219633, 0xD1656A1D, 0xD0A7470B,
		0x89F3412F, 0x92E7C23B, 0xFC7F5E3D, 0x197B6D41
		]
	else:
		needs_keys = false
	
	if needs_keys:
		in_pos = 0x28
		
		var k_cnt: int = dec_keys.size()
		var comp_len: int = buff.decode_u32(4)
		var seed_off: int = buff.decode_u32(comp_len - 4) - 0x7534682
		var s_idx: int = seed_off / 4
		var seed: int = buff.decode_u32(s_idx * 4) + seed_off + 0x3786425
		
		for i in range(8, min(1023, buff.size() / 4)):
			if i != s_idx:
				buff.encode_u32(i * 4, buff.decode_u32(i * 4) - dec_keys[i % k_cnt] - seed - comp_len)
			seed = ((seed * 0x41C64E6D) + 0x9B06) & 0xFFFFFFFF
	else:
		in_pos = 0x1C
	
	var out_len: int = buff.decode_u32(0xC)
	var out: PackedByteArray = PackedByteArray()
	out.resize(out_len)
	
	var out_pos: int = 0
	var i: int
	
	while out_pos < out_len:
		var control: int = buff[in_pos]
		in_pos += 1
		if control & 0x80:
			if control & 0x40:
				i = (control & 0x1F) + 2
				if control & 0x20:
					i += buff[in_pos] << 5
					in_pos += 1
				while i > 0:
					out[out_pos] = buff[in_pos]
					out_pos += 1
					i -= 1
				in_pos += 1
			else:
				var mod: int = ((control & 3) << 8) | buff[in_pos]
				in_pos += 1
				i = ((control >> 2) & 0xF) + 2
				while i > 0:
					out[out_pos] = out[out_pos - mod - 1]
					out_pos += 1
					i -= 1
		else:
			if control & 0x40:
				var num_bytes: int = buff[in_pos] + 1
				in_pos += 1
				var copy_len: int = (control & 0x3F) + 2
				var block: PackedByteArray = buff.slice(in_pos, in_pos + copy_len)
				in_pos += copy_len
				for rep in range(num_bytes):
					for copy_pos in range(copy_len):
						out[out_pos] = block[copy_pos]
						out_pos += 1
			else:
				i = (control & 0x1F) + 1
				if control & 0x20:
					i += buff[in_pos] << 5
					in_pos += 1
				while i > 0:
					out[out_pos] = buff[in_pos]
					out_pos += 1
					in_pos += 1
					i -= 1
					
	var f_buff: PackedByteArray
	if needs_keys:
		f_buff = PackedByteArray(buff.slice(0x20, 0x28))
	else:
		f_buff = PackedByteArray(buff.slice(0x14, 0x1C))
	f_buff.append_array(out)
	return f_buff
	
	
func lzh_decode_mips(input: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray
	var f_out: PackedByteArray
	var output_size: int = ComFuncs.swap32(input.decode_u32(0))
	var fill_count: int = ComFuncs.swapNumber(input.decode_u16(4), "16")
	var at: int = 0
	var v0: int
	var v1: int
	var a0: int
	var s0: int = 0
	var s1: int = 0
	var s2: int = 0
	var s3: int = 0
	var OO40_sp: int = 0
	var OO42_sp: int = 0
	var OO44_sp: int
	var OO48_sp: int
	var OO50_sp: int = 0 #out buffer address
	var OO60_sp: int = 0
	var OO70_sp: int = fill_count
	var next_read_pos: int = 0
	var count: int = 0
	var num_passes: int = 0
	var decode_table: PackedByteArray = [
		0x01, 0x02, 0x04, 0x08,
		0x10, 0x20, 0x40, 0x80,
		# Only first 8 are used
		0x81, 0x75, 0x81, 0x69,
		0x00, 0x00, 0x00, 0x00,
		0x01, 0x02, 0x00, 0x00
	]
	
	out.resize(0x4000)
	if fill_count > 0x4000:
		next_read_pos = 4
		while OO70_sp > 0x4000:
			var cnt: int = 0
			var copy_off: int = next_read_pos + 2
			while cnt < 0x4000:
				f_out.append(input.decode_u8(copy_off))
				cnt += 1
				copy_off += 1
			count += 0x4000
			next_read_pos += cnt + 2
			num_passes += 1
			OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
			if count >= output_size or next_read_pos >= input.size():
				return f_out
			OO60_sp = next_read_pos + 2
	else:
		OO60_sp = 6
		
	OO44_sp = OO60_sp
	v0 = OO60_sp + 1
	OO48_sp = v0
	while true:
		v0 = input.decode_u8(OO44_sp)
		a0 = v0 & 0xFF
		v0 = OO40_sp
		v1 = v0 & 0xFF
		v0 = decode_table[v1] & 0xFF
		v0 &= a0
		# 001BA8AC
		if v0 == 0:
			v1 = input.decode_u8(OO48_sp)
			v0 = OO50_sp + s0
			out.encode_s8(v0, v1)
			OO48_sp += 1
			OO42_sp += 1
			s0 += 1
		elif v0 != 0:
			# 001BA8F0
			OO42_sp += 2
			v0 = input.decode_u8(OO48_sp) & 0xFF
			v1 = v0 << 8
			v0 = input.decode_u8(OO48_sp + 1) & 0xFF
			v0 = v1 | v0
			v0 &= 0xFFFF
			s2 = v0 & 0xFFFF
			v0 = s2 & 0xFFFF
			v0 &= 0x1F
			v0 += 2
			v0 &= 0xFFFF
			s3 = v0 & 0xFFFF
			v0 = s2 & 0xFFFF
			v0 >>= 5
			v0 &= 0xFFFF
			s1 = v0 & 0xFFFF
			v0 = s1 & 0xFFFF
			v0 = s0 - v0
			v0 -= 1
			v0 &= 0xFFFF
			s1 = v0 & 0xFFFF
			OO48_sp += 1
			v0 = 1
			while v0 != 0: 
				at = s0 < 0x0800
				# 001BA96C
				if at != 0:
					v0 = s1 & 0xFFFF
					at = s0 < v0
					if at != 0:
						v1 = out.decode_u8(OO50_sp)
						v0 = OO50_sp + s0
						out.encode_s8(v0, v1)
						s0 += 1
						v0 = s1 + 1
						s1 = v0 & 0xFFFF
						# 001BA9D8
						v1 = s3
						v0 = v1 - 1
						s3 = v0 & 0xFFFF
						v0 = v1 & 0xFFFF
						continue
				# 001BA9B0
				v1 = s1 & 0xFFFF
				v0 = OO50_sp
				v0 += v1
				v1 = out.decode_u8(v0)
				v0 = OO50_sp
				v0 += s0
				out.encode_s8(v0, v1)
				s0 += 1
				v0 = s1 + 1
				s1 = v0 & 0xFFFF
				# 001BA9D8
				v1 = s3
				v0 = v1 - 1
				s3 = v0 & 0xFFFF
				v0 = v1 & 0xFFFF
						
			OO48_sp += 1
		# 001BAA00
		OO40_sp += 1
		v1 = OO40_sp & 0xFF
		v0 = 8
		if v1 == v0:
			OO40_sp = 0
			OO44_sp = OO48_sp
			OO48_sp += 1
			OO42_sp += 1
		v0 = OO42_sp
		v1 = v0 & 0xFFFF
		v0 = OO70_sp
		v0 -= 1
		v0 = v1 < v0
		if v0 == 0:
			count += s0
			if count >= output_size or next_read_pos >= input.size():
				f_out.append_array(out)
				return f_out
			num_passes += 1
			if num_passes == 1:
				next_read_pos += OO70_sp + 6
			else:
				next_read_pos += OO70_sp + 2
				
			f_out.append_array(out)
			#out.fill(0)
			#print("%X, %X, %X, %X, Next read pos: %X" % [s0, s1, OO70_sp, count, next_read_pos])
			#print_rich("[color=yellow]Last pass: Num passes: %d, Addresses: %X, %X, %X, %X, %X, %X, %X[/color]" % [num_passes, OO40_sp, OO42_sp, OO44_sp, OO48_sp, OO50_sp, OO60_sp, OO70_sp])
			OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
			if OO70_sp > 0x4000:
				while OO70_sp > 0x4000:
					var cnt: int = 0
					var copy_off: int = next_read_pos + 2
					while cnt < 0x4000:
						f_out.append(input.decode_u8(copy_off))
						cnt += 1
						copy_off += 1
					count += 0x4000
					next_read_pos += cnt + 2
					OO70_sp = ComFuncs.swapNumber(input.decode_u16(next_read_pos), "16")
					if count >= output_size or next_read_pos >= input.size():
						return f_out
				
			s0 = 0
			s1 = 0
			OO50_sp = 0
			OO42_sp = 0
			OO48_sp = next_read_pos + 2
			if OO48_sp > input.size():
				return f_out
			OO40_sp = 0
			OO60_sp = OO48_sp
			OO44_sp = OO60_sp
			v0 = OO60_sp + 1
			OO48_sp = v0
			#print_rich("[color=orange]This pass: Addresses: %X, %X, %X, %X, %X, %X, %X, This read pos: %X[/color]" % [OO40_sp, OO42_sp, OO44_sp, OO48_sp, OO50_sp, OO60_sp, OO70_sp, next_read_pos + 2])
			
	return f_out


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_load_afs_pressed() -> void:
	file_load_afs.visible = true


func _on_file_load_afs_files_selected(paths: PackedStringArray) -> void:
	file_load_afs.visible = false
	file_load_folder.visible = true
	chose_file = true
	selected_files = paths


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir


func _on_remove_alpha_toggled(_toggled_on: bool) -> void:
	remove_alpha = !remove_alpha
