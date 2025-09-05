extends Resource
class_name CardDef

# Stable internal key used in saves and lookups (lowercase, snake_case, no spaces)
@export var id: StringName = &""

# Display fields
@export var name: String = ""
@export var description: String = ""

# Stats
@export var level: int = 1
@export var atk: int = 1
@export var hp: int = 1

# Visuals
@export var icon: Texture2D

# Inventory behavior
@export var stack_size: int = 1

# Effects
@export var effects: Array[CardEffect] = []

# Rarity dropdown
@export_enum("Common", "Uncommon", "Rare", "Legendary")
var rarity: String = "Common"

# Auto-weights by rarity
const RARITY_WEIGHT: Dictionary = {
	"Common": 60.0,
	"Uncommon": 30.0,
	"Rare": 9.0,
	"Legendary": 1.0,
}

# Border colors by rarity
const RARITY_COLOR: Dictionary = {
	"Common": Color8( 90, 160,  90),
	"Uncommon": Color8( 90, 140, 200),
	"Rare":     Color8(180,  80, 200),
	"Legendary":Color8(230, 170,  40),
}

func get_weight() -> float:
	return float(RARITY_WEIGHT.get(rarity, 0.0))

func get_color() -> Color:
	var c: Variant = RARITY_COLOR.get(rarity, Color.WHITE)
	return c as Color
