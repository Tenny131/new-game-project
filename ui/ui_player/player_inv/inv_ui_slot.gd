extends Panel
class_name InvUiSlot

signal slot_clicked(slot_ui: InvUiSlot, event: InputEvent)

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var quantity: Label = $CenterContainer/Panel/Label

var current_slot: InvSlot = null
var source_index: int = -1   # index into the backing Inv.slots (assigned by the tab system)

func update(slot: InvSlot) -> void:
	current_slot = slot

	if slot == null or slot.item == null or slot.amount <= 0:
		if item_visual != null:
			item_visual.visible = false
			item_visual.texture = null
		if quantity != null:
			quantity.visible = false
		return

	if item_visual != null:
		item_visual.visible = true
		item_visual.texture = slot.item.texture

	if quantity != null:
		if slot.amount > 1:
			quantity.visible = true
			quantity.text = str(slot.amount)
		else:
			quantity.visible = false

func _gui_input(event: InputEvent) -> void:
	slot_clicked.emit(self, event)
