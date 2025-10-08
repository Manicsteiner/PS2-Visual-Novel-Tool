extends Control

@onready var file_load_folder: FileDialog = $FILELoadFolder
@onready var file_load_tm_2: FileDialog = $FILELoadTM2
@onready var file_load_gim: FileDialog = $FILELoadGIM
@onready var file_load_search: FileDialog = $FILELoadSearch
@onready var file_load_exe: FileDialog = $FILELoadEXE

var selected_files: PackedStringArray = []
var selected_tm2s: PackedStringArray = []
var selected_gims: PackedStringArray = []
var selected_exe: String = ""
var folder_path: String = ""
var tm2_toggle: bool = true
var bmp_toggle: bool = false

var tm2_fix_alpha: bool = true
var tm2_swizzle: bool = true

var gim_ps2_mode: bool = false

var print_only_exe: bool = false


func _process(_delta: float) -> void:
	if selected_tm2s and folder_path:
		parse_tm2()
		selected_tm2s.clear()
		folder_path = ""
	elif selected_gims and folder_path:
		parse_gim()
		selected_gims.clear()
		folder_path = ""
	elif selected_exe and folder_path:
		extract_exe()
		selected_exe = ""
		folder_path = ""
	elif selected_files:
		search_extract()
		selected_files.clear()
		folder_path = ""
	
	
func parse_tm2() -> void:
	for file in selected_tm2s.size():
		var in_file: FileAccess = FileAccess.open(selected_tm2s[file], FileAccess.READ)
		var f_name: String = selected_tm2s[file].get_file()
		
		in_file.seek(0)
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		
		var pngs: Array[Image] = ComFuncs.load_tim2_images(buff, tm2_fix_alpha, tm2_swizzle)
		for i in range(pngs.size()):
			var png: Image = pngs[i]
			png.save_png(folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
			print("%s" % folder_path + "/%s" % f_name + "_%04d_%04d.PNG" % [file, i])
	print_rich("[color=green]Finished![/color]")
	
	
func parse_gim() -> void:
	for file in selected_gims.size():
		var in_file: FileAccess = FileAccess.open(selected_gims[file], FileAccess.READ)
		var f_name: String = selected_gims[file].get_file()
		
		in_file.seek(0)
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		
		var png: Image = ComFuncs.gim_to_image(buff, f_name, gim_ps2_mode)
		png.save_png(folder_path + "/%s" % f_name + "_%04d.PNG" % file)
		print("%s" % folder_path + "/%s" % f_name + "_%04d.PNG" % file)
	print_rich("[color=green]Finished![/color]")
	
	
func search_extract() -> void:
	if tm2_toggle:
		for file in selected_files.size():
			var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
			var f_name: String = selected_files[file].get_file()
			
			in_file.seek(0)
			ComFuncs.tim2_scan_file(in_file)
			
			print_rich("[color=green]Finished searching in %s[/color]" % f_name)
	print_rich("[color=green]Finished![/color]")
	
	
func extract_exe() -> void:
	var in_file: FileAccess = FileAccess.open(selected_exe, FileAccess.READ)
	var arc_name: String = selected_exe.get_file().get_basename()
	if in_file.get_32() != 0x464C457F:
		OS.alert("%s isn't a valid EXE!" % selected_exe)
		return
	
	in_file.seek(0)
	var exe_info: Dictionary = extract_ps2_exe_symbols(in_file.get_buffer(in_file.get_length()))
	if exe_info:
		var dir: DirAccess = DirAccess.open(folder_path)
		dir.make_dir_recursive(arc_name)
		
		print_rich("[color=yellow]Extracting symbols...[/color]")
		
		for sec_name in exe_info.keys():
			var info = exe_info[sec_name]
			if print_only_exe:
				print("%s: addr=%08X size=%d bytes=%d" % [sec_name, info["address"], info["size"], info["data"].size()])
			else:
				
				var f_name: String = sec_name + "@0x%08X" % info["address"]
				var buff: PackedByteArray = info["data"]
				
				var full_name: String = "%s/%s/%s" % [folder_path, arc_name, f_name]
				
				var out_file: FileAccess = FileAccess.open(full_name, FileAccess.WRITE)
				out_file.store_buffer(buff)
				out_file.close()
	else:
		OS.alert("%s doesn't contain debug symbols." % selected_exe)
		
	print_rich("[color=green]Finished![/color]")
	
	
func unswizzle_ps2_8bpp(data: PackedByteArray, w: int, h: int, pitch: int = 0, phase: int = 2) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(w * h)

	# If pitch not provided, align to 128 (bytes) as GS pages expect.
	var p: int = pitch
	if p <= 0:
		var pages_w: int = (w + 127) / 128  # number of 128-wide pages
		p = pages_w * 128                    # bytes per scanline in VRAM terms

	for y in range(h):
		for x in range(w):
			# ---- Page (128x64) base ----
			var page_y: int = y & ~63       # multiples of 64
			var page_x: int = x & ~127      # multiples of 128
			var page_base: int = page_y * p + page_x * 64  # 128*64 bytes per page

			# ---- Block (16x8) inside page ----
			var blk_y: int = y & 63
			var blk_x: int = x & 127
			# block origin in bytes: (blk_y/8)* (16x8 bytes * blocks_per_row) + (blk_x/16)* (16x8)
			var blocks_per_row: int = 128 / 16 # 8
			var block_index: int = (blk_y / 8) * blocks_per_row + (blk_x / 16)
			var block_base: int = block_index * (16 * 8)  # 128 bytes per 16x8 block

			# ---- Intra-block address (the PS2 bank-swap bit) ----
			var iy: int = blk_y & 7          # 0..7 within 8 rows
			var ix: int = blk_x & 15         # 0..15 within 16 columns

			# Bank swap phase tweak: some games shift this by 0..3; default 2 matches many titles.
			var bs: int = (((iy + phase) >> 2) & 1) * 4
			# Map 16x8 to byte within block (0..127)
			# Left half and right half interleave a bit; this pattern mirrors common GS wiring.
			var cell: int = (((ix + bs) & 7) * 4) + ((iy >> 1) & 1) + ((ix >> 2) & 2)

			# The other 8 columns (ix 8..15) are offset by 32 within the block.
			if ix >= 8:
				cell += 32

			var src_index: int = page_base + block_base + cell
			var dst_index: int = y * w + x

			# Bounds guard (in case data is tightly sized)
			if src_index >= 0 and src_index < data.size():
				out[dst_index] = data[src_index]
	return out
	
	
func morton_unswizzle(data: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	for y in range(h):
		for x in range(w):
			# Interleave bits of x and y
			var idx: int = 0
			var bit: int = 1
			var i: int = 0
			while (1 << i) <= max(w, h):
				if x & (1 << i):
					idx |= bit
				bit <<= 1
				if y & (1 << i):
					idx |= bit
				bit <<= 1
				i += 1
			if idx < data.size():
				out[y * w + x] = data[idx]
	return out
	
	
func unswizzle8x8(data: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(data.size())
	
	var pitch: int = w  # width in pixels
	var blocks_w: int = w / 8
	var blocks_h: int = h / 8
	var src_index: int = 0
	
	for by in range(blocks_h):         # block row
		for bx in range(blocks_w):     # block col
			for iy in range(8):        # inside block Y
				for ix in range(8):    # inside block X
					var dst_x: int = bx * 8 + ix
					var dst_y: int = by * 8 + iy
					var dst_index: int = dst_y * pitch + dst_x
					
					if src_index < data.size() and dst_index < out.size():
						out[dst_index] = data[src_index]
					src_index += 1
					
	return out
	
	
func extract_ps2_exe_symbols(elf_bytes: PackedByteArray) -> Dictionary:
	var symbols: Dictionary = {}
	
	# --- ELF header basics ---
	var e_shoff: int = elf_bytes.decode_u32(0x20)  # Section header table offset
	var e_shentsize: int = elf_bytes.decode_u16(0x2E)
	var e_shnum: int = elf_bytes.decode_u16(0x30)
	var e_shstrndx: int = elf_bytes.decode_u16(0x32)

	# --- Load section header string table ---
	var shstr_hdr_off: int = e_shoff + e_shstrndx * e_shentsize
	var shstr_off: int = elf_bytes.decode_u32(shstr_hdr_off + 0x10)
	var shstr_size: int = elf_bytes.decode_u32(shstr_hdr_off + 0x14)
	var shstr: PackedByteArray = elf_bytes.slice(shstr_off, shstr_off + shstr_size)

	# --- Locate .symtab and .strtab sections ---
	var symtab_off := -1
	var symtab_size := 0
	var symtab_entsize := 0
	var strtab_off := -1
	var strtab_size := 0
	var sections: Array[Dictionary] = []
	
	for i in range(e_shnum):
		var sh_off: int = e_shoff + i * e_shentsize
		var name_off: int = elf_bytes.decode_u32(sh_off + 0x0)
		
		# Resolve section name
		var sec_name := ""
		for j in range(name_off, shstr.size()):
			var c: int = shstr.decode_u8(j)
			if c == 0:
				break
			sec_name += char(c)
		
		var sec_type: int = elf_bytes.decode_u32(sh_off + 0x4)
		var sec_addr: int = elf_bytes.decode_u32(sh_off + 0xC)
		var sec_offset: int = elf_bytes.decode_u32(sh_off + 0x10)
		var sec_size: int = elf_bytes.decode_u32(sh_off + 0x14)
		var sec_entsize: int = elf_bytes.decode_u32(sh_off + 0x24)
		
		sections.append({
			"name": sec_name,
			"addr": sec_addr,
			"offset": sec_offset,
			"size": sec_size
		})
		
		if sec_name == ".symtab":
			symtab_off = sec_offset
			symtab_size = sec_size
			symtab_entsize = sec_entsize
		elif sec_name == ".strtab":
			strtab_off = sec_offset
			strtab_size = sec_size
	
	if symtab_off == -1 or strtab_off == -1:
		push_error("No symbol table found in ELF")
		return symbols
	
	var strtab: PackedByteArray = elf_bytes.slice(strtab_off, strtab_off + strtab_size)
	
	# --- Parse symbols ---
	var num_syms: int = symtab_size / symtab_entsize
	for i in range(num_syms):
		var sym_off: int = symtab_off + i * symtab_entsize
		var st_name: int = elf_bytes.decode_u32(sym_off + 0x0)   # name offset into strtab
		var st_value: int = elf_bytes.decode_u32(sym_off + 0x4)  # symbol virtual address
		var st_size: int = elf_bytes.decode_u32(sym_off + 0x8)   # symbol size
		var st_info: int = elf_bytes.decode_u8(sym_off + 0xC)    # type/binding
		var st_shndx: int = elf_bytes.decode_u16(sym_off + 0xE)  # section index
		
		# Extract symbol name
		var sym_name := ""
		if st_name < strtab.size():
			for j in range(st_name, strtab.size()):
				var c: int = strtab.decode_u8(j)
				if c == 0:
					break
				sym_name += char(c)
		
		# Skip unnamed or invalid symbols
		if sym_name == "" or st_shndx >= sections.size():
			continue
		
		# Try to extract symbol data
		var data_bytes: PackedByteArray = PackedByteArray()
		if st_size > 0:
			var sec := sections[st_shndx]
			var sec_addr: int = sec["addr"]
			var sec_offset: int = sec["offset"]
			var sec_size: int = sec["size"]
			
			# Compute symbol offset relative to section
			var rel_off: int = st_value - sec_addr
			if rel_off >= 0 and rel_off + st_size <= sec_size:
				data_bytes = elf_bytes.slice(sec_offset + rel_off, sec_offset + rel_off + st_size)
		
		# Store symbol info
		symbols[sym_name] = {
			"address": st_value,
			"size": st_size,
			"type": st_info,
			"data": data_bytes
		}
	
	return symbols
	
	
func _on_tm_2_toggle_toggled(_toggled_on: bool) -> void:
	tm2_toggle = !tm2_toggle


func _on_bmp_toggle_toggled(_toggled_on: bool) -> void:
	bmp_toggle = !bmp_toggle


func _on_load_tm_2_pressed() -> void:
	file_load_tm_2.show()


func _on_file_load_tm_2_files_selected(paths: PackedStringArray) -> void:
	selected_tm2s = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_tm_2_fix_alpha_toggled(_toggled_on: bool) -> void:
	tm2_fix_alpha = !tm2_fix_alpha


func _on_tm_2_swizzle_toggled(_toggled_on: bool) -> void:
	tm2_swizzle = !tm2_swizzle


func _on_gimps_2_width_toggled(_toggled_on: bool) -> void:
	gim_ps2_mode = !gim_ps2_mode


func _on_file_load_gim_files_selected(paths: PackedStringArray) -> void:
	selected_gims = paths
	file_load_folder.show()


func _on_load_gim_pressed() -> void:
	file_load_gim.show()


func _on_search_in_files_button_pressed() -> void:
	file_load_search.show()


func _on_file_load_search_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths


func _on_extract_exe_symbols_pressed() -> void:
	file_load_exe.show()
	
	
func _on_file_load_exe_file_selected(path: String) -> void:
	selected_exe = path
	file_load_folder.show()


func _on_exe_print_toggled(_toggled_on: bool) -> void:
	print_only_exe = !print_only_exe
