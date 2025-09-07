# res://globals/components/collectable_component.gd
extends Area2D
class_name CollectableComponent

# Use ONE of these:
@export var item: InvItem = null              # preferred: a ready InvItem .tres
@export var item_id: StringName = &""         # fallback: build from id via ItemFactory
@export var amount: int = 1                   # how many to give

var _icon_sprite: Sprite2D = null             # optional: auto-detected Sprite2D called "Icon"

func _ready() -> void:
	# connect once
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# auto-detect an Icon sprite (sibling named "Icon") — optional
	# if you don't have one, this does nothing.
	_icon_sprite = get_node_or_null("../Icon") as Sprite2D
	_update_icon()

# inside your Area2D component
func _on_body_entered(body: Node2D) -> void:
	if body is Player and item != null:
		var pl: Player = body as Player
		if pl.loadout != null:
			if item.card_def != null:
				pl.loadout.cards.insert(item, 1)
			else:
				pl.loadout.items.insert(item, 1)
		get_parent().queue_free()

# ---------- helpers ----------

func _resolve_item() -> InvItem:
	# prefer the explicit resource
	if item != null:
		# duplicate so we don't mutate the original .tres accidentally
		var dup: Resource = item.duplicate(true)
		return dup as InvItem

	# otherwise try to build from id
	if String(item_id) != "":
		return ItemFactory.make_item(String(item_id))

	return null

func _update_icon() -> void:
	if _icon_sprite == null:
		return

	var tex: Texture2D = null
	if item != null and item.texture != null:
		tex = item.texture
	elif String(item_id) != "":
		tex = ItemFactory.get_icon(String(item_id))

	_icon_sprite.texture = tex
