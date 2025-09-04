# e.g. Main.gd on your main scene root (Node2D/Node/Control)
extends Node2D

@onready var loot_ui: Control = $LootBoxOverlay # adjust path

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open lootbox"):  # add this action in Project > Input Map
		loot_ui.open()
