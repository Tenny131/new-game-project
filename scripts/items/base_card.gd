class_name BaseCard
extends Node2D

@export var card_level: int = 1
@export var card_atk: int = 4
@export var card_hp: int = 10
@export var card_image: Node2D

@export var card_name: String = "Card Name"
@export var card_description: String = "CardDescription"

# PRELOAD
@onready var level_label: Label = $CardStats/CardLevel/Label
@onready var atk_label: Label = $CardStats/CardAtk/Label
@onready var hp_label: Label = $CardStats/CardHP/Label

@onready var name_label: Label = $CardDetails/CardNameLabel
@onready var description_label: Label = $CardDetails/CardDescriptionLabel

func _ready() -> void:
	set_card_values(card_level, card_atk, card_hp, card_name, card_description)
	#visible = false
	
func set_card_values(_level: int, _atk: int, _hp: int, _name: String, _description: String)-> void:
	level_label.set_text(str(_level))
	atk_label.set_text(str(_atk))
	hp_label.set_text(str(_hp))
	
	name_label.set_text(_name)
	description_label.set_text(_description)
	
func _process(_delta: float) -> void:
	pass
