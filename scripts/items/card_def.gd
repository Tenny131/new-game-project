extends Resource
class_name CardDef

@export var name: String
@export var description: String
@export var level: int = 1
@export var atk: int = 1
@export var hp: int = 1
@export var icon: Texture2D
@export var stack_size: int = 99          # how many identical cards can stack
@export var weight: float = 1.0           # relative chance in weighted rolls (0 = never picked)
