extends Node2D
class_name NpcLootbox


var _player: Player = null
@onready var loot_ui: Control = $"../CanvasLayer/LootBoxOverlay"
var _player_in_range: bool = false
	
func _ready() -> void:
	# Resolve player by group (or export the Player if you prefer)
	_player = get_tree().get_first_node_in_group("player") as Player

	var area: Area2D = $Area2D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
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
		loot_ui.open_basic_lootbox()
		get_viewport().set_input_as_handled()
