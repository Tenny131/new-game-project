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
	
func count_by_id(id: String) -> int:
	var total: int = 0
	for s in slots:
		if s.item and s.item.id == id:
			total += s.amount
	return total


func remove_by_id(id: String, amount: int) -> bool:
	var left: int = amount
	for s in slots:
		if s.item and s.item.id == id:
			var take: int = left if left < s.amount else s.amount  # <- no Variant
			s.amount -= take
			left -= take
			if s.amount <= 0:
				s.item = null
			if left == 0:
				update.emit()
				return true
	update.emit()
	return false
