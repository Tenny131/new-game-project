extends Node

# Assign your non-card ItemDef .tres here
@export var item_defs: Array[ItemDef] = []

# Optional fallback icons for ids you haven't made ItemDefs for yet
@export var resource_icons: Dictionary = {
	"shard": "res://assets/ui/shard.png"
}

var _item_by_id: Dictionary = {}  # String -> ItemDef

func _ready() -> void:
	_item_by_id.clear()
	for d: ItemDef in item_defs:
		if d != null:
			var key: String = String(d.id)
			if key != "":
				_item_by_id[key] = d

func has_item_def(id: String) -> bool:
	return _item_by_id.has(id)

func get_item_def(id: String) -> ItemDef:
	var v: Variant = _item_by_id.get(id, null)
	return v as ItemDef

func make_item(id: String) -> InvItem:
	var it: InvItem = InvItem.new()
	it.id = id

	# 1) Cards first
	if CardLibrary.has(id):
		var cdef: CardDef = CardLibrary.get_def(id)
		if cdef != null:
			it.card_def = cdef
			it.texture = cdef.icon
			it.stack_size = cdef.stack_size
			return it

	# 2) Non-card ItemDef
	var idef: ItemDef = get_item_def(id)
	if idef != null:
		it.texture = idef.icon
		it.stack_size = idef.stack_size
		return it

	# 3) Fallback icon map
	var path_any: Variant = resource_icons.get(id, "")
	var path: String = String(path_any)
	if path != "":
		it.texture = load(path) as Texture2D
	else:
		it.texture = null
	it.stack_size = 99
	return it

func get_icon(id: String) -> Texture2D:
	# Card icons
	if CardLibrary.has(id):
		var cdef: CardDef = CardLibrary.get_def(id)
		if cdef != null:
			return cdef.icon

	# ItemDef icons
	var idef: ItemDef = get_item_def(id)
	if idef != null:
		return idef.icon

	# Fallback map
	var path_any: Variant = resource_icons.get(id, "")
	var path: String = String(path_any)
	if path != "":
		return load(path) as Texture2D
	return null
