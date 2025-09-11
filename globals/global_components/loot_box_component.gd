extends Control
class_name LootBoxComponent
signal opened(def: CardDef, item: InvItem)

# ---- External wiring ----
var player: Player = null
var loadout: PlayerLoadout = null
@export var card_pool: Array[CardDef] = []
@export var cost_item_id: String = "crystal"
@export var cost_amount: int = 1

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

# ---- UI refs ----
@onready var reel: ScrollContainer = $VBoxContainer/HBoxContainer2/Reel
@onready var row: HBoxContainer = $VBoxContainer/HBoxContainer2/Reel/Row
@onready var marker: ColorRect = $"../../../../../Marker"
@onready var btn: Button = $VBoxContainer/HBoxContainer/OpenButton
@onready var btn10 : Button = $VBoxContainer/HBoxContainer/Open10Button
@onready var preview_spawn: Node2D = get_node_or_null(card_preview_spawn_path) as Node2D

# ===== NEW: Lootbox-defined rarity weights & colors (Inspector) =====
# Display buckets used by your legend: Common, Rare, Epic, Legendary
@export var rarity_weights := {
	"Common": 60.0,
	"Rare": 30.0,      # maps from CardDef "Uncommon"
	"Epic": 9.0,       # maps from CardDef "Rare"
	"Legendary": 1.0,
}

@export var rarity_colors := {
	"Common": Color8( 90, 160,  90),
	"Rare":   Color8( 90, 140, 200),   # was "Uncommon" in CardDef
	"Epic":   Color8(180,  80, 200),   # was "Rare" in CardDef
	"Legendary": Color8(230, 170,  40),
}

# Map CardDef.rarity -> display bucket names used in your legend
const DEF_TO_DISPLAY_RARITY := {
	"Common": "Common",
	"Uncommon": "Rare",      # show as Rare
	"Rare": "Epic",          # show as Epic
	"Legendary": "Legendary",
	"Epic": "Epic",          # in case you later switch CardDef to have "Epic"
}

# ===== NEW: Legend label + color-rect refs (your exact paths) =====
@onready var lbl_common: Label = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Common/HBoxContainer/Common"
@onready var lbl_rare: Label = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Rare/HBoxContainer/Rare"
@onready var lbl_epic: Label = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Epic/HBoxContainer/Epic"
@onready var lbl_legendary: Label = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Legendary/HBoxContainer/Legendary"

@onready var col_common: ColorRect = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Common/HBoxContainer/ColorRect"
@onready var col_rare: ColorRect = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Rare/HBoxContainer/ColorRect"
@onready var col_epic: ColorRect = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Epic/HBoxContainer/ColorRect"
@onready var col_legendary: ColorRect = $"../../MarginContainer/InfoRow/MarginContainer/RarityLegend/Legendary/HBoxContainer/ColorRect"

var _rarity_counts: Dictionary = {}
var _per_card_weight_by_rarity: Dictionary = {}
var _available_weight_sum: float = 0.0

var _spinning: bool = false
var _last_preview: Node2D = null

func _recalc_rarity_cache() -> void:
	# Count cards in pool per DISPLAY rarity
	_rarity_counts = {"Common":0, "Rare":0, "Epic":0, "Legendary":0}
	for def: CardDef in card_pool:
		var dr := _display_rarity_of(def)
		if not _rarity_counts.has(dr):
			_rarity_counts[dr] = 0
		_rarity_counts[dr] = int(_rarity_counts[dr]) + 1

	# Build per-card weight so that sum over cards of a rarity == rarity_weights[rarity]
	_per_card_weight_by_rarity = {}
	_available_weight_sum = 0.0

	for r in ["Common","Rare","Epic","Legendary"]:
		var r_weight := float(rarity_weights.get(r, 0.0))
		var r_count  := int(_rarity_counts.get(r, 0))
		if r_weight > 0.0 and r_count > 0:
			_per_card_weight_by_rarity[r] = r_weight / float(r_count) # <<< split evenly
			_available_weight_sum += r_weight                          # sum weights of available rarities
		else:
			_per_card_weight_by_rarity[r] = 0.0


func _ready() -> void:
	randomize()
	row.add_theme_constant_override("separation", tile_gap)

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	assert(player != null)

	loadout = player.loadout
	assert(loadout != null and loadout.cards != null and loadout.items != null)

	if btn != null and not btn.is_connected("pressed", Callable(self, "open_one")):
		btn.pressed.connect(open_one)
	if btn10 != null and not btn10.is_connected("pressed", Callable(self, "open_ten")):
		btn10.pressed.connect(open_ten)

	if not loadout.items.is_connected("update", Callable(self, "_refresh_afford")):
		loadout.items.update.connect(_refresh_afford)
	_refresh_afford()
	_recalc_rarity_cache()
	# ===== NEW: initialize legend once UI is ready =====
	_update_rarity_legend()

# ----------------------------------------------------------------
# Public API
# ----------------------------------------------------------------
func open_one() -> void: open_n(1)
func open_ten() -> void: open_n(10)

func open_n(n: int) -> void:
	if n <= 0 or _spinning or card_pool.is_empty():
		return
	if loadout == null or loadout.items == null or loadout.cards == null:
		return

	var total_cost: int = cost_amount * n
	if total_cost > 0:
		if not _can_afford_total(n): return
		if not _pay_total(n): return

	_recalc_rarity_cache()
	_update_rarity_legend()

	_spinning = true
	btn.disabled = true
	await _run_draw_sequence(n)
	_spinning = false
	_refresh_afford()

# ----------------------------------------------------------------
# Draw sequence
# ----------------------------------------------------------------
func _run_draw_sequence(n: int) -> void:
	for i: int in range(n):
		var def: CardDef = _pick_weighted_local(card_pool)   # <<< NEW: instance-weighted
		if def == null:
			continue

		await _spin_to(def)

		var item: InvItem = InvItem.new()
		item.id = String(def.id)
		item.texture = def.icon
		item.stack_size = def.stack_size
		item.card_def = def

		loadout.cards.insert(item, 1)
		opened.emit(def, item)

		if preview_in_reel_end and base_card_scene != null:
			await _show_preview(def)

# ----------------------------------------------------------------
# Reel spin (unchanged math, calls _pick_weighted_local for filler)
# ----------------------------------------------------------------
func _spin_to(target_def: CardDef) -> void:
	for c: Node in row.get_children():
		c.queue_free()
	await get_tree().process_frame

	var visible_w: float = reel.size.x
	var tile_w: float = float(tile_size.x + tile_gap)
	var center_offset: float = max((visible_w - float(tile_size.x)) * 0.5, 0.0)
	var pad_tiles: int = int(ceil(center_offset / tile_w)) + 1

	for i in range(pad_tiles):
		row.add_child(_make_tile(_pick_weighted_local(card_pool)))
	for i in range(tiles_to_spin - 1):
		row.add_child(_make_tile(_pick_weighted_local(card_pool)))
	row.add_child(_make_tile(target_def))
	for i in range(pad_tiles):
		row.add_child(_make_tile(_pick_weighted_local(card_pool)))

	await get_tree().process_frame

	reel.scroll_horizontal = 0
	var target_index: int = pad_tiles + (tiles_to_spin - 1)
	var target_x: float = target_index * tile_w
	var target_scroll: float = max(target_x - center_offset, 0.0)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(reel, "scroll_horizontal", int(target_scroll), spin_duration)
	await tw.finished

# ----------------------------------------------------------------
# Preview (unchanged)
# ----------------------------------------------------------------
func _show_preview(def: CardDef) -> void:
	if clear_previous_preview and _last_preview != null and is_instance_valid(_last_preview):
		_last_preview.queue_free()
		_last_preview = null

	var node: Node = base_card_scene.instantiate()
	var as_2d: Node2D = node as Node2D

	var parent: Node = preview_spawn if preview_spawn != null else self
	parent.add_child(node)

	if as_2d != null and preview_spawn != null:
		as_2d.position = Vector2.ZERO

	if node.has_method("set_card_values"):
		node.call("set_card_values", def.level, def.atk, def.hp, def.name, def.description)

	node.visible = true
	_last_preview = as_2d

	await get_tree().create_timer(preview_seconds).timeout
	if is_instance_valid(node): node.queue_free()
	_last_preview = null

# ----------------------------------------------------------------
# Tile rendering (OPTIONAL: use lootbox colors instead of def.get_color)
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
	sb.border_color = _color_for(def)  # <<< NEW
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
# Costs (unchanged)
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

# ===== NEW: Weighted pick that uses lootbox weights =====
func _display_rarity_of(def: CardDef) -> String:
	var r := String(def.rarity)
	return String(DEF_TO_DISPLAY_RARITY.get(r, r))

func _effective_weight(def: CardDef) -> float:
	var dr := _display_rarity_of(def)
	return float(_per_card_weight_by_rarity.get(dr, 0.0))

func _pick_weighted_local(pool: Array[CardDef]) -> CardDef:
	var total := 0.0
	for def: CardDef in pool:
		total += max(_effective_weight(def), 0.0)
	if total <= 0.0:
		return null
	var r := randf() * total
	for def: CardDef in pool:
		r -= max(_effective_weight(def), 0.0)
		if r <= 0.0:
			return def
	return pool.back()

# ===== NEW: Legend computation & UI update =====
func _update_rarity_legend() -> void:
	# Make sure caches reflect current pool
	_recalc_rarity_cache()

	var sum_available := _available_weight_sum  # sum of weights of rarities that actually exist

	_set_legend(lbl_common,    col_common,    "Common",    sum_available)
	_set_legend(lbl_rare,      col_rare,      "Rare",      sum_available)      # CardDef "Uncommon"
	_set_legend(lbl_epic,      col_epic,      "Epic",      sum_available)      # CardDef "Rare"
	_set_legend(lbl_legendary, col_legendary, "Legendary", sum_available)

func _set_legend(lbl: Label, rect: ColorRect, rarity_name: String, sum_available: float) -> void:
	var r_weight := float(rarity_weights.get(rarity_name, 0.0))
	var r_count  := int(_rarity_counts.get(rarity_name, 0))

	var share := 0.0
	if r_count > 0 and sum_available > 0.0 and r_weight > 0.0:
		share = r_weight / sum_available  # fixed per-rarity chance

	var pct := share * 100.0

	if lbl:
		lbl.text = "%s %s" % [_fmt_pct(pct), rarity_name]  # e.g. "50% Common"
	if rect:
		var col_var: Variant = rarity_colors.get(rarity_name, rect.color)
		if col_var is Color:
			rect.color = col_var



func _fmt_pct(p: float) -> String:
	var v: int = round(p * 10.0) / 10.0   # one decimal
	return ("%d%%" % int(v)) if int(v) == v else ("%s%%" % str(v))

# ===== NEW: Color helper for tiles (lootbox colors, with fallback) =====
func _color_for(def: CardDef) -> Color:
	var dr := _display_rarity_of(def)
	var col: Variant = rarity_colors.get(dr, null)
	if col is Color:
		return col
	return def.get_color()
