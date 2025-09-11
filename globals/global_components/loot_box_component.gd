extends Control
class_name LootBoxComponent

signal opened(def: CardDef, item: InvItem)

# ---- External wiring ----
var player: Player = null                        # Assign in Inspector OR add Player to "player" group
var loadout: PlayerLoadout = null                  # Resolved from player in _ready

@export var card_pool: Array[CardDef] = []         # Fill in Inspector

@export var cost_item_id: String = "crystal"
@export var cost_amount: int = 1                   # cost per draw

# ---- Reel visuals ----
@export var tile_size: Vector2i = Vector2i(96, 96)
@export var tile_gap: int = 8
@export var tiles_to_spin: int = 40
@export var spin_duration: float = 2.6

# ---- Preview ----
@export var base_card_scene: PackedScene = preload("res://content/cards/base_cards/view_base_card.tscn")
@export var preview_in_reel_end: bool = true
@export var card_preview_spawn_path: NodePath
@export var clear_previous_preview: bool = true
@export var preview_seconds: float = 2.0

# ---- UI refs (inside this scene) ----
@onready var reel: ScrollContainer = $VBoxContainer/HBoxContainer2/Reel
@onready var row: HBoxContainer = $VBoxContainer/HBoxContainer2/Reel/Row
@onready var marker: ColorRect = $"../Marker"
@onready var btn: Button = $VBoxContainer/HBoxContainer/OpenButton
@onready var btn10 : Button = $VBoxContainer/HBoxContainer/Open10Button
@onready var preview_spawn: Node2D = get_node_or_null(card_preview_spawn_path) as Node2D

var _spinning: bool = false
var _last_preview: Node2D = null

func _ready() -> void:
	randomize()
	row.add_theme_constant_override("separation", tile_gap)

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	assert(player != null, "LootBoxComponent: player not assigned and none found in 'player' group'.")

	loadout = player.loadout
	assert(loadout != null and loadout.cards != null and loadout.items != null)

	# Open 1
	if btn != null and not btn.is_connected("pressed", Callable(self, "open_one")):
		btn.pressed.connect(open_one)

	# Open 10  ← NEW
	if btn10 != null and not btn10.is_connected("pressed", Callable(self, "open_ten")):
		btn10.pressed.connect(open_ten)

	# Affordability reacts to items inventory updates
	if not loadout.items.is_connected("update", Callable(self, "_refresh_afford")):
		loadout.items.update.connect(_refresh_afford)
	_refresh_afford()


# ----------------------------------------------------------------
# Public API (your overlay's Open10 button should call open_n(10))
# ----------------------------------------------------------------
func open_one() -> void:
	open_n(1)
	
func open_ten() -> void:
	open_n(10)

func open_n(n: int) -> void:
	if n <= 0:
		return
	if _spinning:
		return
	if card_pool.is_empty():
		return
	if loadout == null or loadout.items == null or loadout.cards == null:
		return

	# Pay upfront for all draws (atomic)
	var total_cost: int = cost_amount * n
	if total_cost > 0:
		if not _can_afford_total(n):
			# OPTIONAL: show "Not enough shards"
			return
		if not _pay_total(n):
			return

	_spinning = true
	btn.disabled = true
	await _run_draw_sequence(n)
	_spinning = false
	_refresh_afford()

# ----------------------------------------------------------------
# Draw sequence (runs n times in a row)
# ----------------------------------------------------------------
func _run_draw_sequence(n: int) -> void:
	for i: int in range(n):
		var def: CardDef = _pick_weighted(card_pool)
		if def == null:
			continue

		await _spin_to(def)  # spin VISUALLY to THIS def

		# Create the inventory item and insert into CARDS inv
		var item: InvItem = InvItem.new()
		item.id = String(def.id)
		item.texture = def.icon
		item.stack_size = def.stack_size
		item.card_def = def

		loadout.cards.insert(item, 1)
		opened.emit(def, item)

		# Show big preview for this exact def
		if preview_in_reel_end and base_card_scene != null:
			await _show_preview(def)

# ----------------------------------------------------------------
# Reel spin to a specific def
# ----------------------------------------------------------------
func _spin_to(target_def: CardDef) -> void:
	# Clear reel
	for c: Node in row.get_children():
		c.queue_free()
	await get_tree().process_frame

	# Sizing
	var visible_w: float = reel.size.x                     # viewport width
	var tile_w: float = float(tile_size.x + tile_gap)
	var center_offset: float = max((visible_w - float(tile_size.x)) * 0.5, 0.0)

	# How many padding tiles are needed to allow centering the first/last tiles
	var pad_tiles: int = int(ceil(center_offset / tile_w)) + 1

	# LEFT padding (can be blanks or randoms; randoms look nicer)
	for i in range(pad_tiles):
		row.add_child(_make_tile(_pick_weighted(card_pool)))

	# Spin content before the target
	for i in range(tiles_to_spin - 1):
		row.add_child(_make_tile(_pick_weighted(card_pool)))

	# Target tile
	var target_tile: Control = _make_tile(target_def)
	row.add_child(target_tile)

	# RIGHT padding
	for i in range(pad_tiles):
		row.add_child(_make_tile(_pick_weighted(card_pool)))

	await get_tree().process_frame

	# Scroll so the target centers under the marker
	reel.scroll_horizontal = 0
	var target_index: int = pad_tiles + (tiles_to_spin - 1)   # index of target in the row
	var target_x: float = target_index * tile_w
	var target_scroll: float = max(target_x - center_offset, 0.0)

	# Optional clamp to the real max just in case layouts change
	# var hbar := reel.get_h_scroll_bar()
	# if hbar: target_scroll = clamp(target_scroll, 0.0, hbar.max_value)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(reel, "scroll_horizontal", int(target_scroll), spin_duration)
	await tw.finished

# ----------------------------------------------------------------
# Preview of the pulled card (2s)
# ----------------------------------------------------------------
func _show_preview(def: CardDef) -> void:
	if clear_previous_preview and _last_preview != null and is_instance_valid(_last_preview):
		_last_preview.queue_free()
		_last_preview = null

	var node: Node = base_card_scene.instantiate()
	var as_2d: Node2D = node as Node2D

	var parent: Node = null
	if preview_spawn != null:
		parent = preview_spawn
	else:
		parent = self

	parent.add_child(node)

	if as_2d != null and preview_spawn != null:
		as_2d.position = Vector2.ZERO

	if node.has_method("set_card_values"):
		node.call("set_card_values", def.level, def.atk, def.hp, def.name, def.description)

	node.visible = true
	_last_preview = as_2d

	await get_tree().create_timer(preview_seconds).timeout

	if is_instance_valid(node):
		node.queue_free()
	_last_preview = null


# ----------------------------------------------------------------
# Tile rendering
# ----------------------------------------------------------------
func _make_tile(def: CardDef) -> Control:
	var tile: PanelContainer = PanelContainer.new()
	tile.custom_minimum_size = Vector2(tile_size)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
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

	var inner: MarginContainer = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 6)
	inner.add_theme_constant_override("margin_top", 6)
	inner.add_theme_constant_override("margin_right", 6)
	inner.add_theme_constant_override("margin_bottom", 6)
	tile.add_child(inner)

	var tex: TextureRect = TextureRect.new()
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = def.icon
	tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(tex)

	return tile

# ----------------------------------------------------------------
# Costs (use loadout.items)
# ----------------------------------------------------------------
func _refresh_afford() -> void:
	var pool_empty: bool = card_pool.is_empty()
	var can_one: bool = _can_afford_total(1)
	var can_ten: bool = _can_afford_total(10)

	if btn != null:
		btn.disabled = _spinning or pool_empty or not can_one
	if btn10 != null:
		btn10.disabled = _spinning or pool_empty or not can_ten


func _can_afford_total(n: int) -> bool:
	if loadout == null or loadout.items == null:
		return false
	var need: int = cost_amount * n
	if need <= 0:
		return true
	return loadout.items.count_by_id(cost_item_id) >= need

func _pay_total(n: int) -> bool:
	if loadout == null or loadout.items == null:
		return false
	var need: int = cost_amount * n
	if need <= 0:
		return true
	return loadout.items.remove_by_id(cost_item_id, need)

# ----------------------------------------------------------------
# Weighted pick helper
# ----------------------------------------------------------------
static func _pick_weighted(pool: Array[CardDef]) -> CardDef:
	var total: float = 0.0
	for def: CardDef in pool:
		total += max(def.get_weight(), 0.0)
	if total <= 0.0:
		return null
	var r: float = randf() * total
	for def: CardDef in pool:
		r -= max(def.get_weight(), 0.0)
		if r <= 0.0:
			return def
	return pool.back()

# --- Affordability helpers ----------------------------------------------------
