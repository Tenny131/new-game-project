# res://tools/validate_card_ids.gd
@tool
extends EditorScript

func _run() -> void:
	var base_path: String = "res://content/cards/base_cards/card_resources/"  # adjust to your folder
	var card_defs: Array[CardDef] = _collect_card_defs(base_path)

	var seen: Dictionary = {}   # id String -> path String
	var ok: bool = true

	for def: CardDef in card_defs:
		var sid: String = String(def.id)
		var path: String = def.resource_path

		if sid == "":
			push_error("CardDef missing id: %s" % path)
			ok = false
			continue

		if seen.has(sid):
			push_error("Duplicate CardDef id '%s' in:\n  - %s\n  - %s" % [
				sid, path, String(seen[sid])
			])
			ok = false
		else:
			seen[sid] = path

	if ok:
		print("CardDef ids OK: %d checked." % seen.size())

func _collect_card_defs(dir_path: String) -> Array[CardDef]:
	var out: Array[CardDef] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("No such folder: %s" % dir_path)
		return out

	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break

		var full: String = dir_path + "/" + name
		if dir.current_is_dir():
			if name.begins_with("."):
				continue
			var nested: Array[CardDef] = _collect_card_defs(full)
			for d: CardDef in nested:
				out.append(d)
		else:
			if name.ends_with(".tres"):
				var res: Resource = ResourceLoader.load(full)
				var def: CardDef = res as CardDef
				if def != null:
					out.append(def)
	dir.list_dir_end()
	return out
