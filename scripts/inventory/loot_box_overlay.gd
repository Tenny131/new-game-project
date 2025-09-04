# LootBoxOverlay.gd
extends Control

@onready var dimmer: ColorRect = $Dimmer
@onready var window: Control = $Window
@onready var content: Control = $Window/VBox/Content        # node with LootBox script
@onready var result_text: Label = $Window/VBox/MarginContainer/InfoRow/ResultText
@onready var close_btn: Button = $Window/VBox/TitleBar/Close
@onready var close2_btn: Button = $Window/VBox/MarginContainer2/Buttons/Close2
@onready var open10_btn: Button = $Window/VBox/MarginContainer2/Buttons/Open10

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	# Hook lootbox "opened" signal to show result text
	if content.has_signal("opened"):
		content.connect("opened", _on_opened)
	close_btn.pressed.connect(close)
	close2_btn.pressed.connect(close)
	open10_btn.pressed.connect(func(): _set_draws(10))
	var col = CardDef.RARITY_COLOR
	$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/CommonBox/ColorRect.color = col["Common"]
	$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/UncommonBox/ColorRect.color = col["Uncommon"]
	$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/RareBox/ColorRect.color = col["Rare"]
	$Window/VBox/MarginContainer/InfoRow/MarginContainer/RarityLegend/LegendaryBox/ColorRect.color = col["Legendary"]

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func _set_draws(n: int) -> void:
	if content.has_method("set"): # exported var draws_per_open
		content.set("draws_per_open", n)

func _on_opened(def: CardDef, _item: InvItem) -> void:
	result_text.text = "%s  (%s)" % [def.name, def.rarity]
	# optional: tint the text by rarity color
	if def.has_method("get_color"):
		result_text.add_theme_color_override("font_color", def.get_color())

func open() -> void:
	visible = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.18)

func close() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.finished.connect(func(): visible = false)
