extends Node2D
class_name BaseCard

@export var card_level: int = 1
@export var card_atk: int = 4
@export var card_hp: int = 10
@export var card_name: String = "Card Name"
@export var card_description: String = "CardDescription"

@onready var level_label: Label = $CardStats/CardLevel/Label
@onready var atk_label: Label   = $CardStats/CardAtk/Label
@onready var hp_label: Label    = $CardStats/CardHP/Label
@onready var name_label: Label  = $CardDetails/CardNameLabel
@onready var description_label: Label = $CardDetails/CardDescriptionLabel

func set_card_values(_level:int, _atk:int, _hp:int, _name:String, _desc:String) -> void:
	level_label.text = str(_level)
	atk_label.text   = str(_atk)
	hp_label.text    = str(_hp)
	name_label.text  = _name
	description_label.text = _desc
