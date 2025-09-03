extends Control

@onready var grid: GridContainer = $NinePatchRect/GridContainer
@onready var player_inventory: Inv = preload("res://inventory/player_inventory.tres")

var holding_slot: InvSlot = null
var holding_visual: TextureRect = null

func _ready():
	player_inventory.update.connect(update_ui)
	for inv_slot in grid.get_children():
		inv_slot.slot_clicked.connect(slot_gui_input)
	update_ui()
	visible = false

func _process(_delta):
	if Input.is_action_just_pressed("inventory"):
		visible = !visible
		if !visible:
			_clear_holding()

	if holding_visual and holding_visual.texture:
		var sz: Vector2 = holding_visual.texture.get_size()
		holding_visual.global_position = get_global_mouse_position() - sz / 2.0

func update_ui():
	for i in range(min(player_inventory.slots.size(), grid.get_child_count())):
		grid.get_child(i).update(player_inventory.slots[i])

func slot_gui_input(slot_ui, event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var slot_data: InvSlot = slot_ui.current_slot

		if holding_slot:
			# Empty → place
			if !slot_data.item:
				slot_data.item = holding_slot.item
				slot_data.amount = holding_slot.amount
				_clear_holding()
				player_inventory.update.emit()
				return

			# Same item (by id) → stack
			if slot_data.item.id == holding_slot.item.id:
				var max_stack: int = int(slot_data.item.stack_size)
				var can_add: int = max_stack - slot_data.amount
				if can_add >= holding_slot.amount:
					slot_data.amount += holding_slot.amount
					_clear_holding()
				else:
					slot_data.amount += can_add
					holding_slot.amount -= can_add
				player_inventory.update.emit()
				return

			# Different → swap
			var temp_item        = slot_data.item
			var temp_amount: int = slot_data.amount
			slot_data.item   = holding_slot.item
			slot_data.amount = holding_slot.amount
			holding_slot.item   = temp_item
			holding_slot.amount = temp_amount
			if holding_visual:
				holding_visual.texture = holding_slot.item.texture
			player_inventory.update.emit()
			return

		# Pick up
		if slot_data.item:
			holding_slot = InvSlot.new()
			holding_slot.item = slot_data.item
			holding_slot.amount = slot_data.amount

			slot_data.item = null
			slot_data.amount = 0

			holding_visual = TextureRect.new()
			holding_visual.texture = holding_slot.item.texture
			holding_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			holding_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holding_visual.z_index = 1000
			add_child(holding_visual)

			player_inventory.update.emit()

func _clear_holding():
	holding_slot = null
	if holding_visual:
		holding_visual.queue_free()
		holding_visual = null
