# features/cards/scripts/card_view.gd
extends Node2D
class_name BaseCard

@export var card_def: CardDef   # set in Inspector or at runtime

@onready var level_label: Label        = $CardStats/CardLevel/Label
@onready var atk_label: Label          = $CardStats/CardAtk/Label
@onready var hp_label: Label           = $CardStats/CardHP/Label
@onready var name_label: Label         = $CardDetails/CardNameLabel
@onready var description_label: Label  = $CardDetails/CardDescriptionLabel
@onready var image_sprite: Sprite2D    = $CardDetails/ImageSprite2D   # adjust path if different

func _ready() -> void:
	if card_def != null:
		_apply_def(card_def)

func show_def(def: CardDef) -> void:
	card_def = def
	_apply_def(card_def)

func show_item(item: InvItem) -> void:
	if item != null and item.card_def != null:
		show_def(item.card_def)

func _apply_def(def: CardDef) -> void:
	level_label.text = str(def.level)
	atk_label.text   = str(def.atk)
	hp_label.text    = str(def.hp)
	name_label.text  = def.name
	description_label.text = def.description
	if image_sprite != null and def.icon != null:
		image_sprite.texture = def.icon
