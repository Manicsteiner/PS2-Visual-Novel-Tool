extends Control

@onready var file_load_bmz: FileDialog = $FILELoadBMZ
@onready var file_load_folder: FileDialog = $FILELoadFOLDER

var selected_files: PackedStringArray
var folder_path: String = ""
var debug_out: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_load_bmz.filters = ["*.BMZ"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if selected_files and folder_path:
		create_img()
		selected_files.clear()
		
	
	
func create_img() -> void:
	var decoder = DeflateDecoder.new()
	
	for file: int in selected_files.size():
		var in_file: FileAccess = FileAccess.open(selected_files[file], FileAccess.READ)
		var arc_name: String = selected_files[file].get_file().get_basename()
		
		var buff: PackedByteArray = in_file.get_buffer(in_file.get_length())
		var width: int = buff.decode_u16(4)
		var height: int = buff.decode_u16(6)
		var slice_off: int = 0x10
		
		buff = decoder.decompress(buff.slice(slice_off))
		if debug_out:
			var out_file: FileAccess = FileAccess.open(folder_path + "/%s" % arc_name + ".DEC", FileAccess.WRITE)
			out_file.store_buffer(buff)
			
		if arc_name.contains("CARD") or arc_name.contains("PHOTO"):
			buff.resize(buff.size() - 2) # contains some padded bytes at end
			
		print("%d %d " % [width, height] + folder_path + "/%s" % arc_name + ".PNG")
		var png: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, buff)
		png.save_png(folder_path + "/%s" % arc_name + ".PNG")
	print_rich("[color=green]Finished![/color]")


func _on_outdebug_toggled(_toggled_on: bool) -> void:
	debug_out = !debug_out


func _on_file_load_bmz_files_selected(paths: PackedStringArray) -> void:
	selected_files = paths
	file_load_folder.show()


func _on_file_load_folder_dir_selected(dir: String) -> void:
	folder_path = dir


func _on_load_bmz_pressed() -> void:
	file_load_bmz.show()
