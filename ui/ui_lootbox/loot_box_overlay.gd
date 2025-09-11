# LootBoxOverlay.gd
extends Control

@onready var dimmer: ColorRect = $Window/Dimmer
@onready var window: Control = $Window
@onready var content: Node   = $Window/Dimmer/HBoxContainer/VBox/Content     # LootBoxComponent lives here
@onready var result_text: Label = $Window/Dimmer/HBoxContainer/VBox/ResultText
@onready var close_btn: Button  = $Window/Dimmer/HBoxContainer/VBox/TitleBar/Close

func _ready() -> void:
	visible = false
	modulate.a = 0.0

	# Hook lootbox signal to show result text
	if content != null and content.has_signal("opened"):
		content.connect("opened", _on_opened)

	# Connect close buttons (second close may or may not exist)
	if is_instance_valid(close_btn):
		close_btn.pressed.connect(close_basic_lootbox)

	# Color the rarity legend
	var col = CardDef.RARITY_COLOR
	#$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/CommonBox/ColorRect.color    = col["Common"]
	#$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/UncommonBox/ColorRect.color  = col["Uncommon"]
	#$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/RareBox/ColorRect.color      = col["Rare"]
	#$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/LegendaryBox/ColorRect.color = col["Legendary"]

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_basic_lootbox()
		get_viewport().set_input_as_handled()

func open_basic_lootbox() -> void:
	result_text.text = ""  # clear last result
	visible = true
	var t: Tween = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.18)

func close_basic_lootbox() -> void:
	var t: Tween = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.finished.connect(func() -> void:
		visible = false
	)

func _on_opened(def: CardDef, _item: InvItem) -> void:
	# Update result label using pulled def
	result_text.text = "%s  (%s)" % [def.name, def.rarity]
	if def.has_method("get_color"):
		result_text.add_theme_color_override("font_color", def.get_color())
