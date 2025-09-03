extends Resource
class_name CardDef

@export var name: String
@export var description: String
@export var level: int = 1
@export var atk: int = 1
@export var hp: int = 1
@export var icon: Texture2D
@export var stack_size: int = 99

# Dropdown in the Inspector; value is a String limited to these options.
@export_enum("Common", "Uncommon", "Rare", "Legendary")
var rarity: String = "Common"

# Auto-weight table
const RARITY_WEIGHT := {
	"Common": 60.0,
	"Uncommon": 30.0,
	"Rare": 9.0,
	"Legendary": 1.0,
}

func get_weight() -> float:
	return RARITY_WEIGHT.get(rarity, 0.0)
