extends Panel
class_name EquipSlot

@export_enum("BATTLE", "SUPPORT") var slot_type: String = "BATTLE"
@export var index: int = 0  # 0..3

var item: InvItem = null

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var quantity: Label     = $CenterContainer/Panel/Label

func _ready() -> void:
	update_view()

func set_item(new_item: InvItem) -> void:
	item = new_item
	update_view()

func clear_item() -> void:
	item = null
	update_view()

func update_view() -> void:
	if item == null:
		item_visual.visible = false
		item_visual.texture = null
		quantity.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = item.texture
		# Equip ghosts never display a number
		quantity.visible = false
