extends Panel
class_name EquipSlot

@export_enum("BATTLE", "SUPPORT") var slot_type: String = "BATTLE"
@export var index: int = 0  # 0..3

var item: InvItem = null

@onready var item_visual: Sprite2D = $CenterContainer/Panel/ItemDisplay
@onready var quantity: Label = $CenterContainer/Panel/Label
@onready var cc: Control = $CenterContainer
@onready var inner_panel: Control = $CenterContainer/Panel

func _ready() -> void:
	# Root must capture clicks
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Let children pass the click to the root
	if cc:          cc.mouse_filter = Control.MOUSE_FILTER_PASS
	if inner_panel: inner_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	# Equip ghosts never show stack numbers
	if quantity: quantity.visible = false
	update_view()

func set_item(new_item: InvItem) -> void:
	item = new_item
	update_view()

func clear_item() -> void:
	item = null
	update_view()

func update_view() -> void:
	if item == null:
		if item_visual:
			item_visual.visible = false
			item_visual.texture = null
		if quantity:
			quantity.visible = false
	else:
		if item_visual:
			item_visual.visible = true
			item_visual.texture = item.texture
		if quantity:
			quantity.visible = false
