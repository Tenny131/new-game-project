# res://scripts/npc_battle_trigger.gd
extends Area2D
class_name NpcBattleTrigger

@export var enemy_cards: Array[CardDef] = []                # set per NPC
@onready var battle_ui: BattleUI = $CanvasLayer2/BattleUI

var _in_range := false

func _ready() -> void:
	body_entered.connect(func(b): if b.is_in_group("player"): _in_range = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _in_range = false)

func _unhandled_input(e: InputEvent) -> void:
	if not _in_range:
		return
	if e.is_action_pressed("interact"):
		_start_battle_ui()
		get_viewport().set_input_as_handled()

func _start_battle_ui() -> void:
	var ui := get_node_or_null(battle_ui_path) as BattleUI
	if ui == null:
		push_error("NpcBattleTrigger: BattleUI not found at %s" % [battle_ui_path])
		return

	# get player loadout from the first node in 'player' group
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("loadout") == null:
		push_error("NpcBattleTrigger: Player with 'loadout' not found.")
		return

	# feed UI
	ui.player_loadout = player.loadout
	ui.enemy_cards = enemy_cards

	# refresh and show (uses the minimal BattleUI you have)
	if ui.has_method("_refresh_teams"):
		ui.call("_refresh_teams")
	if ui.has_method("_load_current"):
		ui.call("_load_current")
	ui.visible = true
