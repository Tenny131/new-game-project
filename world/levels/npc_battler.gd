extends Node2D
class_name NpcBattler

@export var team: BattleTeam                         # assign your BattleTeam.tres
@export_node_path("Control") var battle_ui_path: NodePath  # your BattleUI node in the level/overlay

var _player: Player = null
var _battle_ui: Node = null
var _player_in_range: bool = false
	
func _ready() -> void:
	# Resolve player by group (or export the Player if you prefer)
	_player = get_tree().get_first_node_in_group("player") as Player
	assert(_player != null, "NpcBattler: put your Player in the 'player' group or assign manually.")

	_battle_ui = get_node_or_null(battle_ui_path)
	assert(_battle_ui != null, "NpcBattler: battle_ui_path not set.")

	var area: Area2D = $Area2D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	if _battle_ui and not _battle_ui.is_connected("battle_finished", Callable(self, "_on_battle_finished")):
		_battle_ui.connect("battle_finished", _on_battle_finished)

func _on_body_entered(body: Node) -> void:
	if body == _player:
		_player_in_range = true
		print("player in range")
func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_start_battle()
		get_viewport().set_input_as_handled()

func _start_battle() -> void:
	if team == null:
		push_error("NpcBattler: team not set.")
		return
	var ui: Node = _battle_ui
	if ui != null and ui.has_method("open_battle"):
		ui.call("open_battle", _player.loadout, team)  # opens UI, does NOT start
	else:
		push_error("NpcBattler: Battle UI missing open_battle(loadout, team).")



func _on_battle_finished(won: bool, rewards: Array) -> void:
	# rewards is Array[InvItem]
	if won and _player and _player.loadout and _player.loadout.items:
		for it in rewards:
			if it is InvItem:
				_player.loadout.items.insert(it, 10)  # insert one of each drop
