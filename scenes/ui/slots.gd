class_name Slots
extends Node

var default_texture = preload("res://assets/UI/inventory/default_inventory_background.png")
var empty_texture = preload("res://assets/UI/inventory/item_slot_empty_background.png")

var default_style: StyleBoxTexture = null
var empty_style: StyleBoxTexture = null

#var card = preload("res://scenes/objects/cards/base_card.tscn")
var ItemClass = preload("res://scenes/objects/items/item_drop.tscn")
var item = null
var slot_size = Vector2(18, 18)

func _ready() -> void:
	default_style = StyleBoxTexture.new()
	empty_style = StyleBoxTexture.new()
	default_style.texture = default_texture
	empty_style.texture = empty_texture
	
	if randi() % 2 == 0:
		#if randi() % 2 == 0:
			#item = card.instantiate()
			#item.scale = Vector2(0.03, 0.03)
			#item.position = slot_size / 2
			#add_child(item)
		#else:
		#item = card.instantiate()
		#item.scale = Vector2(0.3, 0.3)
		#item.position = slot_size / 2
		#add_child(item)
		pass
	refresh_style()
	
func refresh_style():
	if item == null:
		set('theme_override_styles/panel', empty_style)
	else:
		set('theme_override_styles/panel', default_style)
		
func pick_from_slot():
	remove_child(item)
	var inventory_node = find_parent("Inventory")
	inventory_node.add_child(item)
	item = null
	refresh_style()
	
func put_into_slot(new_item):
	item = new_item
	item.position = slot_size / 2
	var inventory_node = find_parent("Inventory")
	inventory_node.remove_child(item)
	add_child(item)
	refresh_style()
	
func initialize_item(item_name, item_quantity):
	if item == null:
		item = ItemClass.instantiate()
		add_child(item)
		#item.set_item(item_name, item_quantity)
	else:
		pass#item.set_item(item_name, item_quantity)
	refresh_style()
		
	
