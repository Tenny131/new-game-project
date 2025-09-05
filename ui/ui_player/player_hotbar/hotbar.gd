extends PanelContainer

@onready var tool_axe: Button = $MarginContainer/HBoxContainer/ToolAxe
@onready var tool_sword: Button = $MarginContainer/HBoxContainer/ToolSword
@onready var tool_pickaxe: Button = $MarginContainer/HBoxContainer/ToolPickaxe



func _on_tool_axe_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.Axe)


func _on_tool_sword_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.Sword)


func _on_tool_pickaxe_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.Pickaxe)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_tool"):
		ToolManager.select_tool(DataTypes.Tools.None)
		tool_axe.release_focus()
		tool_pickaxe.release_focus()
		tool_sword.release_focus()
		
