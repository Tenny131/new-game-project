extends Node2D

@onready var item_name: String = "Stone"
var item_quantity: int


func _ready() -> void:
	#$TextureRect.texture = load("res://assets/game/objects/items/Orange Gem.png")
	var stack_size = int(JsonData.item_data[item_name]["StackSize"])
	item_quantity = randi() % stack_size + 1
	
	if stack_size == 1:
		$Label.visible = false
	#else:
		#$Label.text = String(str(item_quantity))
	
func set_item(_name, _quantity):
	item_name = _name
	item_quantity = _quantity
	$TextureRect.texture = load("res://assets/game/objects/items/Orange Gem.png")
	
	var stack_size = int(JsonData.item_data[item_name]["StackSize"]) 
	if stack_size == 1:
		$Label.visible = false
	else:
		$Label.text = String(str(item_quantity))
		$Label.visible = true
		
		
func add_item_quantity(_add_amount):
	item_quantity += _add_amount
	$Label.text = String(str(item_quantity))

func remove_item_quantity(_remove_amount):
	item_quantity -= _remove_amount
	$Label.text = String(str(item_quantity))
