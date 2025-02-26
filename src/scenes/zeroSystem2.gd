extends Control

@onready var file_load_exe: FileDialog = $FILELoadEXE
@onready var file_load_bin: FileDialog = $FILELoadBIN
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path:String
var exe_path: String
var selected_bin: String
var chose_bin: bool = false
var chose_folder: bool = false
var out_decomp: bool = false


func _ready() -> void:
	file_load_exe.filters = [
		"SLPM_668.05, SLPM_552.41, SLPM_551.95, SLPM_669.34"
	]


func _process(_delta: float) -> void:
	if chose_bin and chose_folder:
		extractBin()
		exe_path = ""
		selected_bin = ""
		chose_bin = false
		chose_folder = false


func extractBin() -> void:
	var i: int
	var exe_start: int
	var exe_file: FileAccess
	var exe_end: int
	var exe_buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var tbl_file: FileAccess
	var file_name: String
	var f_id: int
	var f_offset: int
	var f_size: int
	var exe_pos: int
	var exe_offset: int
	var exe_size: int
	var exe_unk: int
	var f_unk: int
	var f_freq: int
	var bytes: int
	var buff: PackedByteArray # Used for decompressing
	var scr_bytes: int = 0x02524353
	var ext: String
	
	# This table format is kinda wacky in these games, so we load the exe and get offsets to DATA.BIN,
	# which in turn point to another table for the first 6 entries, then we extract the actual files.
	# Since these files can be rather large (1GB or so in some cases), we don't load them into a buffer,
	# instead we do 64 bit stores to the disk and loop until the end of the current file.
	
	if exe_path == "":
		OS.alert("Load an EXE (SLPM_XXX.XX) first.")
		return
				
	if exe_path.get_file() == "SLPM_668.05": # Colorful Aquarium - My Little Mermaid
		exe_start = 0x850A8
		exe_end = 0x851C8
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
	elif exe_path.get_file() == "SLPM_552.41": # ef - A Fairy Tale of the Two
		exe_start = 0x98438
		exe_end = 0x98588
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
	elif exe_path.get_file() == "SLPM_551.95": # Princess Lover! Eternal Love for My Lady
		exe_start = 0xA0A00
		exe_end = 0xA0B20
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
	elif exe_path.get_file() == "SLPM_669.34": # Kimi ga Aruji de Shitsuji ga Ore de - Otsukae Nikki 
		exe_start = 0x85498
		exe_end = 0x855B8
		exe_file = FileAccess.open(exe_path, FileAccess.READ)
	
	print_rich("[color=yellow]Extracting files. Please wait...[/color]")
	
	in_file = FileAccess.open(selected_bin, FileAccess.READ)
	
	exe_file.seek(exe_start)
	i = 0
	# Grab and extract first 6 files.
	
	while i < 7:
		exe_offset = exe_file.get_64() * 0x4000
		exe_size = exe_file.get_64() * 0x4000
		exe_unk = exe_file.get_64()
		
		ext = ".HED"
		out_file = FileAccess.open(folder_path + "/%02d" % i + ext, FileAccess.WRITE)
		exe_buff.resize(0x18)
		exe_buff.encode_u64(0, exe_offset)
		exe_buff.encode_u64(8, exe_size)
		exe_buff.encode_u64(16, exe_unk)
		out_file.store_buffer(exe_buff)
		out_file.close()
		exe_buff.clear()
		
		if i > 1:
			ext = ".TBL"
			out_file = FileAccess.open(folder_path + "/%02d" % i + ext, FileAccess.WRITE)
		else:
			ext = ".BIN"
			out_file = FileAccess.open(folder_path + "/%02d" % i + ext, FileAccess.WRITE)
			
			
		print("%08X %08X %02d %s/%02d%s" % [exe_offset, exe_size, i, folder_path, i, ext])
		
		in_file.seek(exe_offset)
		while in_file.get_position() < exe_offset + exe_size:
			bytes = in_file.get_64()
			out_file.store_64(bytes)
		
		out_file.close()
		i += 1
	
	i = 2
	ext = ".BIN"
	# Extract the rest of the files
	while true:
		exe_offset = exe_file.get_64() * 0x4000
		exe_size = exe_file.get_64() * 0x4000
		exe_unk = exe_file.get_64()
		if exe_size == 0:
			exe_file.close()
			break
		
		out_file = FileAccess.open(folder_path + "/%02d" % i + ext, FileAccess.WRITE)
		
		print("%08X %08X %02d %s/%02d%s" % [exe_offset, exe_size, i, folder_path, i, ext])
		
		in_file.seek(exe_offset)
		while in_file.get_position() < exe_offset + exe_size:
			bytes = in_file.get_64()
			out_file.store_64(bytes)
			
		out_file.close()
		i += 1
		
	in_file.close()
	exe_file.close()
	i = 2
		
	# Open extracted files and split them based on offsets in their respective table.
	while i < 7:
		#if i == 2 or i == 3:
			#i += 1
			#continue
		if i == 5:
			# If BGM file, write VGMStream txth settings.
			var string: String
			var f_channels: int
			
			ext = ".txth"
			tbl_file = FileAccess.open(folder_path + "/%02d" % i + ".TBL", FileAccess.READ)
			out_file = FileAccess.open(folder_path + "/%02d" % i + "%s" % ext, FileAccess.WRITE)
			
			tbl_file.seek(8)
			var num_entries: int = tbl_file.get_32()
					
			string = "codec             = PSX"
			out_file.store_line(string)
			string = "interleave        = 0x4000"
			out_file.store_line(string)
			string = "padding_size      = auto-empty"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "header_file       = %02d.TBL" % i
			out_file.store_line(string)
			string = "body_file         = %02d.BIN" % i
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "subsong_count     = %02d" % num_entries
			out_file.store_line(string)
			string = "subsong_offset    = 0x30"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "base_offset       = 0x10"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "sample_type       = bytes"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "channels          = @0x04"
			out_file.store_line(string)
			string = "start_offset      = @0x10"
			out_file.store_line(string)
			string = "sample_rate       = @0x1C$2"
			out_file.store_line(string)
			string = "data_size         = (@0x14 + 0x4000) / 0x4000 * 0x4000 * channels"
			out_file.store_line(string)
			string = "num_samples       = data_size"
			out_file.store_line(string)
			string = "loop_flag         = auto"
			out_file.store_line(string)
				
			tbl_file.close()
			out_file.close()
			i += 1
			continue
		elif i == 4 or i == 6:
			# Write VGMStream txth settings for voice and sfx files.
			var string: String
			
			ext = ".txth"
			tbl_file = FileAccess.open(folder_path + "/%02d" % i + ".TBL", FileAccess.READ)
			out_file = FileAccess.open(folder_path + "/%02d" % i + "%s" % ext, FileAccess.WRITE)
			
			# Find ending of table
			var num_entries: int = tbl_file.get_32()
			bytes = tbl_file.get_64()
			while bytes != 0:
				bytes = tbl_file.get_64()
				
			num_entries = (tbl_file.get_position() - 8) / 16
			
			string = "codec             = PSX"
			out_file.store_line(string)
			string = "channels          = 1"
			out_file.store_line(string)
			string = "padding_size      = auto-empty"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "header_file       = %02d.TBL" % i
			out_file.store_line(string)
			string = "body_file         = %02d.BIN" % i
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "subsong_count     = %02d" % num_entries
			out_file.store_line(string)
			string = "subsong_offset    = 0x10"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "sample_type       = bytes"
			out_file.store_line(string)
			out_file.store_string("\n")
			string = "start_offset      = @0x08"
			out_file.store_line(string)
			string = "sample_rate       = @0x0E$2"
			out_file.store_line(string)
			string = "data_size         = @0x04"
			out_file.store_line(string)
			string = "num_samples       = data_size"
			out_file.store_line(string)
			
			tbl_file.close()
			out_file.close()
			i += 1
			continue
			
		in_file = FileAccess.open(folder_path + "/%02d" % i + ".BIN", FileAccess.READ)
		tbl_file = FileAccess.open(folder_path + "/%02d" % i + ".TBL", FileAccess.READ)
		if tbl_file.get_error() != OK:
			printerr("Error occured loading %s" % folder_path + "/%02d" % i + ".TBL")
			return
			
		while tbl_file.get_position() < tbl_file.get_length():
			if tbl_file.eof_reached():
				break
				
			f_id = tbl_file.get_32()
			f_size = tbl_file.get_32()
			f_offset = tbl_file.get_32()
			f_unk = tbl_file.get_16()
			f_freq = tbl_file.get_16()
			
			if f_size == 0:
				break
			
			in_file.seek(f_offset)
			bytes = in_file.get_32()
			if bytes == scr_bytes:
				ext = ".SCR"
			elif bytes == 0x03504D43 or bytes == 0x04504D43 or bytes == 0x05504D43:
				ext = ".TM2"
				
				out_file = FileAccess.open(folder_path + "/%02d" % i + "_%08d" % f_id + ext, FileAccess.WRITE)
				
				in_file.seek(f_offset)
				if bytes == 0x04504D43 or bytes == 0x05504D43:
					buff = decompressRLE_ef(in_file.get_buffer(f_offset + f_size))
				else:
					buff = decompressRLE(in_file.get_buffer(f_offset + f_size))
			
				out_file.store_buffer(buff)
				print("%08X %08X %02d %s/%02d_%08d%s" % [f_offset, buff.size(), i, folder_path, i, f_id, ext])
				
				buff.clear()
					
				if out_decomp:
					ext = ".CMP"
						
					out_file = FileAccess.open(folder_path + "/%02d" % i + "_%08d" % f_id + ext, FileAccess.WRITE)
					
					in_file.seek(f_offset)
					buff = in_file.get_buffer(f_offset + f_size)
					
					out_file.store_buffer(buff)
					print("%08X %08X %02d %s/%02d_%08d%s" % [f_offset, buff.size(), i, folder_path, i, f_id, ext])
					
					buff.clear()
				continue
			else:
				ext = ".BIN"
				
				
			out_file = FileAccess.open(folder_path + "/%02d" % i + "_%08d" % f_id + ext, FileAccess.WRITE)
			
			in_file.seek(f_offset)
			while in_file.get_position() < f_offset + f_size:
				bytes = in_file.get_64()
				out_file.store_64(bytes)
				
			print("%08X %08X %02d %s/%02d_%08d%s" % [f_offset, f_size, i, folder_path, i, f_id, ext])
			out_file.close()
			
		in_file.close()
		tbl_file.close()
		i += 1
		
	print_rich("[color=green]Finished![/color]")
	
func decompressRLE(input: PackedByteArray) -> PackedByteArray:
	var control_byte: int
	var repeat_byte: int
	var output = PackedByteArray()
	var input_index: int = 0
	var tim2_hex: int = 0x324D4954
	#var block_size: int

	# Determine initial state pointer and block size
	var state: int = input.decode_u8(input_index + 3)
	input_index += 0x1C

	#block_size = state if input[input_index + 3] < 3 else ~state & 0xFF00FF
	control_byte = input[input_index]
	input_index += 1

	# Main decompression loop
	while control_byte != 0xF8:  # End marker
		var remaining_bytes: int = 0

		match control_byte:
			0xFD:  # Copy block of bytes
				remaining_bytes = input.decode_u32(input_index)
				input_index += 4
			0xFE:  # Shorter block copy
				remaining_bytes = input.decode_u16(input_index)
				input_index += 2
			0xFF:  # Another type of block copy
				remaining_bytes = input[input_index]
				input_index += 1
			0xF2:  # Fill block with repeated byte
				repeat_byte = input[input_index + 4]
				remaining_bytes = input.decode_u32(input_index)
				input_index += 5
			0xF1:  # Shorter repeated byte fill
				repeat_byte = input[input_index + 2]
				remaining_bytes = input.decode_u16(input_index)
				input_index += 3
			0xF0:  # Simple repeated byte fill
				repeat_byte = input[input_index + 1]
				remaining_bytes = input[input_index]
				input_index += 2
			_:
				push_error("Unknown control byte %02X in RLE compression." % control_byte)
				return output  # Unknown control byte, stop decompression

		# Process the block
		if remaining_bytes > 0:
			var processed_bytes: int = 0

			# Efficiently process blocks of 8 bytes
			while processed_bytes + 8 <= remaining_bytes:
				if control_byte >= 0xF0 and control_byte <= 0xF2:
					output.resize(output.size() + 8)
					for i in range(8):
						output[output.size() - 8 + i] = repeat_byte
				else:
					output.resize(output.size() + 8)
					for i in range(8):
						output[output.size() - 8 + i] = input[input_index + i]
					input_index += 8
				processed_bytes += 8

			# Process remaining bytes one at a time
			while processed_bytes < remaining_bytes:
				output.resize(output.size() + 1)
				if control_byte >= 0xF0 and control_byte <= 0xF2:
					output[output.size() - 1] = repeat_byte
				else:
					output[output.size() - 1] = input[input_index]
					input_index += 1
				processed_bytes += 1

		# Move to the next control byte
		control_byte = input[input_index]
		input_index += 1

	# Append output header (TIM2)
	output.encode_u32(0, tim2_hex)
	return output
	
	
func decompressRLE_ef(input: PackedByteArray) -> PackedByteArray:
	var output = PackedByteArray()
	var input_index: int = 0
	#var block_size: int = 0
	var control_byte: int
	var repeat_byte: int
	var tim2_hex: int = 0x324D4954

	# Determine initial state pointer and block size
	var state: int
	if input[3] < 3:
		state = input.decode_u32(0x10)
	else:
		state = input.decode_u32(0x18)

	#block_size = state if input[3] <= 1 else (state & 0xff00ff00 | (~state & 0xff00ff))

	# Start processing the input
	input_index = 0x1C  # Adjust for state pointer location
	control_byte = input[input_index]
	input_index += 1

	while (control_byte & 0xF) != 0x8:  # End marker
		control_byte &= 0xF  # Apply masking
		var remaining_bytes: int = 0

		match control_byte:
			0xD:  # Copy block of bytes
				remaining_bytes = input.decode_u32(input_index)
				input_index += 4
			0xE:  # Shorter block copy
				remaining_bytes = input.decode_u16(input_index)
				input_index += 2
			0xF:  # Another type of block copy
				remaining_bytes = input[input_index]
				input_index += 1
			0x2:  # Fill block with repeated byte
				repeat_byte = input[input_index + 4]
				remaining_bytes = input.decode_u32(input_index)
				input_index += 5
			0x1:  # Shorter repeated byte fill
				repeat_byte = input[input_index + 2]
				remaining_bytes = input.decode_u16(input_index)
				input_index += 3
			0x0:  # Simple repeated byte fill
				repeat_byte = input[input_index + 1]
				remaining_bytes = input[input_index]
				input_index += 2
			_:
				push_error("Unknown control byte encountered: 0x%02X" % control_byte)
				return output

		# Process the block
		if remaining_bytes > 0:
			var processed_bytes: int = 0
			while processed_bytes + 8 <= remaining_bytes:
				if control_byte in [0x2, 0x1, 0x0]:
					# Fill with repeated byte
					output.resize(output.size() + 8)
					for i in range(8):
						output[output.size() - 8 + i] = repeat_byte
				else:
					# Copy block from input
					output.resize(output.size() + 8)
					for i in range(8):
						output[output.size() - 8 + i] = input[input_index + i]
					input_index += 8
				processed_bytes += 8

			while processed_bytes < remaining_bytes:
				output.resize(output.size() + 1)
				if control_byte in [0x2, 0x1, 0x0]:
					output[output.size() - 1] = repeat_byte
				else:
					output[output.size() - 1] = input[input_index]
					input_index += 1
				processed_bytes += 1

		# Move to the next control byte
		control_byte = input[input_index]
		input_index += 1

	# Add TIM2 header
	output.encode_u32(0, tim2_hex)
	return output


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_load_exe_pressed() -> void:
	file_load_exe.visible = true


func _on_load_bin_pressed() -> void:
	file_load_bin.visible = true


func _on_file_load_bin_file_selected(path: String) -> void:
	file_load_bin.visible = false
	file_load_folder.visible = true
	chose_bin = true
	selected_bin = path


func _on_file_load_folder_dir_selected(dir: String) -> void:
	chose_folder = true
	folder_path = dir
