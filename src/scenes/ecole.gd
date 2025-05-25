extends Control

var folder_path: String = ""
var selected_files: PackedStringArray = []

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER


func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		
		
func extract_arc() -> void:
	for file in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		var ext: String = selected_files[file].get_file().get_extension().to_lower()
		if ext == "agi" or ext == "cmp":
			if ext == "cmp":
				buff = lb_decompress(buff)
				#var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + ".DEC", FileAccess.WRITE)
				#out_file.store_buffer(buff)
				#out_file.close()
			var img_dat_off: int = buff.decode_u32(8)
			var w: int = buff.decode_u16(0x18)
			var h: int = buff.decode_u16(0x1A)
			if img_dat_off == 0x30:
				var pal_off: int = buff.decode_u32(0x1C)
				var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
				var img_dat: PackedByteArray = buff.slice(img_dat_off, pal_off)
				var pal: PackedByteArray = buff.slice(pal_off)
				var pal_size: int = pal.size()
				if pal_size == 0x400:
					pal = ComFuncs.unswizzle_palette(pal, 32)
					for y in range(h):
						for x in range(w):
							var pixel_index: int = img_dat[x + y * w]
							var r: int = pal[pixel_index * 4 + 0]
							var g: int = pal[pixel_index * 4 + 1]
							var b: int = pal[pixel_index * 4 + 2]
							var a: int = pal[pixel_index * 4 + 3]
							image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
				elif pal_size == 0x40:
					for i in range(pal_size):
						var byte_val: int = img_dat[i]
						img_dat[i] = ((byte_val & 0x0F) << 4) | ((byte_val & 0xF0) >> 4)  
						# Swaps high and low nibbles
					for y in range(h):
						for x in range(w):
							var pixel_index: int = img_dat[(x + y * w) >> 1]  # 2 pixels per byte
							if x % 2 == 0:
								pixel_index = (pixel_index >> 4) & 0xF  # Higher nibble
							else:
								pixel_index = pixel_index & 0xF         # Lower nibble
							var base_index: int = pixel_index * 4
							var r: int = pal[base_index + 0]
							var g: int = pal[base_index + 1]
							var b: int = pal[base_index + 2]
							var a: int = pal[base_index + 3]
							image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
				image.convert(Image.FORMAT_RGB8)
				image.save_png(folder_path + "/%s" % arc_name + ".PNG")
			else:
				var image: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, buff.slice(img_dat_off))
				image.convert(Image.FORMAT_RGB8)
				image.save_png(folder_path + "/%s" % arc_name + ".PNG")
			print("Converted %s" % arc_name + ".PNG")
	print_rich("[color=green]Finished![/color]")


#func lb_decompress_mips(data: PackedByteArray) -> PackedByteArray:
	#if data.slice(0, 10).get_string_from_ascii() != "COMPRESSED":
		#return PackedByteArray()
		#
	#var total_size: int = data.decode_u32(0xA)
	#var output: PackedByteArray = []
	#output.resize(total_size)
	#
	#var read_idx: int = 14
	#var write_idx: int = 0
	#
	#var v0: int = 0
	#var v1: int = 0
	#var s0: int = read_idx
	#var s1: int = write_idx
	#var s2: int = 0
	#var s4: int = 0
	#var s5: int = 0
	#var s3: int = 0
	#var s6: int = 0
	#var goto: String = "00348f00"
	#while s1 < total_size:
		#match goto:
			#"00348f00":
				#if s1 >= total_size:
					#break
				#goto = "00348E54"
			#"00348E54":
				#s2 = 0
				#goto = "00348ed8"
			#"00348e60":
				#v1 = data.decode_u8(s0 + 1)
				#v0 = s1
				#s1 = v0 + 1
				#output.encode_s8(v0, v1)
				#v1 = data.decode_u8(s0 + 2)
				#v0 = s1
				#s1 = v0 + 1
				#output.encode_s8(v0, v1)
				#v1 = data.decode_u8(s0 + 3)
				#v0 = s1
				#s1 = v0 + 1
				#output.encode_s8(v0, v1)
				#v1 = data.decode_u8(s0 + 4)
				#v0 = s1
				#s1 = v0 + 1
				#output.encode_s8(v0, v1)
				#goto = "00348ec8"
			#"00348ec8":
				#s2 += 1
				#s4 = s3
				#s3 = s4 + 1
				#goto = "00348ed8"
			#"00348ed8":
				#v0 = data.decode_u8(s0)
				#v0 = s2 < v0
				#if v0 != 0:
					#goto = "00348e60"
				#else:
					#if s0 >= data.size():
						#break
					#v0 = data.decode_u8(s0)
					#v0 <<= 2
					#s5 += v0
					#s0 += 5
					#goto = "00348f00"
			#
		#
	#return output
	
	
func lb_decompress(data: PackedByteArray) -> PackedByteArray:
	const PREFIX: String = "COMPRESSED"
	var prefix_len: int = PREFIX.length()

	if data.size() < prefix_len + 4:
		return PackedByteArray()

	if data.slice(0, prefix_len).get_string_from_ascii() != PREFIX:
		return PackedByteArray()

	var total_size: int = data.decode_u32(prefix_len)
	var output: PackedByteArray = PackedByteArray()
	output.resize(total_size)

	var read_idx: int = prefix_len + 4
	var write_idx: int = 0

	while write_idx < total_size:
		# Ensure there's room for a full 5‑byte header
		if read_idx + 5 > data.size():
			return PackedByteArray()
		# Number of times to repeat this pattern
		var run_length: int = data[read_idx]
		# Extract 4‑byte pattern
		var pattern: Array[int] = [
			data[read_idx + 1],
			data[read_idx + 2],
			data[read_idx + 3],
			data[read_idx + 4]
		]
		read_idx += 5

		# Copy pattern run_length times
		for _i in range(run_length):
			# Stop if buffer full
			if write_idx + 4 > total_size:
				return PackedByteArray()
			for byte_val in pattern:
				output[write_idx] = byte_val
				write_idx += 1
	return output


func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
