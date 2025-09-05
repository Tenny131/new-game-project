class_name Player
extends CharacterBody2D

@onready var hit_component: HitComponent = $"Hit Component"

@export var loadout: PlayerLoadout        # << use loadout, not a single Inv
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

var player_direction: Vector2

func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)

func on_tool_selected(tool: DataTypes.Tools) -> void:
	current_tool = tool
	hit_component.current_tool = tool
	print("Tool:", tool)

# Called by CollectableComponent / drops, etc.
func collect(item: InvItem, amount: int = 1) -> void:
	if loadout == null or item == null:
		return

	# Cards go to the Cards inventory, everything else to Items
	var dest: Inv = null
	if item.card_def != null:
		dest = loadout.cards
	else:
		dest = loadout.items

	if dest != null:
		dest.insert(item, amount)
