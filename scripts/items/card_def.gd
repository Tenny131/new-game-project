extends Resource
class_name CardDef

@export var name: String
@export var description: String
@export var level: int = 1
@export var atk: int = 1
@export var hp: int = 1
@export var icon: Texture2D
@export var stack_size: int = 99

# Dropdown with allowed values only
@export_enum("Common", "Uncommon", "Rare", "Legendary")
var rarity: String = "Common"

# Auto-weights by rarity
const RARITY_WEIGHT := {
	"Common": 60.0,
	"Uncommon": 30.0,
	"Rare": 9.0,
	"Legendary": 1.0,
}

# Border colors by rarity
const RARITY_COLOR := {
	"Common": Color8( 90, 160,  90),   # greenish
	"Uncommon": Color8( 90, 140, 200), # blue
	"Rare": Color8(180,  80, 200),     # purple
	"Legendary": Color8(230, 170,  40) # gold
}

func get_weight() -> float:
	return RARITY_WEIGHT.get(rarity, 0.0)

func get_color() -> Color:
	return RARITY_COLOR.get(rarity, Color.WHITE)
