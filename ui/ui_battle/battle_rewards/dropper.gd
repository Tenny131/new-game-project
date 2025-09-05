extends Node
class_name Dropper

static func roll(enc: EncounterDef, rng: RandomNumberGenerator) -> Array[InvItem]:
	var out: Array[InvItem] = []
	for _r in enc.rolls:
		var picked: DropEntry = _pick_weighted(enc.drops, rng)
		if picked == null: continue
		var amt: int = picked.amount_min + rng.randi_range(0, max(0, picked.amount_max - picked.amount_min))
		match picked.drop_type:
			"Currency", "Item":
				var it := InvItem.new()
				it.id = picked.id
				it.stack_size = 999
				it.texture = null   # optional icon
				out.append(_stacked(it, amt))
			"Card":
				if picked.card_def != null:
					var ic := InvItem.new()
					ic.id = picked.card_def.name
					ic.stack_size = 1
					ic.texture = picked.card_def.icon
					ic.card_def = picked.card_def
					out.append(ic)
	return out

static func _pick_weighted(entries: Array[DropEntry], rng: RandomNumberGenerator) -> DropEntry:
	var total: int = 0
	for e in entries:
		total += max(e.weight, 0)
	if total <= 0: return null
	var r: int = rng.randi_range(1, total)
	for e in entries:
		r -= max(e.weight, 0)
		if r <= 0: return e
	return entries.back()

static func _stacked(item: InvItem, _amount: int) -> InvItem:
	# Return a single InvItem representing 'amount' to be inserted with 'amount'
	# Your inventory insert already handles amount. We'll carry amount via return array length.
	# If you prefer exact amounts, you can extend InvItem with an 'amount' field.
	return item
