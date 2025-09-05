extends Resource
class_name InvItem

@export var id: String = ""
@export var texture: Texture2D
@export var stack_size: int = 99

# For card-type items (non-cards keep this null)
@export var card_def: CardDef = null
