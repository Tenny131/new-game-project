extends Control
class_name LootBox

signal opened(def: CardDef, item: InvItem)

@export var player_inventory: Inv
@export var card_pool: Array[CardDef] = []
@export var draws_per_open: int = 1
@export var spawn_point_path: NodePath
@export var base_card_scene: PackedScene = preload("res://scenes/objects/cards/base_card.tscn")

@onready var btn: Button = $"../Button"
@onready var spawn_point: Node = get_node_or_null(spawn_point_path)

func _ready() -> void:
	randomize()
	btn.pressed.connect(_on_button_pressed)
	btn.disabled = card_pool.is_empty() or player_inventory == null

func _on_button_pressed() -> void:
	if card_pool.is_empty() or player_inventory == null:
		return

	for i in draws_per_open:
		var def := _pick_weighted(card_pool)
		if def == null:
			continue

		# optional preview of full card
		if spawn_point:
			var card: BaseCard = base_card_scene.instantiate()
			spawn_point.add_child(card)
			card.set_card_values(def.level, def.atk, def.hp, def.name, def.description)
			card.visible = true

		# create inventory item (stacks by id in your Inv.gd)
		var item: InvItem = InvItem.new()
		item.id = def.name
		item.texture = def.icon
		item.stack_size = def.stack_size

		player_inventory.insert(item, 1)
		opened.emit(def, item)

# ---------- weighted roll using CardDef.get_weight() ----------
static func _pick_weighted(pool: Array[CardDef]) -> CardDef:
	var total := 0.0
	for def in pool:
		total += max(def.get_weight(), 0.0)
	if total <= 0.0:
		return null

	var r := randf() * total
	for def in pool:
		r -= max(def.get_weight(), 0.0)
		if r <= 0.0:
			return def
	return pool.back()
