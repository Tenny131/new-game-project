extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

@export var pickup_scene: PackedScene = preload("res://content/items/item_pickup.tscn")
@export var drop_id: StringName = &"log"
@export var drop_min: int = 1
@export var drop_max: int = 2

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damage_reached.connect(on_max_damage_reached)

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	if material != null:
		material.set_shader_parameter("shake_intensity", 1.0)
		await get_tree().create_timer(1.0).timeout
		material.set_shader_parameter("shake_intensity", 0.0)

func on_max_damage_reached() -> void:
	call_deferred("_spawn_drop_and_die")

func _spawn_drop_and_die() -> void:
	var count: int = randi_range(drop_min, drop_max)
	for i in range(count):
		_spawn_one_pickup()
	queue_free()

func _spawn_one_pickup() -> void:
	if pickup_scene == null:
		return
	var p: Node = pickup_scene.instantiate()
	var cc: CollectableComponent = p.get_node("CollectableComponent") as CollectableComponent
	if cc != null:
		cc.configure_with_id(drop_id, 1)
	# place in world
	var parent: Node = get_parent()
	if parent != null:
		parent.add_child(p)
	else:
		get_tree().current_scene.add_child(p)
	(p as Node2D).global_position = global_position
