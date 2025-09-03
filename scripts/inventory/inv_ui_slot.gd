extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var quantity: Label = $CenterContainer/Panel/Label

var current_slot: InvSlot
signal slot_clicked(slot_ui, event)

func update(slot: InvSlot):
	current_slot = slot
	if !slot.item:
		item_visual.visible = false
		quantity.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		if slot.amount > 1:
			quantity.visible = true
			quantity.text = str(slot.amount)
		else:
			quantity.visible = false

func _gui_input(event: InputEvent):
	emit_signal("slot_clicked", self, event)
