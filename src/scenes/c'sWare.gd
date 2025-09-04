extends Control

@onready var file_load_afs: FileDialog = $FILELoadAFS
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path: String
var selected_files: PackedStringArray
var debug_out: bool = false

func _ready() -> void:
	file_load_afs.filters = ["*.AFS"]


func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract_afs()
		selected_files.clear()
		folder_path = ""


func extract_afs() -> void:
	for file in range(0, selected_files.size()):
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		var base_dir: String = "%s/%s" % [folder_path, arc_name]
		
		in_file.seek(4)
		var num_files: int = in_file.get_32()
		
		var off_tbl: int = 8
		
		in_file.seek((num_files * 8) + off_tbl)
		var name_tbl: int = in_file.get_32()
		var name_tbl_size: int = in_file.get_32()
		
		var f_offset: int = 0
		if name_tbl == 0 or name_tbl_size == 0:
			# check for odd cases where name table isn't the last in the offset table
			in_file.seek(8)
			f_offset = in_file.get_32()
			
			in_file.seek(f_offset - 8)
			name_tbl = in_file.get_32()
			name_tbl_size = in_file.get_32()
			if name_tbl == 0 or name_tbl_size == 0:
				print_rich("[color=red]Couldn't find name table in %s" % selected_files[file])
		
		var dir: DirAccess = DirAccess.open(folder_path)
		for files in range(num_files - 1):
			in_file.seek((files * 8) + off_tbl)
			
			f_offset = in_file.get_32()
			var f_size: int = in_file.get_32()
			
			var f_name: String = ""
			var f_ext: String = ""
			if name_tbl != 0 or name_tbl_size != 0:
				in_file.seek((files * 0x30) + name_tbl)
				f_name = in_file.get_line()
				f_ext = f_name.get_extension()
			else:
				f_name = "%04d" % files
			
			var f_name_no_ext: String = f_name.get_basename()
			
			print("%08X %08X %s" % [f_offset, f_size, folder_path + "/%s" % arc_name + "/%s" % f_name])
			
			in_file.seek(f_offset)
			var buff: PackedByteArray = in_file.get_buffer(f_size)
			
			dir.make_dir_recursive(arc_name)
			
			var ovr_id: int = files
			if f_name.get_extension().to_lower() == "bmz":
				buff = ComFuncs.decompress_raw_zlib(buff)
				if debug_out:
					var file_path: String = "%s/%s.DEC" % [base_dir, f_name]
					if FileAccess.file_exists(file_path):
						file_path = "%s/%s%04d.%s" % [base_dir, f_name_no_ext, ovr_id, f_ext]
					var out_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
					out_file.store_buffer(buff)
					out_file.close()
					
				if buff.slice(0, 3).get_string_from_ascii() == "BMZ":
					var pngs: Array[Image] = make_image(buff)
					for png_i in range(pngs.size()):
						var png: Image = pngs[png_i]
						var file_path: String = "%s/%s_%04d.PNG" % [base_dir, f_name, png_i]
						if FileAccess.file_exists(file_path):
							file_path = "%s/%s%04d.%s_%04d.PNG" % [base_dir, f_name_no_ext, ovr_id, f_ext, png_i]
						png.save_png(file_path)
			elif f_name.get_extension().to_lower() == "z":
				buff = ComFuncs.decompress_raw_zlib(buff)
				
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name + ".DEC", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
			elif f_name.get_extension().to_lower() == "fcz":
				var num_imgs: int = ComFuncs.swapNumber(buff.decode_u32(4), "32")
				var off: int = 8
				for i in range(num_imgs):
					var t_name: String = buff.slice(off, off + 8).get_string_from_ascii()
					var comp_size: int = ComFuncs.swapNumber(buff.decode_u32(off + 0x14), "32") + 0x18
					var t_buff: PackedByteArray = ComFuncs.decompress_raw_zlib(buff.slice(off + 0x18, off + comp_size))
					if debug_out:
						var file_path: String = "%s/%s_%s.DEC" % [base_dir, f_name, t_name]
						if FileAccess.file_exists(file_path):
							file_path = "%s/%s%04d.%s_%s" % [base_dir, f_name_no_ext, ovr_id, f_ext, t_name]
						var out_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
						out_file.store_buffer(t_buff)
						out_file.close()
						
					if t_buff.slice(0, 3).get_string_from_ascii() == "BMZ":
						var pngs: Array[Image] = make_image(t_buff)
						for png_i in range(pngs.size()):
							var png: Image = pngs[png_i]
							var file_path: String = "%s/%s_%s_%04d.PNG" % [base_dir, f_name, t_name, png_i]
							if FileAccess.file_exists(file_path):
								file_path = "%s/%s%04d.%s_%04d.PNG" % [base_dir, f_name_no_ext, ovr_id, f_ext, t_name, png_i]
							png.save_png(file_path)
							
					off += comp_size
			else:
				var file_path: String = ""
				if FileAccess.file_exists(base_dir + "/%s" % f_name):
					file_path = "%s/%s%04d.%s" % [base_dir, f_name_no_ext, ovr_id, f_ext]
				else:
					file_path = "%s/%s" % [base_dir, f_name]
				var out_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
	print_rich("[color=green]Finished![/color]")
	
	
func make_image(data: PackedByteArray) -> Array[Image]:
	var num_imgs: int = ComFuncs.swapNumber(data.decode_u32(4), "32")
	var off: int = 0x0C + (num_imgs * 4)
	var width: int = 0
	var height: int = 0
	var off_mod: int = 0
	var img_size: int = 0
	
	var imgs: Array[Image]
	for i in range(num_imgs + 1):
		if i == 0: 
			off_mod = 8
			width = ComFuncs.swapNumber(data.decode_u16(off + 0), "16")
			height = ComFuncs.swapNumber(data.decode_u16(off + 2), "16")
			img_size = ComFuncs.swapNumber(data.decode_u32(off + 4), "32") + off_mod
		else:
			off_mod = 0x14
			width= ComFuncs.swapNumber(data.decode_u16(off + 8), "16")
			height = ComFuncs.swapNumber(data.decode_u16(off + 10), "16")
			img_size = ComFuncs.swapNumber(data.decode_u32(off + 16), "32") + off_mod
		
		imgs.append(Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data.slice(off + off_mod, off + img_size)))
		
		off += img_size
	return imgs


func _on_load_afs_pressed() -> void:
	file_load_afs.show()


func _on_file_load_afs_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_output_debug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out
