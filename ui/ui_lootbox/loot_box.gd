# LevelLootBox.gd (on your Level root)
extends Node2D


@export var inv: Inv
@export var loadout: PlayerLoadout
@onready var loot_ui: Control = $Player/CanvasLayer/LootBoxOverlay

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_lootbox"):  # bind to L in Input Map
		loot_ui.open_basic_lootbox()
	if event.is_action_pressed("save_game"):
		GameState.save_to_disk(inv, loadout)
	if event.is_action_pressed("load_game"):
		if not GameState.load_from_disk(inv, loadout):
			print("No save found")


	
