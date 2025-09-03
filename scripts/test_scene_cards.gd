extends Node2D

@onready var base_card_scene: PackedScene = preload("res://scenes/objects/cards/base_card.tscn")
@onready var spawn_point: Node = $CanvasLayer/CardSpawnPoint
@onready var player_inventory: Inv = preload("res://inventory/player_inventory.tres")

# Make/assign some card defs in the Inspector
@export var card_pool: Array[CardDef]    # Array of CardDef .tres files

# EITHER: assign in Inspector…
@export var player: Player

func _ready() -> void:
	randomize()
	# …OR auto-find by group as a fallback:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player

func _on_button_pressed() -> void:
	if card_pool.is_empty():
		push_error("card_pool is empty. Assign CardDef .tres files in the Inspector.")
		return

	var def: CardDef = card_pool[randi() % card_pool.size()]

	# (Optional) show full card scene
	var generated_card: BaseCard = base_card_scene.instantiate()
	spawn_point.add_child(generated_card)
	generated_card.set_card_values(def.level, def.atk, def.hp, def.name, def.description)
	generated_card.visible = true

	# Create inventory item from the card
	var item: InvItem = InvItem.new()
	item.id = def.name
	item.texture = def.icon
	#item.stack_size = 1  # cards don’t stack

	# Insert into inventory via player
	if player and is_instance_valid(player):
		player.collect(item)  # Player.collect -> inv.insert(item)
	else:
		push_error("Player not found. Assign 'player' in Inspector OR add Player to 'player' group.")
