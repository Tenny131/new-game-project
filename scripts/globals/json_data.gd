extends Node

var item_data: Dictionary

func _ready() -> void:
	item_data = load_data("res://scenes/ui/item_data.json")
	
func load_data(file_path):
	var file_data = FileAccess.open(file_path, FileAccess.READ)
	var json_data = JSON.new()
	json_data.parse(file_data.get_as_text())
	file_data.close()
	return json_data.get_data()


	
