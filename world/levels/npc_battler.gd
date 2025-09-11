# res://scripts/npc_battle_starter.gd
extends Node
class_name NpcBattler

@onready var battle_ui: BattleUI = $"../CanvasLayer2/BattleUI"
var _can_interact: bool = false

# Called by InteractableComponent signal
func _on_interactable_component_interactable_activated() -> void:
	_can_interact = true

# Called by InteractableComponent signal
func _on_interactable_component_interactable_deactivated() -> void:
	_can_interact = false

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact"):
		_open_battle_ui()

func _open_battle_ui() -> void:
	battle_ui.visible = true
