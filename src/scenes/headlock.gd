extends Control

@onready var file_load_dat: FileDialog = $FILELoadDAT
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var debug_out: bool = false

func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract_dat()
		selected_files.clear()
		folder_path = ""
		

func extract_dat() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var dat_hdr: PackedByteArray
	var hdr_size: int
	var hdr_dec_size: int
	var dat_hdr_name: String
	var dec_size_key: int = 0x1F84C9AF
	var comp_size_key: int = 0x9ED835AB
	var f_name: String
	var f_name_off: int
	var f_offset: int
	var f_dec_size: int
	var f_size: int
	var shift_jis_dic: Dictionary = ComFuncs.make_shift_jis_dic()
	var name_align: int
	var is_enc: bool
	var dat_names: PackedStringArray = [
		# Archives that don't need file decryption / decompression
		"DATA06",
		"DATA07",
		"DATA08",
		"DATA09"
	]
	
	if Main.game_type == Main.PRINCESSCONCERTO:
		name_align = 1
	else:
		name_align = 0
	
	for file in range(0, selected_files.size()):
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		dat_hdr_name = selected_files[file].get_file() + ".HED"
		
		if arc_name == "DATA10" or arc_name == "OP":
			OS.alert("DATA10.DAT / OP.DAT is just a .PSS movie file :)")
			continue
		elif arc_name == "DATA00" and (Main.game_type == Main.MEITANTEIEVA or Main.game_type == Main.SHINSEIKIEVABATTLE):
			continue
			
		if arc_name in dat_names:
			is_enc = false
		else:
			is_enc = true
			
		in_file.seek(0)
		f_dec_size = in_file.get_32() ^ dec_size_key
		f_size = in_file.get_32() ^ comp_size_key
		
		in_file.seek(0)
		dat_hdr = decrypt_file(in_file.get_buffer(f_size + 0xC), f_size, f_dec_size)
		dat_hdr = ComFuncs.decompLZSS(dat_hdr.slice(0xC), f_size, f_dec_size)
		if debug_out:
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + arc_name)
			out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % dat_hdr_name, FileAccess.WRITE)
			out_file.store_buffer(dat_hdr)
			out_file.close()
		
		hdr_size = f_size
		hdr_dec_size = f_dec_size
		var hdr_pos: int = 0
		while hdr_pos < hdr_dec_size:
			var f_name_size: int = dat_hdr.decode_u32(hdr_pos)
			var f_hash: int = dat_hdr.decode_u32(hdr_pos + 4)
			f_offset = dat_hdr.decode_u32(hdr_pos + 8) + hdr_size + 0xC
			f_name = ComFuncs.convert_jis_packed_byte_array(dat_hdr.slice(hdr_pos + 0xC, hdr_pos + 0xC + f_name_size), shift_jis_dic).get_string_from_utf8()
			
			in_file.seek(f_offset)
			f_dec_size = in_file.get_32() ^ dec_size_key
			f_size = in_file.get_32() ^ comp_size_key
			
			print("%08X %08X %08X /%s/%s/%s" % [f_offset, f_dec_size, f_size, folder_path, arc_name, f_name])
			
			in_file.seek(f_offset)
			if is_enc and f_size == 0:
				buff = decrypt_file(in_file.get_buffer(f_dec_size + 0xC), f_dec_size, f_dec_size)
				buff = buff.slice(0xC)
			elif is_enc:
				buff = decrypt_file(in_file.get_buffer(f_size + 0xC), f_size, f_dec_size)
				buff = ComFuncs.decompLZSS(buff.slice(0xC), f_size, f_dec_size)
			else:
				# Not encrypted file, only sizes are.
				buff = in_file.get_buffer(f_dec_size + 0xC)
				buff = buff.slice(0xC)
			
			var dir: DirAccess = DirAccess.open(folder_path)
			dir.make_dir_recursive(folder_path + "/" + arc_name + "/%s" % f_name.get_base_dir())
				
			out_file = FileAccess.open(folder_path + "/" + arc_name + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buff)
			out_file.close()
		
			hdr_pos += 0xC + f_name_size + name_align
			if hdr_pos + 8 >= hdr_dec_size:
				break
				
	print_rich("[color=green]Finished![/color]")
	
	
func decrypt_file(dat: PackedByteArray, comp_size: int, dec_size: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(comp_size + 0xC)
	#out.encode_u32(0, dec_size)
	#out.encode_u32(4, comp_size)

	var t0: int = dat.decode_u8(8)
	var a3: int = dat.decode_u8(9)
	var a2: int = dat.decode_u8(10)
	var v1: int = dat.decode_u8(11)

	a3 += t0
	a2 += a3
	v1 += a2
	a2 = (v1 & 0xFF) if (v1 & 0xFF) != 0 else 0xAA

	for i: int in range(0xC, comp_size + 0xC):
		out.encode_u8(i, dat.decode_u8(i) ^ a2)

	return out


func _on_load_dat_pressed() -> void:
	file_load_dat.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_file_load_dat_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()
