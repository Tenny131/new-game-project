extends Node
#class_name GameState

const SAVE_PATH: String = "user://save_0.json"

var shards: int = 0
var discovered: Dictionary = {}  # String -> bool (card ids)
var pity_counter: int = 0  # reserved for later

# --------- capture/apply ---------

func capture(inv: Inv, loadout: PlayerLoadout) -> Dictionary:
	var inv_data: Array[Dictionary] = []

	if inv != null:
		for s: InvSlot in inv.slots:
			if s.item != null and s.amount > 0:
				inv_data.append({
					"id": String(s.item.id),
					"amount": int(s.amount)
				})

	var battle_ids: Array[String] = ["", "", "", ""]
	var support_ids: Array[String] = ["", "", "", ""]

	if loadout != null:
		var max_slots: int = 4
		for i: int in range(max_slots):
			var b: InvItem = loadout.battle[i] if i < loadout.battle.size() else null
			var sp: InvItem = loadout.support[i] if i < loadout.support.size() else null
			battle_ids[i] = b.id if b != null else ""
			support_ids[i] = sp.id if sp != null else ""

	var disc: Array[String] = []
	for k in discovered.keys():
		if bool(discovered[k]):
			disc.append(String(k))

	return {
		"shards": int(shards),
		"inventory": inv_data,
		"battle": battle_ids,
		"support": support_ids,
		"discovered": disc,
		"pity_counter": int(pity_counter),
	}



func apply(save: Dictionary, inv: Inv, loadout: PlayerLoadout) -> void:
	shards = int(save.get("shards", 0))
	pity_counter = int(save.get("pity_counter", 0))

	# --- inventory: clear, then rebuild ---
	for s: InvSlot in inv.slots:
		s.item = null
		s.amount = 0
	inv.update.emit()

	var inv_arr: Array = save.get("inventory", [])
	for entry_raw in inv_arr:
		var entry: Dictionary = entry_raw as Dictionary
		var id: String = String(entry.get("id", ""))
		var amount: int = int(entry.get("amount", 1))
		if id != "":
			var item: InvItem = ItemFactory.make_item(id)
			inv.insert(item, amount)

	# --- loadout ghosts (battle/support) ---
	if loadout != null:
		var battle_save: Array = save.get("battle", ["", "", "", ""])
		var support_save: Array = save.get("support", ["", "", "", ""])
		for i: int in range(4):
			var bid: String = String(battle_save[i])
			var sid: String = String(support_save[i])

			var b_item: InvItem = null
			var s_item: InvItem = null
			if bid != "":
				b_item = ItemFactory.make_item(bid)
			if sid != "":
				s_item = ItemFactory.make_item(sid)

			loadout.set_slot("BATTLE", i, b_item)
			loadout.set_slot("SUPPORT", i, s_item)

	# --- discovered ---
	discovered.clear()
	var disc_arr: Array = save.get("discovered", [])
	for id_val in disc_arr:
		discovered[String(id_val)] = true


# --------- disk io ---------

func save_to_disk(inv: Inv, loadout: PlayerLoadout) -> void:
	if inv == null or loadout == null:
		push_warning("GameState.save_to_disk called with null inv or loadout; aborting save.")
		return
	var data: Dictionary = capture(inv, loadout)
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		var json_text: String = JSON.stringify(data, "\t")
		f.store_string(json_text)
		print("SAVED GAME")
		f.close()



func load_from_disk(inv: Inv, loadout: PlayerLoadout) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false

	var text: String = f.get_as_text()
	f.close()

	var res: Variant = JSON.parse_string(text)
	if res is Dictionary:
		var data: Dictionary = res as Dictionary
		apply(data, inv, loadout)
		print("LOADED GAME")
		return true
	return false
