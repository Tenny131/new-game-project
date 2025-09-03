class_name CollectableComponent
extends Area2D

@export var item_name: String
@export var item: InvItem

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect(item)
		get_parent().queue_free()
		
