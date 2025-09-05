extends Resource
class_name ItemDef

# stable key for save/lookup (lowercase, snake_case)
@export var id: StringName = &""

# display + behavior
@export var name: String = ""
@export var icon: Texture2D
@export var stack_size: int = 99
@export var description: String = ""
