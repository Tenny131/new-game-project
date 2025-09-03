extends Resource
class_name InvItem

@export var id: String = ""          # e.g. "Gigachad", "FireCat"
@export var texture: Texture2D       # icon shown in inventory
@export var stack_size: int = 99     # max per stack (set >1 to enable stacking)
