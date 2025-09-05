class_name HurtComponent
extends Area2D

@export var tool : DataTypes.Tools = DataTypes.Tools.None
var item_name: String = "Stone"

signal hurt

func _on_area_entered(area: Area2D) -> void:
	var hit_component = area as HitComponent
	
	if tool == hit_component.current_tool:
		hurt.emit(hit_component.hit_damage)
