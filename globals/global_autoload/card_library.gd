extends Node

@export var defs: Array[CardDef] = []

var _by_id: Dictionary = {}  # String -> CardDef

func _ready() -> void:
	_by_id.clear()
	for d: CardDef in defs:
		if d == null:
			continue
		var key: String = String(d.id)
		if key == "":
			key = d.name  # temporary fallback if migrating
		_by_id[key] = d

func has(id: String) -> bool:
	return _by_id.has(id)

func get_def(id: String) -> CardDef:
	var v: Variant = _by_id.get(id, null)
	return v as CardDef
