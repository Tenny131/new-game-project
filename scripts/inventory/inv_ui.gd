extends Control

@onready var inv: Inv = preload("res://inventory/player_inventory.tres")
@onready var inventory_grid: GridContainer = $NinePatchRect/ContentRow/InvPanel/InvGrid
@onready var equip_grid: GridContainer     = $NinePatchRect/ContentRow/EquipPanel/EquipGrid

@export var loadout: PlayerLoadout

var is_open: bool = false
var holding_item: InvItem = null
var holding_amount: int = 0
var holding_visual: TextureRect = null

# Track where we picked the item up from (so we can restore when equipping)
var holding_origin: String = ""         # "INVENTORY" | "" (more later if needed)
var holding_origin_index: int = -1

func _ready() -> void:
	# Connect inventory slot inputs
	for child in inventory_grid.get_children():
		if child.has_signal("gui_input"):
			child.gui_input.connect(_on_inventory_slot_input.bind(child))

	# Connect equip slot inputs
	for child in equip_grid.get_children():
		if child is EquipSlot:
			child.gui_input.connect(_on_equip_slot_input.bind(child))

	inv.update.connect(_update_inventory)
	_update_inventory()
	_update_equip()
	close_inv()  # start hidden

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("inventory"):
		if is_open: close_inv() 
		else: 
			open_inv()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if holding_visual:
		holding_visual.global_position = get_global_mouse_position()

# ------------------------
# Inventory grid handling
# ------------------------
func _on_inventory_slot_input(event: InputEvent, slot_ui: Node) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var idx: int = slot_ui.get_index()  # assumes 1:1 order with inv.slots
		if idx < 0 or idx >= inv.slots.size():
			return
		var slot_data: InvSlot = inv.slots[idx]

		if holding_item != null:
			# place into empty slot
			if slot_data.item == null:
				slot_data.item = holding_item
				slot_data.amount = max(1, holding_amount)
				_clear_holding()
				inv.update.emit()
			# same item -> stack (respect stack_size)
			elif slot_data.item.id == holding_item.id:
				var max_stack: int = slot_data.item.stack_size
				var can_add: int = max_stack - slot_data.amount
				if can_add >= holding_amount:
					slot_data.amount += holding_amount
					_clear_holding()
				else:
					slot_data.amount += can_add
					holding_amount -= can_add
				inv.update.emit()
			# different -> swap
			else:
				var temp_item: InvItem = slot_data.item
				var temp_amount: int = slot_data.amount
				slot_data.item = holding_item
				slot_data.amount = holding_amount
				holding_item = temp_item
				holding_amount = temp_amount
				inv.update.emit()
				_refresh_holding_visual()
		else:
			# pick up from inventory (REMOVES from the inventory slot)
			if slot_data.item != null:
				holding_item = slot_data.item
				holding_amount = slot_data.amount
				holding_origin = "INVENTORY"
				holding_origin_index = idx

				slot_data.item = null
				slot_data.amount = 0
				inv.update.emit()
				_create_holding_visual(holding_item)

# ------------------------
# Equip grid handling (GHOST COPY)
# ------------------------
func _on_equip_slot_input(event: InputEvent, equip_slot: EquipSlot) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event

		# --- RIGHT CLICK = CLEAR EQUIP SLOT (no inventory changes) ---
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if equip_slot.item != null:
				equip_slot.clear_item()
				_update_loadout_for_slot(equip_slot.slot_type, equip_slot.index, null)
				equip_slot.update_view()
			get_viewport().set_input_as_handled()
			return

		# --- LEFT CLICK = EQUIP A GHOST COPY (existing behavior) ---
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# forbid picking up from equip; only place/replace when holding
			if holding_item == null:
				return

			# create ghost copy for slot
			var ghost: InvItem = holding_item.duplicate(true) as InvItem
			equip_slot.item = ghost
			_update_loadout_for_slot(equip_slot.slot_type, equip_slot.index, ghost)
			equip_slot.update_view()

			# restore the original back to inventory and clear the hand
			_restore_holding_to_inventory()
			_clear_holding()


# ------------------------
# Loadout & UI updates
# ------------------------
func _update_loadout_for_slot(slot_type: String, index: int, item: InvItem) -> void:
	if loadout == null:
		return
	loadout.set_slot(slot_type, index, item)

func _update_equip() -> void:
	if loadout == null:
		return
	var panels: Array[Node] = equip_grid.get_children()
	for p in panels:
		if p is EquipSlot:
			var eq: EquipSlot = p
			eq.item = loadout.get_slot(eq.slot_type, eq.index)
			eq.update_view()

func _update_inventory() -> void:
	for i in range(min(inv.slots.size(), inventory_grid.get_child_count())):
		var slot_node: Node = inventory_grid.get_child(i)
		if slot_node.has_method("update"):
			slot_node.update(inv.slots[i])

# ------------------------
# Holding visual helpers
# ------------------------
func _create_holding_visual(item: InvItem) -> void:
	if holding_visual:
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
	holding_origin = ""
	holding_origin_index = -1
	if holding_visual:
		holding_visual.queue_free()
		holding_visual = null

# ------------------------
# Restore item back to inventory after equipping a ghost
# ------------------------
func _restore_holding_to_inventory() -> void:
	if holding_item == null:
		return

	# Try to put back to the original slot if it is still empty.
	if holding_origin == "INVENTORY" and holding_origin_index >= 0 and holding_origin_index < inv.slots.size():
		var origin: InvSlot = inv.slots[holding_origin_index]
		if origin.item == null:
			origin.item = holding_item
			origin.amount = max(1, holding_amount)
			inv.update.emit()
			return

	# Fallback: find first empty slot.
	for i in range(inv.slots.size()):
		var s: InvSlot = inv.slots[i]
		if s.item == null:
			s.item = holding_item
			s.amount = max(1, holding_amount)
			inv.update.emit()
			return

	# Optional: try to stack if no empties (respect stack size)
	for i in range(inv.slots.size()):
		var s2: InvSlot = inv.slots[i]
		if s2.item != null and s2.item.id == holding_item.id:
			var max_stack: int = s2.item.stack_size
			var free: int = max_stack - s2.amount
			if free > 0:
				var put: int = min(free, max(1, holding_amount))
				s2.amount += put
				inv.update.emit()
				return
	# If inventory full and no stack room → you can add a popup warning here.

# ------------------------
# Open/Close
# ------------------------
func open_inv() -> void:
	visible = true
	is_open = true
	if holding_visual:
		holding_visual.visible = true

func close_inv() -> void:
	visible = false
	is_open = false
	if holding_visual:
		holding_visual.visible = false
