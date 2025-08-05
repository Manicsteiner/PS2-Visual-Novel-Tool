extends Control

@onready var file_load_pac: FileDialog = $FILELoadPAC
@onready var file_load_folder: FileDialog = $FILELoadFOLDER
@onready var file_load_irx: FileDialog = $FILELoadIRX

var selected_files: PackedStringArray
var selected_irx: String = ""
var folder_path: String = ""
var out_decomp: bool = false

enum {
	BG,
	BUP,
	SCRA,
	SPR}
	
var type: int

#TODO: There is likely a table that determines part ordering of tiles somewhere. They are currently guessed.

func _ready() -> void:
	file_load_irx.filters = ["CAGEIOP.IRX,KJIOP.IRX,USKYIOP.IRX"]
	file_load_pac.filters = ["GAMEBG.PAC,GAMEBUP.PAC,GAMESCRA.PAC,GAMESCRB.PAC,SYSBG.PAC,SYSSPR.PAC"]
	
	
func _process(_delta: float) -> void:
	if selected_files and folder_path:
		extract_pac()
		selected_files.clear()
		folder_path = ""
	
	
func extract_pac() -> void:
	for file: int in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var irx_file: FileAccess = FileAccess.open(selected_irx, FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		var tbl_start: int
		var tbl_end: int
		if Main.game_type == Main.KOUENJIJOSHI:
			if arc_name == "GAMEBG":
				type = BG
				tbl_start = 0x10068
				tbl_end = 0x10EF0
			elif arc_name == "GAMEBUP":
				type = BUP
				tbl_start = 0x10EF0
				tbl_end = 0x11570
			elif arc_name == "GAMESCRA":
				type = SCRA
				tbl_start = 0x11570
				tbl_end = 0x11618
			elif arc_name == "GAMESCRB":
				type = BG
				tbl_start = 0x11618
				tbl_end = 0x11910
			elif arc_name == "SYSBG":
				type = BG
				tbl_start = 0xFE50
				tbl_end = 0xFFA0
			elif arc_name == "SYSSPR":
				type = SPR
				tbl_start = 0xFFA0
				tbl_end = 0x10068
		elif Main.game_type == Main.KONOHARETA:
			if arc_name == "GAMEBG":
				type = BG
				tbl_start = 0xC668
				tbl_end = 0xD020
			elif arc_name == "GAMEBUP":
				type = BUP
				tbl_start = 0xD020
				tbl_end = 0xD568
			elif arc_name == "SYSBG":
				type = BG
				tbl_start = 0xC468
				tbl_end = 0xC5A8
			elif arc_name == "SYSSPR":
				type = SPR
				tbl_start = 0xC5A8
				tbl_end = 0xC668
		elif Main.game_type == Main.SHIROGANENOTORIKAGO:
			if arc_name == "GAMEBG":
				type = BG
				tbl_start = 0xD740
				tbl_end = 0xDFE8
			elif arc_name == "GAMEBUP":
				type = BUP
				tbl_start = 0xDFE8
				tbl_end = 0xE5E0
			elif arc_name == "SYSBG":
				type = BG
				tbl_start = 0xD528
				tbl_end = 0xD660
			elif arc_name == "SYSSPR":
				type = SPR
				tbl_start = 0xD660
				tbl_end = 0xD740
			
		var table: int = tbl_start
		var id: int = 0
		while table < tbl_end:
			irx_file.seek(table)
			var f_off: int = irx_file.get_32()
			var f_size: int = irx_file.get_32()
			#if id != 17:
				#table += 8
				#id += 1
				#continue
			
			print("%08X %08X %s" % [f_off, f_size, folder_path + "/%s" % arc_name + "%04d" % id + ".BIN"])
			
			in_file.seek(f_off)
			var buff: PackedByteArray
			if Main.game_type == Main.KOUENJIJOSHI:
				buff = decode_rle_to_rgba(in_file.get_buffer(f_size))
			else:
				buff = in_file.get_buffer(f_size)
				for i in range(0, f_size, 4):
					buff.encode_u8(i + 3, int((buff.decode_u8(i + 3) / 127.0) * 255.0))
				
			if out_decomp:
				var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + "%04d" % id + ".BIN", FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
				
			if arc_name == "SYSSPR":
				var png: Image = Image.create_from_data(256, 256, false, Image.FORMAT_RGBA8, buff)
				png.save_png(folder_path + "/%s" % arc_name + "%04d" % id + ".PNG")
			else:
				var png: Image = build_image_from_parts(buff)
				png.save_png(folder_path + "/%s" % arc_name + "%04d" % id + ".PNG")
				
			table += 8
			id += 1
			
	print_rich("[color=green]Finished![/color]")
	
	
	
#func rearrange_2col_vertical(image: Image, tile_w: int = 256, tile_h: int = 256) -> Image:
	#var full_w: int = image.get_width()
	#var full_h: int = image.get_height()
	#var final_img: Image = Image.create(full_w, full_h, false, Image.FORMAT_RGBA8)
	#
	#var num_cols: int = full_w / tile_w
	#var num_rows: int = ceil(float(full_h) / tile_h)
	#
	#var tile_index: int = 0
	#for col in range(num_cols):
		#for row in range(num_rows):
			#var src_x: int = col * tile_w
			#var src_y: int = row * tile_h
			#var tile_width: int = min(tile_w, full_w - src_x)
			#var tile_height: int = min(tile_h, full_h - src_y)
			#
			#var rect := Rect2(src_x, src_y, tile_width, tile_height)
			#var tile: Image = image.get_rect(rect)
			#
			## Rearranged positions
			#var dst_x: int = col * tile_w
			#var dst_y: int = row * tile_h
			#final_img.blit_rect(tile, Rect2i(0, 0, tile_width, tile_height), Vector2i(dst_x, dst_y))
			#
			#tile_index += 1
	#
	#return final_img
	
	
func decode_rle_to_rgba(data: PackedByteArray) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	var offset: int = 4
	var data_len: int = data.size()
	var dec_size: int = data.decode_u32(0)
	if dec_size >= 0x1000000: return PackedByteArray()

	while offset + 5 <= data_len and data.decode_u32(offset) != 0:
		var count: int = data.decode_u8(offset)
		var r: int = data.decode_u8(offset + 1)
		var g: int = data.decode_u8(offset + 2)
		var b: int = data.decode_u8(offset + 3)
		var a: int = data.decode_u8(offset + 4)
		a = int((a / 128.0) * 255.0)
		
		for _i in count:
			result.append(r)
			result.append(g)
			result.append(b)
			result.append(a)
			
		if result.size() > dec_size: 
			break

		offset += 5

	return result
	
	
func build_image_from_parts(img_data: PackedByteArray) -> Image:
	var IMAGE_WIDTH: int
	var IMAGE_HEIGHT: int
	var parts: Array[Vector4i] = []
	
	if type == BG:
		IMAGE_WIDTH = 640
		IMAGE_HEIGHT= 448
		if Main.game_type == Main.KOUENJIJOSHI:
			parts = [
			Vector4i(256, 256,   0,   0),
			Vector4i(256, 256, 256,   0),
			Vector4i(128, 256, 512,   0),
			Vector4i(256, 128,   0, 256),
			Vector4i(256, 128, 256, 256),
			Vector4i(128, 128, 512, 256),
			Vector4i(256, 64,    0, 384),
			Vector4i(256, 64,  256, 384),
			Vector4i(128, 64,  512, 384),
			]
		elif Main.game_type == Main.SHIROGANENOTORIKAGO or Main.game_type == Main.KONOHARETA:
			parts = [
			Vector4i(256, 256, 0, 0),
			Vector4i(256, 256, 256, 0),
			Vector4i(128, 256, 512, 0),
			Vector4i(256, 128, 0, 256),
			Vector4i(256, 128, 0, 384),
			Vector4i(256, 256, 256, 256),
			Vector4i(128, 192, 512, 256),
			]
	elif type == BUP:
		IMAGE_WIDTH = 640
		IMAGE_HEIGHT= 448
		if Main.game_type == Main.KOUENJIJOSHI:
			parts = [
			Vector4i(256, 256, 0, 0),
			Vector4i(64, 64, 0, 64),
			Vector4i(64, 192, 256, 64),
			Vector4i(256, 128,   0, 256),
			Vector4i(64, 128, 256, 256),
			Vector4i(256, 64, 0, 384),
			]
		elif Main.game_type == Main.SHIROGANENOTORIKAGO:
			parts = [
			Vector4i(256, 256, 0, 0),
			Vector4i(64, 64, 256, 0),
			Vector4i(64, 192, 256, 64),
			Vector4i(256, 256, 0, 256),
			Vector4i(64, 64, 256, 256),
			Vector4i(64, 128, 256, 320),
			]
		elif Main.game_type == Main.KONOHARETA:
			parts = [
			Vector4i(256, 256,   0,   0),
			Vector4i(256, 256, 256,   0),
			Vector4i(128, 256, 512,   0),
			Vector4i(256, 256,   0, 256),
			Vector4i(256, 256, 256, 256),
			Vector4i(128, 256, 512, 256),
			]
	elif type == SCRA:
		IMAGE_WIDTH = 960
		IMAGE_HEIGHT= 256
		parts = [
		Vector4i(256, 256,   0,   0),
		Vector4i(256, 256, 256,   0),
		Vector4i(256, 256, 512,   0),
		Vector4i(128, 256,   768, 0),
		Vector4i(64, 256, 896, 0)
		]

	var full_image: Image = Image.create_empty(IMAGE_WIDTH, IMAGE_HEIGHT, false, Image.FORMAT_RGBA8)

	var offset: int = 0
	for part in parts:
		var pw: int = part.x
		var ph: int = part.y
		var px: int = part.z
		var py: int = part.w
		var part_size: int = pw * ph * 4  # RGBA

		var part_data: PackedByteArray = img_data.slice(offset, offset + part_size)
		offset += part_size

		var tile: Image = Image.create_from_data(pw, ph, false, Image.FORMAT_RGBA8, part_data)
		full_image.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(pw, ph)), Vector2i(px, py))

	return full_image


#func build_image_from_vertical_tiles(img_data: PackedByteArray) -> Image:
	#const IMAGE_WIDTH: int = 512
	#const IMAGE_HEIGHT: int = 280
	#
	#var parts: Array[Vector4i] = [
	#Vector4i(192, 140,   0,   0),   # Left column, top row
	#Vector4i(192, 140, 192,   0),   # Center column, top row
	#Vector4i(128, 140, 384,   0),   # Right column, top row
	#Vector4i(192, 140,   0, 140),   # Left column, bottom row
	#Vector4i(192, 140, 192, 140),   # Center column, bottom row
	#Vector4i(128, 140, 384, 140),   # Right column, bottom row
	#]
#
	#var full_image: Image = Image.create_empty(IMAGE_WIDTH, IMAGE_HEIGHT, false, Image.FORMAT_RGBA8)
#
	#var offset: int = 0
	#for part in parts:
		#var pw: int = part.x
		#var ph: int = part.y
		#var px: int = part.z
		#var py: int = part.w
		#var part_size: int = pw * ph * 4  # RGBA
#
		#var part_data: PackedByteArray = img_data.slice(offset, offset + part_size)
		#offset += part_size
#
		#var tile: Image = Image.create_from_data(pw, ph, false, Image.FORMAT_RGBA8, part_data)
		#full_image.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(pw, ph)), Vector2i(px, py))
#
	#return full_image
	
	
#func brute_force_image_layout(img_data: PackedByteArray, image_width: int, image_height: int) -> Array[Image]:
	#var results: Array[Image] = []
#
	#var total_pixels: int = img_data.size() / 4
	#if total_pixels != image_width * image_height:
		#push_error("Data size does not match image dimensions!")
		#return results
#
	## Try tile widths that divide image_width
	#for tile_width in [128, 256, 512]:
		#if image_width % tile_width != 0:
			#continue
#
		## Try tile heights that divide image_height
		#for tile_height in [64, 128, 256]:
			#if image_height % tile_height != 0:
				#continue
#
			#var tiles_x: int = image_width / tile_width
			#var tiles_y: int = image_height / tile_height
			#var num_tiles: int = tiles_x * tiles_y
#
			## Generate full image
			#var full_image: Image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
			#var offset: int = 0
#
			#for y in range(tiles_y):
				#for x in range(tiles_x):
					#var part_size: int = tile_width * tile_height * 4
					#if offset + part_size > img_data.size():
						#continue
#
					#var part_data: PackedByteArray = img_data.slice(offset, offset + part_size)
					#offset += part_size
#
					#var tile: Image = Image.create_from_data(tile_width, tile_height, false, Image.FORMAT_RGBA8, part_data)
					#full_image.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(tile_width, tile_height)), Vector2i(x * tile_width, y * tile_height))
#
			#results.append(full_image)
#
	#return results
	
	
func _on_load_irx_pressed() -> void:
	file_load_irx.show()


func _on_load_pac_pressed() -> void:
	if not selected_irx:
		OS.alert("Please load a known module (.IRX) first.")
		return
		
	file_load_pac.show()


func _on_file_load_irx_file_selected(path: String) -> void:
	selected_irx = path


func _on_file_load_pac_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_decomp_button_toggled(_toggled_on: bool) -> void:
	out_decomp = !out_decomp
