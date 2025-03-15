extends Control

@onready var file_load_iso: FileDialog = $FILELoadISO
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_exe: FileDialog = $FILELoadEXE

var exe_path: String
var selected_file: String
var folder_path: String
var debug_out: bool = false

func _process(_delta: float) -> void:
	if selected_file and folder_path:
		extract_iso()
		selected_file = ""
		folder_path = ""
	
	
func extract_iso() -> void:
	var buff: PackedByteArray
	var in_file: FileAccess
	var out_file: FileAccess
	var exe_file: FileAccess
	var pos: int
	var f_name: String
	var f_id: int = 0
	var f_size: int
	var f_dec_size: int
	var f_offset: int
	var num_files: int
	var tbl_id: int = 0
	var off_tbl: int
	var cur_tbl: int 
	var exe_name: String 
	var ent_pnt: int = 0xFF000
	var is_img: bool
	var is_compressed: bool
	var skip: bool
	var img_ids: PackedInt32Array = [
	14, 18, 19, 38, 58, 59,
	60, 61, 62, 63, 65, 66, 67, 68,
	69, 70, 71, 72, 73, 74, 75, 76,
	77, 78, 79, 80, 81, 82, 83, 84,
	85, 86, 87, 88, 89, 90, 91, 92,
	93, 98, 99, 100, 101
	]
	var unk_img_ids: PackedInt32Array = [
	3, 4, 5, 6, 10, 15, 20, 57,
	64
	]
	var not_comp_ids: PackedInt32Array = [
	31, 32, 33, 34
	]
	
	# This file system sucks
	# TODO: Other images that have multiple files and 4bit images.
	
	in_file = FileAccess.open(selected_file, FileAccess.READ)
	in_file.seek(0x8028)
	if in_file.get_buffer(9).get_string_from_ascii() != "SLPM66329":
		OS.alert("Not a known ISO.")
		return
	if exe_path == "":
		OS.alert("Please load SLPM_663.29 first.")
		return
	
	exe_file = FileAccess.open(exe_path, FileAccess.READ)
	off_tbl = 0x003096B0 - ent_pnt
	
	exe_file.seek(off_tbl)
	cur_tbl = exe_file.get_32()
	pos = cur_tbl - ent_pnt
	while cur_tbl != 0:
		while true:
			exe_file.seek(pos)
			is_img = false
			is_compressed = false
			skip = false
			
			# These aren't real file extensions from the game.
			if tbl_id == 0:
				f_name = "%02d_%08d.FNT" % [tbl_id, f_id]
			elif tbl_id == 1:
				f_name = "%02d_%08d.PSS" % [tbl_id, f_id]
			elif tbl_id in img_ids:
				f_name = "%02d_%08d.IMG" % [tbl_id, f_id]
				is_img = true
				is_compressed = true
			elif tbl_id in unk_img_ids:
				f_name = "%02d_%08d.IMG" % [tbl_id, f_id]
				is_img = true
				is_compressed = true
				skip = true
			elif tbl_id in not_comp_ids:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
			elif tbl_id == 2:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
			elif tbl_id == 7:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
				is_compressed = true
			elif tbl_id == 8 or tbl_id == 9:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
				is_compressed = true
			elif tbl_id == 11:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
				is_compressed = true
			elif tbl_id == 17:
				f_name = "%02d_%08d.SCR" % [tbl_id, f_id]
				is_compressed = true
			else:
				f_name = "%02d_%08d.BIN" % [tbl_id, f_id]
				is_compressed = true
				
			var unk_off: int = exe_file.get_32()
			f_offset = exe_file.get_32() * 0x800
			if f_offset == 0:
				break
				
			f_size = exe_file.get_32()
			in_file.seek(f_offset)
			
			if is_img:
				f_dec_size = in_file.get_32()
				
				print("%08X %08X %08X /%s/%s" % [f_offset, f_size, f_dec_size, folder_path, f_name])
			
				buff = ComFuncs.decompLZSS(in_file.get_buffer(f_size - 4), f_size - 4, f_dec_size)
				
				if skip:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					break
				if debug_out:
					out_file = FileAccess.open(folder_path + "/%s" % f_name + ".DEC", FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
				
				var pal: PackedByteArray
				var img: PackedByteArray
				var img_offs: PackedInt32Array
				var next_img: int
				var i: int = 0
				var img_id: int = 0
				
				var off: int = 0
				var hdr_end_off: int = buff.decode_u32(0)
				var hdr_size: int = buff.decode_u32(8)
				if hdr_size > 0x30:
					while i < 32:
						off = buff.decode_u32(i * 4)
						if off == 0 or off == 0xFFFFFFFF:
							break
						img_offs.append(off)
						i += 1
				else:
					img_offs.append(0)
				i = 0
				while i < img_offs.size():
					off = img_offs[i]
					var dat_hdr_s: int = buff.decode_u32(off)
					#var num_imgs: int = buff.decode_u16(off + 6)
					hdr_size = buff.decode_u32(off + 8)
					var unk_16_1: int = buff.decode_u16(off + dat_hdr_s)
					var w: int = buff.decode_u16(off + dat_hdr_s + 2)
					var h: int = buff.decode_u16(off + dat_hdr_s + 4)
					var bpp: int = buff.decode_u16(off + dat_hdr_s + 6)
					var part_s: int = buff.decode_u32(off + dat_hdr_s + 8) + hdr_size + off
					if w == 0:
						if bpp == 0:
							pal = buff.slice(part_s, part_s + hdr_size + 0x40)
							var n_pal: PackedByteArray = PackedByteArray()
							for pal_pos in range(0, 0x40, 2):
								var bgr555: int = pal.decode_u16(pal_pos)
								var r: int = ((bgr555 >> 10) & 0x1F) * 8
								var g: int = ((bgr555 >> 5) & 0x1F) * 8
								var b: int = (bgr555 & 0x1F) * 8
								n_pal.append(r)
								n_pal.append(g)
								n_pal.append(b)
								n_pal.append(255)
							pal = n_pal
						else:
							pal = ComFuncs.unswizzle_palette(buff.slice(part_s, part_s + hdr_size + 0x400), 32)
							
						dat_hdr_s += 16
						
						unk_16_1 = buff.decode_u16(off + dat_hdr_s)
						w = buff.decode_u16(off + dat_hdr_s + 2)
						h = buff.decode_u16(off + dat_hdr_s + 4)
						var unk_16_2: int = buff.decode_u16(off + dat_hdr_s + 6)
						part_s = buff.decode_u32(off + dat_hdr_s + 8) + hdr_size + off
						img = buff.slice(part_s, (w * h) + part_s + hdr_size)
						var image: Image = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
						if bpp == 0:
							# Not working for some reason
							img_id += 1
							i += 1
							continue
							for y in range(h):
								for x in range(0, w, 2):
									var byte_index: int  = (x + y * w) / 2
									var byte_value: int  = img[byte_index]
									var pixel_index_1 = byte_value & 0xF
									var pixel_index_2 = (byte_value >> 4) & 0xF
									var r1: int = pal[pixel_index_1 * 4 + 0]
									var g1: int = pal[pixel_index_1 * 4 + 1]
									var b1: int = pal[pixel_index_1 * 4 + 2]
									#var a1: int = pal[pixel_index_1 * 4 + 3]
									image.set_pixel(x, y, Color(r1 / 255.0, g1 / 255.0, b1 / 255.0))
									if x + 1 < w:
										var r2: int = pal[pixel_index_2 * 4 + 0]
										var g2: int = pal[pixel_index_2 * 4 + 1]
										var b2: int = pal[pixel_index_2 * 4 + 2]
										#var a2: int = pal[pixel_index_2 * 4 + 3]
										image.set_pixel(x + 1, y, Color(r2 / 255.0, g2 / 255.0, b2 / 255.0))
						else:
							for y in range(h):
								for x in range(w):
									var pixel_index: int = img[x + y * w]
									var r: int = pal[pixel_index * 4 + 0]
									var g: int = pal[pixel_index * 4 + 1]
									var b: int = pal[pixel_index * 4 + 2]
									#var a: int = palette[pixel_index * 4 + 3]
									image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
						image.save_png(folder_path + "/%s" % f_name + "_%02d" % img_id + ".PNG")
						img_id += 1
						i += 1
					else:
						push_error("Unknown image format in %s_%s?" % [f_name, img_id])
						i += 1
						img_id += 1
			else:
				if is_compressed:
					f_dec_size = in_file.get_32()
					
					print("%08X %08X %08X /%s/%s" % [f_offset, f_size, f_dec_size, folder_path, f_name])
					
					buff = ComFuncs.decompLZSS(in_file.get_buffer(f_size - 4), f_size - 4, f_dec_size)
				else:
					print("%08X %08X /%s/%s" % [f_offset, f_size, folder_path, f_name])
					buff = in_file.get_buffer(f_size)
				
				out_file = FileAccess.open(folder_path + "/%s" % f_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			
			f_id += 1
			f_dec_size = 0
			pos += 16
		
		f_id = 0
		tbl_id += 1
		exe_file.seek((tbl_id * 4) + off_tbl)
		cur_tbl = exe_file.get_32()
		pos = cur_tbl - ent_pnt
		
	print_rich("[color=green]Finished![/color]")
		


func _on_load_iso_pressed() -> void:
	file_load_iso.show()


func _on_file_load_iso_file_selected(path: String) -> void:
	selected_file = path
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_exe_pressed() -> void:
	file_load_exe.show()


func _on_file_load_exe_file_selected(path: String) -> void:
	exe_path = path


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
