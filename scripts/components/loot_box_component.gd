extends Control
class_name LootBoxComponent

signal opened(def: CardDef, item: InvItem)

@export var player_inventory: Inv
@export var card_pool: Array[CardDef] = []
@export var draws_per_open: int = 1

# Reel visuals
@export var tile_size: Vector2i = Vector2i(96, 96)
@export var tile_gap: int = 8
@export var tiles_to_spin: int = 40
@export var spin_duration: float = 2.6

# Big preview
@export var base_card_scene: PackedScene = preload("res://scenes/objects/cards/base_card.tscn")
@export var preview_in_reel_end: bool = true
@export var card_preview_spawn_path: NodePath            # ← assign your Node2D CardPreviewSpawnPoint here
@export var clear_previous_preview: bool = true

@export var cost_item_id := "Shard"
@export var cost_amount := 10

@onready var reel: ScrollContainer = $Reel
@onready var row: HBoxContainer = $Reel/Row
@onready var marker: ColorRect = $Marker
@onready var btn: Button = $OpenButton

@onready var preview_spawn: Node2D = get_node_or_null(card_preview_spawn_path) as Node2D

var _spinning := false
var _last_preview: BaseCard = null

func _ready() -> void:
	# ... existing ...
	if player_inventory:
		player_inventory.update.connect(_refresh_afford)
	_refresh_afford()

func _refresh_afford() -> void:
	btn.disabled = card_pool.is_empty() or player_inventory == null or not _can_afford()


func _on_button_pressed() -> void:
	if _spinning or card_pool.is_empty() or player_inventory == null:
		return
	if not _can_afford():
		# TODO: flash the button red or show a toast “Not enough Shards”
		return
	if not _pay_cost():
		return
	# ... existing spin logic continues ...

	if _spinning or card_pool.is_empty() or player_inventory == null:
		return

	for _i in range(draws_per_open):
		var def: CardDef = _pick_weighted(card_pool)
		if def == null:
			continue
		await _spin_to(def)

		# reward → inventory
		var item: InvItem = InvItem.new()
		item.id = def.name
		item.texture = def.icon
		item.stack_size = def.stack_size
		item.card_def = def
		player_inventory.insert(item, 1)
		opened.emit(def, item)

		# optional big preview at the spawn point
		if preview_in_reel_end and base_card_scene:
			var parent: Node = preview_spawn if preview_spawn != null else self
			if clear_previous_preview and _last_preview and is_instance_valid(_last_preview):
				_last_preview.queue_free()

			var card: BaseCard = base_card_scene.instantiate()
			parent.add_child(card)
			if parent is Node2D:
				card.position = Vector2.ZERO
			card.set_card_values(def.level, def.atk, def.hp, def.name, def.description)
			card.visible = true
			_last_preview = card

func _spin_to(target_def: CardDef) -> void:
	_spinning = true
	btn.disabled = true

	# Clear reel
	for c in row.get_children():
		c.queue_free()
	await get_tree().process_frame

	# Build reel: random tiles + target at end
	for _i in range(tiles_to_spin - 1):
		var d := _pick_weighted(card_pool)
		row.add_child(_make_tile(d))
	var target_tile := _make_tile(target_def)
	row.add_child(target_tile)

	await get_tree().process_frame

	# Scroll calc so target centers under marker
	reel.scroll_horizontal = 0
	var visible_w: float = reel.size.x
	var tile_w: float = float(tile_size.x + tile_gap)
	var target_index: int = row.get_child_count() - 1
	var target_x: float = target_index * tile_w
	var center_offset: float = (visible_w - float(tile_size.x)) * 0.5
	var target_scroll: float = max(target_x - center_offset, 0.0)

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(reel, "scroll_horizontal", int(target_scroll), spin_duration)
	await tw.finished

	_spinning = false
	btn.disabled = false

func _make_tile(def: CardDef) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(tile_size)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0,0,0,0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = def.get_color()
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	tile.add_theme_stylebox_override("panel", sb)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 6)
	inner.add_theme_constant_override("margin_top", 6)
	inner.add_theme_constant_override("margin_right", 6)
	inner.add_theme_constant_override("margin_bottom", 6)
	tile.add_child(inner)

	var tex := TextureRect.new()
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = def.icon
	tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(tex)

	return tile

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
	
func _can_afford() -> bool:
	var inv_ref: Inv = player_inventory
	return inv_ref != null and inv_ref.count_by_id(cost_item_id) >= cost_amount

func _pay_cost() -> bool:
	var inv_ref: Inv = player_inventory
	return inv_ref != null and inv_ref.remove_by_id(cost_item_id, cost_amount)
