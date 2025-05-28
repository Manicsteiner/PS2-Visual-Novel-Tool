extends Control

var folder_path: String = ""
var selected_files: PackedStringArray = []

@onready var file_load_arc: FileDialog = $FILELoadARC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

#TODO: IMAGE_G.BIN has some wrong palettes combined to PNGs

func _ready() -> void:
	file_load_arc.filters = ["IMAGE_D.BIN, IMAGE_E.BIN, IMAGE_G.BIN, IMAGE_MD.BIN"]
	
	
func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_arc()
		folder_path = ""
		selected_files.clear()
		
		
func extract_arc() -> void:
	for file in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_full_name: String = selected_files[file].get_file()
		if arc_full_name == "IMAGE_E.BIN": # There is no offsets in the exe for this file. Appears to be unused.
			print_rich("[color=yellow]Making offsets for %s (image output not implemented yet)[/color]" % arc_full_name)
			
			var offsets: Array[int] = []
			var pattern: String = "CPXa0100"

			var file_size: int = in_file.get_length()
			var buffer: PackedByteArray = in_file.get_buffer(file_size)

			var pattern_bytes: PackedByteArray = pattern.to_ascii_buffer()
			var pattern_length: int = pattern_bytes.size()
			
			var search_pos: int = 0
			for i in range(buffer.size() - pattern_length + 1):
				var mat: bool = true
				for j in range(pattern_length):
					if buffer[i + j] != pattern_bytes[j]:
						mat = false
						break
				if mat:
					offsets.append(i)
					
			buffer.clear()
			var dims:Array[int] = [
				512, 256, 512, 320, 512, 512, 512, 448, 512, 640, 512, 768,
				640, 256, 640, 320, 640, 512, 640, 448, 640, 640, 640, 768, 
				768, 256, 768, 320, 768, 512, 768, 448, 768, 640, 768, 768,
				]
			var f_id: int = 0
			var pal_id: int = 63 
			for i in range(0, offsets.size()):
				var f_offset: int = offsets[i]
				var f_size: int
				if i + 1 >= offsets.size():
					f_size = 0x00592000
				else:
					f_size = offsets[i + 1]
				
				in_file.seek(f_offset)
				var buff: PackedByteArray = in_file.get_buffer(f_size - f_offset)
				if buff.slice(0, 8).get_string_from_ascii() == "CPXa0100":
					buff = cpx_expand(buff)
					
				var f_name: String = "%s_%04d.BIN" % [arc_full_name, f_id]
				for dim in range(0, dims.size(), 2):
					if dims[dim] * dims[dim + 1] == buff.size():
						print("Match of dimensions found in %s with dims %d x %d" % [f_name, dims[dim], dims[dim + 1]])
						break
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				f_id += 1
				
			var off: int = 0x00592000
			var f_size: int = 0x400
			while off < file_size:
				in_file.seek(off)
				var buff: PackedByteArray = in_file.get_buffer(f_size)
				
				var f_name: String = "%s_%04d.BIN" % [arc_full_name, f_id]
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				off += 0x800
				f_id += 1
			print_rich("[color=green]Extracted from %s[/color]" % arc_full_name)
		else:
			var exe_file: FileAccess = FileAccess.open(selected_files[file].get_base_dir() + "SLPM_624.00", FileAccess.READ)
			if exe_file == null:
				OS.alert("Could not find %s!" % selected_files[file].get_base_dir() + "SLPM_624.00")
				return
				
			var entry_point: int = 0x3FFF80
			var tbl_start: int = 0 # exe table offsets for .BIN file
			var tbl_end: int = 0
			var pal_id: int = 0    # start of palette files
			if arc_full_name == "IMAGE_MD.BIN":
				tbl_start = 0x00486ca0 - entry_point
				tbl_end = 0x0048a030 - entry_point
				pal_id = 330
			elif arc_full_name == "IMAGE_D.BIN":
				tbl_start = 0x00485030 - entry_point
				tbl_end = 0x00485990 - entry_point
				pal_id = 59
			elif arc_full_name == "IMAGE_G.BIN":
				tbl_start = 0x00485990 - entry_point
				tbl_end = 0x00486ca0 - entry_point
				pal_id = 123
				
			# IMAGE_E.BIN appears to be unused and has no offsets
			
			var dimensions_arr: Array[int]
			var f_id: int = 0
			for tbl_pos in range(tbl_start, tbl_end, 0x14):
				exe_file.seek(tbl_pos)
				var f_offset: int = exe_file.get_32() * 0x800
				var f_sector_size: int = exe_file.get_32() * 0x800
				var f_size: int = exe_file.get_32()
				var f_width: int = exe_file.get_32()
				var f_height: int = exe_file.get_32()
				
				if f_width != 0:
					dimensions_arr.append(f_width)
					dimensions_arr.append(f_height)
				
				in_file.seek(f_offset)
				var buff: PackedByteArray = in_file.get_buffer(f_size)
				if buff.slice(0, 8).get_string_from_ascii() == "CPXa0100":
					buff = cpx_expand(buff)
				
				var f_name: String = "%s_%04d.BIN" % [arc_full_name, f_id]
				
				print("%08X %08X %d %d %s/%s" % [f_offset, f_size, f_width, f_height, folder_path, f_name])
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
				f_id += 1
				
			in_file.close()
			exe_file.close()
			
			print_rich("[color=yellow]Combining image and palettes for %s[/color]" % arc_full_name)
			
			# Combine image data and palettes
			f_id = 0
			for i in range(0, dimensions_arr.size(), 2):
				if arc_full_name == "IMAGE_D.BIN":
					if f_id == 17:
						pal_id += 1
					elif f_id == 56:
						pal_id += 1 
					elif f_id == 58:
						pal_id = 116 
				if arc_full_name == "IMAGE_G.BIN":
					if f_id == 3: # 127
						pal_id += 1
					elif f_id == 4: # 126
						pal_id -= 2 
					elif f_id == 5: # 128
						pal_id += 1
					elif f_id == 72:
						pal_id = 207
					elif f_id == 73:
						pal_id = 200
					elif f_id == 74:
						pal_id = 204
					elif f_id == 75: 
						pal_id = 198
					elif f_id == 76: 
						pal_id = 209
					elif f_id == 77: 
						pal_id = 197
					elif f_id == 78: 
						pal_id = 196
					elif f_id == 79: 
						pal_id = 208
					elif f_id == 80: 
						pal_id = 205
					elif f_id == 81:
						pal_id = 195
					elif f_id == 82:
						pal_id = 199
					elif f_id == 83:
						pal_id = 201
					elif f_id == 86:
						pal_id = 206
					elif f_id == 87:
						pal_id = 210
					elif f_id == 97: # 219
						pal_id -= 1
					elif f_id == 115: # 236
						pal_id -= 1
					elif f_id == 117: # 237
						pal_id -= 1
						
				var f_name: String = "%s_%04d.BIN" % [arc_full_name, f_id]
				var pal_name: String = "%s_%04d.BIN" % [arc_full_name, pal_id]
				
				in_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.READ)
				if in_file == null:
					push_error("Can't find %s" % folder_path + "/%s" % f_name)
					f_id += 1
					pal_id += 1
					continue
				var pal_file: FileAccess = FileAccess.open(folder_path + "/%s" % pal_name, FileAccess.READ)
				if pal_file == null:
					push_error("Can't find palette %s" % folder_path + "/%s" % pal_name)
					f_id += 1
					pal_id += 1
					continue
					
				print("Combined image: %s to palette: %s" % [f_name, pal_name])
				
				var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
				var pal_buff: PackedByteArray = pal_file.get_buffer(pal_file.get_length())
				var img: Image = make_img(buff, dimensions_arr[i], dimensions_arr[i + 1], pal_buff)
				img.save_png(folder_path + "/%s" % f_name + ".PNG")
				
				in_file.close()
				pal_file.close()
				
				f_id += 1
				pal_id += 1
		
	print_rich("[color=green]Finished![/color]")
	

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
	
	
func make_img(buff: PackedByteArray, w: int, h: int, pal: PackedByteArray) -> Image:
	var img_dat: PackedByteArray = unswizzle8(buff, w, h)
	var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	pal = ComFuncs.unswizzle_palette(pal, 32)
	for y in range(h):
		for x in range(w):
			var pixel_index: int = img_dat[x + y * w]
			var r: int = pal[pixel_index * 4 + 0]
			var g: int = pal[pixel_index * 4 + 1]
			var b: int = pal[pixel_index * 4 + 2]
			var a: int = pal[pixel_index * 4 + 3]
			image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0))
	image.convert(Image.FORMAT_RGB8)
	return image
	
	
func cpx_expand(data: PackedByteArray) -> PackedByteArray:
	# Skip the first 0x10 bytes of header
	var ip: int = 0x10
	var out_size: int = data.decode_u32(8)

	var output: PackedByteArray = PackedByteArray()
	output.resize(out_size)
	
	var op: int = 0
	while ip < data.size():
		var ctrl: int = data[ip]
		if ctrl == 0:
			break
			
		ip += 1
		var hi: int = ctrl & 0xF0
		match hi:
			0x40, 0x50:
				# Literal copy: length = low 5 bits
				var count: int = ctrl & 0x1F
				if count == 0:
					break
				#count -= 1
				for i in range(count):
					output[op] = data[ip]
					ip += 1
					op += 1
			0x60, 0x70:
				# Extended literal: length = ((low5bits << 8) | nextByte)
				var length: int = ((ctrl & 0x1F) << 8) | data[ip]
				ip += 1
				if length == 0:
					break
				#length -= 1
				for i in range(length):
					output[op] = data[ip]
					ip += 1
					op += 1
			0x00:
				# Back-reference, 1-byte offset
				var length: int = (ctrl & 0x0F) + 2
				var offset: int = data[ip]
				ip += 1
				var src_pos: int = op - offset
				for i in range(length):
					output[op] = output[src_pos + i]
					op += 1
			0x10:
				# Back-reference, 2-byte little-endian offset
				var length: int = (ctrl & 0x0F) + 2
				var offset_low: int = data[ip]
				var offset_high: int = data[ip + 1]
				ip += 2
				var offset: int = offset_low | (offset_high << 8)
				var src_pos: int = op - offset
				for i in range(length):
					output[op] = output[src_pos + i]
					op += 1
			0x20:
				# Back-reference: offset in high byte, length in low byte + nibble
				var low: int = data[ip]
				var high: int = data[ip + 1]
				ip += 2
				var length: int = ((ctrl & 0x0F) << 8) | low
				var offset: int = high
				var src_pos: int = op - offset
				for i in range(length):
					if op >= out_size:
						return output
					output[op] = output[src_pos + i]
					op += 1
			0x30:
				# Back-reference: 3-byte offset (low, mid, high)
				var b0: int = data[ip]
				var b1: int = data[ip + 1]
				var b2: int = data[ip + 2]
				ip += 3
				var length: int = ((ctrl & 0x0F) << 8) | b0
				var offset: int = b1 | (b2 << 8)
				var src_pos: int = op - offset
				for i in range(length):
					if op >= out_size:
						return output
					output[op] = output[src_pos + i]
					op += 1
			_:
				# Default: literal copy of ((ctrl & 0x70) >> 4) bytes
				var count: int = (ctrl & 0x70) >> 4
				if count == 0:
					var length: int = (ctrl & 0x0F) + 2
					var offset: int = data[ip]
					ip += 1
					var src_pos: int = op - offset
					for i in range(length):
						if op >= out_size:
							return output
						output[op] = output[src_pos + i]
						op += 1
				else:
					for i in range(count):
						output[op] = data[ip]
						ip += 1
						op += 1
					var length: int = (ctrl & 0x0F) + 2
					var offset: int = data[ip]
					ip += 1
					var src_pos: int = op - offset
					for i in range(length):
						output[op] = output[src_pos + i]
						op += 1

	return output
	
	
func _on_load_arc_pressed() -> void:
	file_load_arc.show()


func _on_file_load_arc_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir
