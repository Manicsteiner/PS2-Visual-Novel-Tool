extends Control

@onready var file_load_dt: FileDialog = $FILELoadDT
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var folder_path:String
var selected_files: PackedStringArray

func _ready() -> void:
	file_load_dt.filters = ["*.DT"]
	
	
func _process(_delta: float) -> void:
	if folder_path and selected_files:
		extract_dt_hd()
		selected_files.clear()
		folder_path = ""


func extract_dt_hd() -> void:
	for file in range(0, selected_files.size()):
		var arc_name: String = selected_files[file].get_file().get_basename()
		var hd_path: String = selected_files[file].get_basename() + ".HD"
		var dt_path: String = selected_files[file].get_basename() + ".DT"

		var hd_file := FileAccess.open(hd_path, FileAccess.READ)
		if hd_file == null:
			push_error("Failed to open: " + hd_path)
			return
		var hd_size: int = hd_file.get_length()

		var hd_buffer: PackedByteArray = hd_file.get_buffer(hd_size)
		hd_file.close()

		var dt_file := FileAccess.open(dt_path, FileAccess.READ)
		if dt_file == null:
			push_error("Failed to open: " + dt_path)
			return

		var dir: DirAccess = DirAccess.open(folder_path)
		dir.make_dir_recursive_absolute(folder_path + "/" + arc_name)
		
		var entry_count: int = hd_buffer.size() / 8
		for i in range(entry_count):
			var f_off: int = hd_buffer.decode_u32(i * 8)
			var f_size: int = hd_buffer.decode_u32(i * 8 + 4)

			dt_file.seek(f_off)
			var buffer: PackedByteArray = dt_file.get_buffer(f_size)
			
			var f_name: String = ""
			if buffer.slice(0, 2).get_string_from_ascii() == "BM":
				f_name = "%04d.BMP" % i
			else:
				f_name = "%04d.BIN" % i
				
					
			var out_file := FileAccess.open(folder_path + "/%s" % arc_name + "/%s" % f_name, FileAccess.WRITE)
			out_file.store_buffer(buffer)
			out_file.close()

			print("%08X %08X %s/%s/%s" % [f_off, f_size, folder_path, arc_name, f_name])

		dt_file.close()
	print_rich("[color=green]Finished![/color]")


func _on_file_load_dt_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_dt_pressed() -> void:
	file_load_dt.show()
