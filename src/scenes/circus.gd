extends Control

@onready var circus_load_dat: FileDialog = $CircusLoadDAT
@onready var circus_load_folder: FileDialog = $CircusLoadFOLDER


var folder_path: String
var remove_alpha: bool = true
var selected_files: PackedStringArray
var debug_out: bool = false


func _process(_delta):
	if selected_files and folder_path:
		extract_dat()
		folder_path = ""
		selected_files.clear()
		

func extract_dat() -> void:
	var in_file: FileAccess
	var out_file: FileAccess
	var buff: PackedByteArray
	var num_files: int
	var f_offset: int
	var f_size: int
	var f_name: String
	var off_tbl: int
	var dir: DirAccess = DirAccess.open(folder_path)
	
	for file: int in selected_files.size():
		in_file = FileAccess.open(selected_files[file], FileAccess.READ)
		
		in_file.seek(0)
		num_files = in_file.get_32()
		off_tbl = (num_files * 8) + 4
		
		for i: int in num_files:
			in_file.seek((i * 0x40) + off_tbl)
			f_name = in_file.get_line()
			
			in_file.seek((i * 0x40) + off_tbl + 0x38)
			f_offset = in_file.get_32()
			f_size = in_file.get_32()
			
			print("%08X %08X %s/%s" % [f_offset, f_size, folder_path, f_name])
			
			dir.make_dir_recursive(f_name.get_base_dir())
			
			if f_name.ends_with("GRP"):
				in_file.seek(f_offset + 4)
				var width: int = in_file.get_32()
				var height: int = in_file.get_32()
				var unk_flag: int = in_file.get_32()
				var comp_size: int = in_file.get_32()
				
				in_file.seek(f_offset + 0x80)
				buff = decompress_image(in_file.get_buffer(comp_size), comp_size, (width * height) << 2)
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				var png: Image
				if remove_alpha:
					for off: int in range(0, buff.size(), 4):
						buff.encode_u8(off + 3, min(buff.decode_u8(off + 3) * 2, 0xFF))
					png = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
				else:
					png = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buff)
				png.save_png(folder_path + "/%s" % f_name + ".PNG")
			else:
				in_file.seek(f_offset)
				buff = in_file.get_buffer(f_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
	print_rich("[color=green]Finished![/color]")
		

func decompress_image(compressed: PackedByteArray, comp_size: int, decomp_size: int) -> PackedByteArray:
	# Allocate output buffer.
	var output: PackedByteArray = PackedByteArray()
	output.resize(decomp_size)

	# Pointers and counters.
	var in_index: int = 0                   # Index into the compressed data.
	var out_index: int = 0                  # Index into the output buffer.
	var bytes_left: int = comp_size         # Remaining compressed bytes.
	var flag_buffer: int = 0                # Bit buffer for literal/copy flags.

	# Constant used for extended commands.
	const EXTENDED_TOKEN: int = 0x7F

	# Main decompression loop.
	while bytes_left > 0:
		# Shift flag buffer; when its 9th bit isn’t set, fetch a new flag byte.
		flag_buffer >>= 1
		if (flag_buffer & 0x100) == 0:
			flag_buffer = compressed.decode_u8(in_index) | 0xFF00
			in_index += 1
			bytes_left -= 1

		# If the lowest flag bit is set, copy a literal byte.
		if flag_buffer & 1:
			output.encode_s8(out_index, compressed.decode_u8(in_index))
			in_index += 1
			bytes_left -= 1
			out_index += 1
			continue

		# Otherwise, process a backreference command.
		var token: int = compressed.decode_u8(in_index)
		in_index += 1
		bytes_left -= 1

		# --- Command Type A: token >= 0xC0 ---
		if token >= 0xC0:
			var offset: int = ((token & 0x03) << 8) | compressed.decode_u8(in_index)
			in_index += 1
			bytes_left -= 1
			var length: int = ((token >> 2) & 0x0F) + 4
			var copy_from: int = out_index - offset
			for i in range(length):
				output.encode_s8(out_index, output.decode_u8(copy_from))
				copy_from += 1
				out_index += 1
			continue

		# --- Command Type B: token in [0x80, 0xBF] ---
		if token & 0x80:
			var distance: int = token & 0x1F
			var length: int = (token >> 5) & 0x03
			if distance == 0:
				distance = compressed.decode_u8(in_index)
				in_index += 1
				bytes_left -= 1
				length += 2
			else:
				length += 2
			var copy_from: int = out_index - distance
			for i in range(length):
				output.encode_s8(out_index, output.decode_u8(copy_from))
				copy_from += 1
				out_index += 1
			continue

		# --- Command Type C & D: token < 0x80 ---
		if token == EXTENDED_TOKEN:
			var length: int = compressed.decode_u8(in_index)
			in_index += 1
			bytes_left -= 4
			length |= compressed.decode_u8(in_index) << 8
			in_index += 1
			var offset: int = compressed.decode_u8(in_index)
			in_index += 1
			length += 2
			offset |= compressed.decode_u8(in_index) << 8
			in_index += 1
			var copy_from: int = out_index - offset
			for i in range(length):
				output.encode_s8(out_index, output.decode_u8(copy_from))
				copy_from += 1
				out_index += 1
			continue
		else:
			bytes_left -= 2
			var length: int = token + 4
			var offset: int = compressed.decode_u8(in_index)
			in_index += 1
			offset |= compressed.decode_u8(in_index) << 8
			in_index += 1
			var copy_from: int = out_index - offset
			for i in range(length):
				output.encode_s8(out_index, output.decode_u8(copy_from))
				copy_from += 1
				out_index += 1
			continue

	return output
	
	
#func decompress_image_mips(file:PackedByteArray, comp_size:int, decomp_size:int) -> PackedByteArray:
	#var v0:int
	#var a0:int
	#var a1:int
	#var a2:int
	#var t3:int
	#var t4:int
	#var t5:int
	#var t6:int
	#var t7:int
	#var new_file:PackedByteArray
	#var gp:int #86A0(gp)
	#
	##function is lz77 based?
	##a0 = outbuffer
	##a1 = compressed data start
	##a2 = compressed buffer in header
	#
	#new_file.resize(decomp_size)
	#gp = 0
	#v0 = 0
	#a0 = 0
	#a1 = 0 #compressed data start
	#a2 = comp_size
	#t3 = 0x7F
	#t6 = gp
	#while a2 > 0:
		#t6 >>= 1
		#t7 = t6 & 0x100
		#gp = t6
		#if t7 == 0:
			#t7 = file.decode_u8(a1)
			#a2 -= 1 #daddiu a2, a2, $ffff
			#t6 = t7 | 0xFF00
			#a1 += 1
			#gp = t6
		#t7 = t6 & 1
		#if t7 != 0:
			#t7 = file.decode_u8(a1)
			#v0 += 1
			#a2 -= 1 #daddiu a2, a2, $ffff
			#new_file.encode_s8(a0, t7)
			#a1 += 1
			#a0 += 1
			#t6 = gp
			#continue
			#
		#if a2 == 0:
			#return new_file
	#
		#t4 = file.decode_u8(a1) #001231AC
		#a2 -= 1 #daddiu a2, a2, $ffff
		#t7 = t4 < 0xC0
		#a1 += 1
		#if t7 == 0:
			#t6 = t4 & 0x3
			#t5 = file.decode_u8(a1)
			#t7 = t4 >> 2
			#t6 <<= 8
			#t4 = t7 & 0xF
			#a2 -= 1 #daddiu a2, a2, $ffff
			#t6 |= t5 & 0xFFFFFFFF
			#a1 += 1
			#t4 += 4
			#t6 = a0 - t6
			#v0 += t4
			#while t4 != 0:
				#t7 = new_file.decode_u8(t6)
				#t4 -= 1
				#new_file.encode_s8(a0, t7)
				#t6 += 1
				#a0 += 1
			#if a2 == 0:
				#return new_file
			#else:
				#t6 = gp
				#continue
				#
		#t7 = t4 & 0x80
		#if t7 != 0:
			#t7 = t4 >> 5
			#t6 = t4 & 0x1F
			#t4 = t7 & 0x3
			#if t6 == 0:
				#t6 = file.decode_u8(a1)
				#a2 -= 1 #daddiu a2, a2, $ffff
				#a1 += 1
				#t4 += 2
				##beq      zero, zero, $001231E4
				#t6 = a0 - t6
				#v0 += t4
				#while t4 != 0:
					#t7 = new_file.decode_u8(t6)
					#t4 -= 1
					#new_file.encode_s8(a0, t7)
					#t6 += 1
					#a0 += 1
				#if a2 == 0:
					#return new_file
				#else:
					#t6 = gp
					#continue
			#
			#else:
				##bne      t6, zero, $00123234
				#t4 += 2
				#t6 = a0 - t6
				#v0 += t4
				#while t4 != 0:
					#t7 = new_file.decode_u8(t6)
					#t4 -= 1
					#new_file.encode_s8(a0, t7)
					#t6 += 1
					#a0 += 1
				#if a2 == 0:
					#return new_file
				#else:
					#t6 = gp
					#continue
				#
		##0012323C
		#t7 = t4 >> 5
		#if t4 == t3:
			#t4 = file.decode_u8(a1)
			#a2 -= 4 #daddiu a2, a2, $fffc
			#a1 += 1
			#t7 = file.decode_u8(a1)
			#a1 += 1
			#t7 <<= 8
			#t4 |= t7 & 0xFFFFFFFF
			#t6 = file.decode_u8(a1)
			#t4 += 2
			#a1 += 1
			#t7 = file.decode_u8(a1)
			#t7 <<= 8
			#a1 += 1
			#t6 |= t7 & 0xFFFFFFFF
			##beq      zero, zero, $001231E4
			#t6 = a0 - t6
			#v0 += t4
			#while t4 != 0:
				#t7 = new_file.decode_u8(t6)
				#t4 -= 1
				#new_file.encode_s8(a0, t7)
				#t6 += 1
				#a0 += 1
			#if a2 == 0:
				#return new_file
			#else:
				#t6 = gp
				#continue
				#
		#else:
			#t6 = file.decode_u8(a1)
			#a2 -= 2 #daddiu a2, a2, $fffe
			#t4 += 4
			##beq      zero, zero, $00123268
			#a1 += 1
			#t7 = file.decode_u8(a1)
			#t7 <<= 8
			#a1 += 1
			#t6 |= t7 & 0xFFFFFFFF
			##beq      zero, zero, $001231E4
			#t6 = a0 - t6
			#v0 += t4
			#while t4 != 0:
				#t7 = new_file.decode_u8(t6)
				#t4 -= 1
				#new_file.encode_s8(a0, t7)
				#t6 += 1
				#a0 += 1
			#if a2 == 0:
				#return new_file
			#else:
				#t6 = gp
				#continue
			#
	#return new_file
	
	
func _on_load_dat_pressed():
	circus_load_dat.visible = true
	
	
func _on_remove_alpha_button_toggled(_toggled_on):
	remove_alpha = !remove_alpha
		
		
func _on_circus_load_dat_files_selected(paths):
	circus_load_folder.show()
	selected_files = paths
	
	
func _on_circus_load_folder_dir_selected(dir):
	folder_path = dir


func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
