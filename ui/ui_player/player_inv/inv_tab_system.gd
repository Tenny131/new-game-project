extends Control
class_name InvTabSystem

# Data
@export var loadout: PlayerLoadout

# Assign these in the Inspector to your actual grids
@export_node_path("GridContainer") var cards_grid_path: NodePath
@export_node_path("GridContainer") var items_grid_path: NodePath
@export_node_path("GridContainer") var equip_grid_path: NodePath   # NEW

# Holding state
var holding_item: InvItem = null
var holding_amount: int = 0
var holding_visual: TextureRect = null

# Resolved grids
var cards_grid: GridContainer = null
var items_grid: GridContainer = null
var equip_grid: GridContainer = null

func _ready() -> void:
	assert(loadout != null, "InvTabSystem: loadout must be assigned (PlayerLoadout.tres).")

	# Make sure this UI does NOT steal keyboard focus globally
	focus_mode = Control.FOCUS_NONE

	# Start CLOSED
	close_inv()  # sets visible=false and ignores mouse when closed

	# Resolve grids
	if cards_grid_path != NodePath(""):
		var n1: Node = get_node_or_null(cards_grid_path)
		cards_grid = n1 as GridContainer
	if items_grid_path != NodePath(""):
		var n2: Node = get_node_or_null(items_grid_path)
		items_grid = n2 as GridContainer
	if equip_grid_path != NodePath(""):
		var n3: Node = get_node_or_null(equip_grid_path)
		equip_grid = n3 as GridContainer

	assert(cards_grid != null, "InvTabSystem: cards_grid_path not set or invalid.")
	assert(items_grid != null, "InvTabSystem: items_grid_path not set or invalid.")
	assert(equip_grid != null, "InvTabSystem: equip_grid_path not set or invalid.")

	# Connect slot signals via wrappers (handlers take exactly 2 args)
	_connect_tab_slots(cards_grid, true)
	_connect_tab_slots(items_grid, false)

	# Connect equip slots: left-click equip (cards only, ghost), right-click clear
	_connect_equip_slots()

	# Listen for inventory changes
	if loadout.cards != null and not loadout.cards.is_connected("update", Callable(self, "_refresh_cards")):
		loadout.cards.update.connect(_refresh_cards)
	if loadout.items != null and not loadout.items.is_connected("update", Callable(self, "_refresh_items")):
		loadout.items.update.connect(_refresh_items)

	# Initial draw
	_refresh_cards()
	_refresh_items()
	_update_equip()

func _unhandled_input(e: InputEvent) -> void:
	# IMPORTANT: make sure ONLY ONE script in your scene toggles the inventory.
	if e.is_action_pressed("inventory"):
		toggle_inv()
		get_viewport().set_input_as_handled()

func _process(_dt: float) -> void:
	if holding_visual != null:
		holding_visual.global_position = get_global_mouse_position()

# ---------------------------
# Open / Close / Toggle
# ---------------------------
func open_inv() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if holding_visual != null:
		holding_visual.visible = true

func close_inv() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if holding_visual != null:
		holding_visual.visible = false

func toggle_inv() -> void:
	if visible:
		close_inv()
	else:
		open_inv()

# ---------------------------
# Connections / Refresh
# ---------------------------
func _connect_tab_slots(grid: GridContainer, is_cards_tab: bool) -> void:
	var i: int = 0
	while i < grid.get_child_count():
		var node: Node = grid.get_child(i)
		if node is InvUiSlot:
			var ui: InvUiSlot = node as InvUiSlot
			if is_cards_tab:
				if not ui.is_connected("slot_clicked", Callable(self, "_cards_wrapper")):
					ui.slot_clicked.connect(_cards_wrapper)
			else:
				if not ui.is_connected("slot_clicked", Callable(self, "_items_wrapper")):
					ui.slot_clicked.connect(_items_wrapper)
		i += 1

func _cards_wrapper(slot_ui: InvUiSlot, event: InputEvent) -> void:
	_on_cards_slot_clicked(slot_ui, event)

func _items_wrapper(slot_ui: InvUiSlot, event: InputEvent) -> void:
	_on_items_slot_clicked(slot_ui, event)

func _connect_equip_slots() -> void:
	var i: int = 0
	while i < equip_grid.get_child_count():
		var node: Node = equip_grid.get_child(i)
		if node is EquipSlot:
			var es: EquipSlot = node as EquipSlot
			if not es.is_connected("gui_input", Callable(self, "_on_equip_slot_input")):
				es.gui_input.connect(_on_equip_slot_input.bind(es))
		i += 1

func _refresh_cards() -> void:
	_populate_grid_from_inv(cards_grid, loadout.cards)

func _refresh_items() -> void:
	_populate_grid_from_inv(items_grid, loadout.items)

func _populate_grid_from_inv(grid: GridContainer, inv_ref: Inv) -> void:
	var child_count: int = grid.get_child_count()
	var inv_size: int = 0
	if inv_ref != null:
		inv_size = inv_ref.slots.size()

	var i: int = 0
	while i < child_count:
		var node: Node = grid.get_child(i)
		if node is InvUiSlot:
			var ui: InvUiSlot = node as InvUiSlot
			if inv_ref != null and i < inv_size:
				ui.source_index = i
				ui.update(inv_ref.slots[i])
			else:
				ui.source_index = -1
				ui.update(null)
		i += 1

func _update_equip() -> void:
	var i: int = 0
	while i < equip_grid.get_child_count():
		var node: Node = equip_grid.get_child(i)
		if node is EquipSlot:
			var es: EquipSlot = node as EquipSlot
			es.item = loadout.get_slot(es.slot_type, es.index)
			es.update_view()
		i += 1

# ---------------------------
# Tab Handlers (2 args only)
# ---------------------------
func _on_cards_slot_clicked(slot_ui: InvUiSlot, event: InputEvent) -> void:
	_handle_tab_click(slot_ui, event, loadout.cards, true)

func _on_items_slot_clicked(slot_ui: InvUiSlot, event: InputEvent) -> void:
	_handle_tab_click(slot_ui, event, loadout.items, false)

# Core click logic shared by both tabs
func _handle_tab_click(slot_ui: InvUiSlot, event: InputEvent, inv_ref: Inv, wants_cards: bool) -> void:
	if not (event is InputEventMouseButton):
		return
	var mbe: InputEventMouseButton = event as InputEventMouseButton
	if mbe.button_index != MOUSE_BUTTON_LEFT or not mbe.pressed:
		return

	if inv_ref == null:
		return

	var src: int = slot_ui.source_index
	var slot_data: InvSlot = null
	if src >= 0 and src < inv_ref.slots.size():
		slot_data = inv_ref.slots[src]

	# Placing
	if holding_item != null:
		var is_card: bool = (holding_item.card_def != null)
		if wants_cards != is_card:
			_reject_feedback(slot_ui)
			return

		# Empty
		if slot_data == null or slot_data.item == null:
			if slot_data == null:
				var empty_index: int = _find_empty_index(inv_ref)
				if empty_index == -1:
					_reject_feedback(slot_ui)
					return
				inv_ref.slots[empty_index].item = holding_item
				inv_ref.slots[empty_index].amount = max(1, holding_amount)
			else:
				slot_data.item = holding_item
				slot_data.amount = max(1, holding_amount)
			_clear_holding()
			inv_ref.update.emit()
			return

		# Stack
		if slot_data.item.id == holding_item.id:
			var max_stack: int = slot_data.item.stack_size
			var can_add: int = max_stack - slot_data.amount
			if can_add >= holding_amount:
				slot_data.amount += holding_amount
				_clear_holding()
			else:
				slot_data.amount += can_add
				holding_amount -= can_add
				_refresh_holding_visual()
			inv_ref.update.emit()
			return

		# Swap
		var temp_item: InvItem = slot_data.item
		var temp_amount: int = slot_data.amount
		slot_data.item = holding_item
		slot_data.amount = holding_amount
		holding_item = temp_item
		holding_amount = temp_amount
		inv_ref.update.emit()
		_refresh_holding_visual()
		return

	# Pick up
	if slot_data != null and slot_data.item != null:
		holding_item = slot_data.item
		holding_amount = slot_data.amount
		slot_data.item = null
		slot_data.amount = 0
		inv_ref.update.emit()
		_create_holding_visual(holding_item)

# ---------------------------
# Equip handling (cards only)
# ---------------------------
func _on_equip_slot_input(event: InputEvent, equip_slot: EquipSlot) -> void:
	if not (event is InputEventMouseButton):
		return
	var mbe: InputEventMouseButton = event as InputEventMouseButton

	# Right-click clears the slot
	if mbe.button_index == MOUSE_BUTTON_RIGHT and mbe.pressed:
		if equip_slot.item != null:
			equip_slot.item = null
			loadout.set_slot(equip_slot.slot_type, equip_slot.index, null)
			equip_slot.update_view()
		return

	# Left-click: equip only if holding a CARD
	if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed:
		if holding_item == null:
			return
		if holding_item.card_def == null:
			_reject_feedback(equip_slot)
			return

		# Create a ghost copy — do NOT consume from inventory
		var ghost: InvItem = InvItem.new()
		ghost.id = holding_item.id
		ghost.texture = holding_item.texture
		ghost.stack_size = 1
		ghost.card_def = holding_item.card_def

		equip_slot.item = ghost
		loadout.set_slot(equip_slot.slot_type, equip_slot.index, ghost)
		equip_slot.update_view()

		# Keep holding the original; user can place it back into Cards tab or ignore

# ---------------------------
# Helpers
# ---------------------------
func _find_empty_index(inv_ref: Inv) -> int:
	if inv_ref == null:
		return -1
	var i: int = 0
	while i < inv_ref.slots.size():
		var s: InvSlot = inv_ref.slots[i]
		if s.item == null or s.amount <= 0:
			return i
		i += 1
	return -1

func _create_holding_visual(item: InvItem) -> void:
	if holding_visual != null:
		holding_visual.queue_free()
	holding_visual = TextureRect.new()
	holding_visual.texture = item.texture
	holding_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holding_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holding_visual)

func _refresh_holding_visual() -> void:
	if holding_item == null:
		_clear_holding()
		return
	if holding_visual == null:
		_create_holding_visual(holding_item)
	else:
		holding_visual.texture = holding_item.texture

func _clear_holding() -> void:
	holding_item = null
	holding_amount = 0
	if holding_visual != null:
		holding_visual.queue_free()
		holding_visual = null

func _reject_feedback(node: Node) -> void:
	var c: Control = node as Control
	if c == null:
		return
	var tw: Tween = create_tween()
	var x: float = c.position.x
	tw.tween_property(c, "position:x", x - 3.0, 0.05)
	tw.tween_property(c, "position:x", x + 3.0, 0.05)
	tw.tween_property(c, "position:x", x, 0.05)
