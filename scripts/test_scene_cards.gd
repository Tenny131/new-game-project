extends Node2D

@onready var base_card_scene: PackedScene = preload("res://scenes/objects/cards/base_card.tscn")
@onready var spawn_point = $CanvasLayer/CardSpawnPoint
@export var item: InvItem

func _on_button_pressed() -> void:
	var generated_card: BaseCard = base_card_scene.instantiate()
	spawn_point.add_child(generated_card)
	generated_card.set_card_values(9, 9, 100, "GIGACHAD", "best card")
	generated_card.visible = true
