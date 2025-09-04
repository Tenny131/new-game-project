extends Resource
class_name PlayerLoadout

@export var battle: Array[InvItem] = [null, null, null, null]
@export var support: Array[InvItem] = [null, null, null, null]

func get_slot(slot_type: String, index: int) -> InvItem:
	if slot_type == "BATTLE":
		return battle[index]
	return support[index]

func set_slot(slot_type: String, index: int, item: InvItem) -> void:
	if slot_type == "BATTLE":
		battle[index] = item
	else:
		support[index] = item
