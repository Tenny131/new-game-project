extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay 
@onready var quantity: Label = $CenterContainer/Panel/Label

func update(slot: InvSlot):
	if !slot.item:
		item_visual.visible = false
		quantity.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		if slot.amount > 1:
			quantity.visible = true
		quantity.text = str(slot.amount)
