# res://resources/player_loadout.gd
extends Resource
class_name PlayerLoadout

# Separate inventories
@export var cards: Inv         # res://resources/inventory/cards.tres
@export var items: Inv         # res://resources/inventory/items.tres

# Equip "ghost" slots – these DO NOT consume stacks
@export var battle: Array[InvItem] = [null, null, null, null]   # 4 slots
@export var support: Array[InvItem] = [null, null, null, null]  # 4 slots

func set_slot(slot_type: String, index: int, item: InvItem) -> void:
	if slot_type == "BATTLE":
		if index >= 0 and index < battle.size():
			battle[index] = item
	elif slot_type == "SUPPORT":
		if index >= 0 and index < support.size():
			support[index] = item

func get_slot(slot_type: String, index: int) -> InvItem:
	if slot_type == "BATTLE":
		if index >= 0 and index < battle.size():
			return battle[index]
		else:
			return null
	elif slot_type == "SUPPORT":
		if index >= 0 and index < support.size():
			return support[index]
		else:
			return null
	else:
		return null
