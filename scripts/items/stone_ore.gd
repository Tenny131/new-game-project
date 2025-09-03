extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

var stone_item_scene = preload("res://scenes/objects/items/stone_item.tscn")

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)
	
func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 2.0)
	await get_tree().create_timer(1.0).timeout
	material.set_shader_parameter("shake_intensity", 0)
	
func on_max_damage_reached() -> void:
	call_deferred("add_stone_item_scene")
	queue_free()
	
func add_stone_item_scene() -> void:
	var stone_ore_drop_instance = stone_item_scene.instantiate() as Node2D
	stone_ore_drop_instance.global_position = global_position
	get_parent().add_child(stone_ore_drop_instance)
