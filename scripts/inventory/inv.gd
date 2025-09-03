extends Resource
class_name Inv

signal update

@export var slots: Array[InvSlot] = []

# Insert 'amount' of an item. Stacks by item.id when stack_size > 1.
func insert(item: InvItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var remaining: int = amount

	# 1) Fill existing stacks first (same id)
	if item.stack_size > 1:
		for s: InvSlot in slots:
			if s.item != null and s.item.id == item.id and s.amount < s.item.stack_size:
				var can_add: int = min(remaining, s.item.stack_size - s.amount)
				s.amount += can_add
				remaining -= can_add
				if remaining == 0:
					update.emit()
					return true

	# 2) Use empty slots
	for s: InvSlot in slots:
		if s.item == null:
			s.item = item
			var put: int = (min(remaining, item.stack_size) if item.stack_size > 1 else 1)
			s.amount = put
			remaining -= put
			if remaining == 0:
				update.emit()
				return true

	update.emit()
	return remaining == 0
