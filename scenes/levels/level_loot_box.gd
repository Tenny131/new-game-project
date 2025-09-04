# LevelLootBox.gd (on your Level root)
extends Node2D

@onready var loot_ui: Control = $LootBoxOverlay

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_lootbox"):  # bind to L in Input Map
		loot_ui.open_basic_lootbox()
