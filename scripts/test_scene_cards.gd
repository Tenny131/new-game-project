extends Node2D

@onready var base_card_scene: PackedScene = preload("res://scenes/objects/cards/base_card.tscn")
@onready var spawn_point: Node = $CanvasLayer/CardSpawnPoint
@onready var player_inventory: Inv = preload("res://inventory/player_inventory.tres")

@export var card_pool: Array[CardDef]

func _ready() -> void:
	randomize()

func _on_button_pressed() -> void:
	if card_pool.is_empty():
		push_error("card_pool is empty. Assign CardDef .tres files in the Inspector.")
		return

	var def: CardDef = card_pool[randi() % card_pool.size()]

	# (optional) show full card
	var generated_card: BaseCard = base_card_scene.instantiate()
	spawn_point.add_child(generated_card)
	generated_card.set_card_values(def.level, def.atk, def.hp, def.name, def.description)
	generated_card.visible = true

	# create stackable item (id is the key used for stacking)
	var item: InvItem = InvItem.new()
	item.id = def.name
	item.texture = def.icon
	item.stack_size = def.stack_size  # enable stacking

	player_inventory.insert(item, 1)  # insert 1 copy
