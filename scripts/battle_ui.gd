extends Control
class_name BattleUI

# Inputs
@export var player_loadout: PlayerLoadout
@export var enemy_cards: Array[CardDef] = []   # simple enemy queue for MVP

# UI refs
@onready var player_card_tex: TextureRect = $Panel/VBox/TopRow/PlayerPane/PlayerCard
@onready var enemy_card_tex:  TextureRect = $Panel/VBox/TopRow/EnemyPane/EnemyCard
@onready var player_hp: ProgressBar = $Panel/VBox/TopRow/PlayerPane/PlayerHP
@onready var enemy_hp:  ProgressBar = $Panel/VBox/TopRow/EnemyPane/EnemyHP
@onready var log_label: RichTextLabel = $Panel/VBox/TopRow/LogPane/Log
@onready var start_btn: Button = $Panel/VBox/Controls/Start
@onready var next_btn: Button = $Panel/VBox/Controls/Next

# Runtime battle card
class BattleCard:
	var name: String
	var level: int
	var atk: int
	var hp_max: int
	var hp: int
	var icon: Texture2D
	func _init(n: String, lv: int, a: int, h: int, ic: Texture2D) -> void:
		name = n; level = lv; atk = a; hp_max = h; hp = h; icon = ic

var p_queue: Array[BattleCard] = []
var e_queue: Array[BattleCard] = []
var current_p: BattleCard = null
var current_e: BattleCard = null
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	next_btn.disabled = true
	start_btn.pressed.connect(_on_start_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	_build_queues()

func _build_queues() -> void:
	p_queue.clear()
	e_queue.clear()

	# Player queue from loadout (battle slots 0..3)
	if player_loadout != null:
		for i in 4:
			var item: InvItem = player_loadout.battle[i]
			if item != null and item.card_def != null:
				var d: CardDef = item.card_def
				p_queue.append(BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon))

	# Enemy queue from enemy_cards
	for d in enemy_cards:
		e_queue.append(BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon))

	# Fallback if any side empty
	if p_queue.is_empty():
		log_label.append_text("[color=yellow]No player cards equipped![/color]\n")
	if e_queue.is_empty():
		log_label.append_text("[color=yellow]No enemy cards set![/color]\n")

func _on_start_pressed() -> void:
	if p_queue.is_empty() or e_queue.is_empty():
		return
	start_btn.disabled = true
	next_btn.disabled = true
	log_label.clear()
	_next_pair()
	await _run_pair()  # run until one side dies
	_finish_or_continue()

func _on_next_pressed() -> void:
	# Close the battle or notify overworld here; for MVP just queue_free
	get_tree().current_scene.queue_free()

func _next_pair() -> void:
	current_p = p_queue.pop_front()
	current_e = e_queue.pop_front()
	_set_ui_for_current()

func _set_ui_for_current() -> void:
	# Player
	player_card_tex.texture = current_p.icon
	player_hp.max_value = current_p.hp_max
	player_hp.value = current_p.hp_max
	# Enemy
	enemy_card_tex.texture = current_e.icon
	enemy_hp.max_value = current_e.hp_max
	enemy_hp.value = current_e.hp_max
	# Log
	log_label.append_text("[b]%s[/b] vs [b]%s[/b]\n" % [current_p.name, current_e.name])

func _roll_initiative(p: BattleCard, e: BattleCard) -> String:
	# winner: "P" or "E"
	var p_roll: float = rng.randf() + float(p.level) * 0.05
	var e_roll: float = rng.randf() + float(e.level) * 0.05
	return "P" if p_roll >= e_roll else "E"

func _run_pair() -> void:
	var who: String = _roll_initiative(current_p, current_e)
	log_label.append_text("Initiative: %s\n" % ("Player" if who == "P" else "Enemy"))
	await get_tree().process_frame

	while current_p.hp > 0 and current_e.hp > 0:
		if who == "P":
			await _attack(current_p, current_e, true)
			if current_e.hp <= 0: break
			who = "E"
		else:
			await _attack(current_e, current_p, false)
			if current_p.hp <= 0: break
			who = "P"
		await get_tree().process_frame

func _attack(att: BattleCard, def: BattleCard, player_is_attacking: bool) -> void:
	# Effects hooks will go here later
	def.hp = max(def.hp - att.atk, 0)
	if player_is_attacking:
		log_label.append_text("[color=cyan]%s[/color] hits [color=tomato]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, att.atk])
		enemy_hp.value = def.hp
	else:
		log_label.append_text("[color=orange]%s[/color] hits [color=mediumseagreen]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, att.atk])
		player_hp.value = def.hp
	await get_tree().create_timer(0.35).timeout

func _finish_or_continue() -> void:
	if current_p.hp <= 0 and p_queue.is_empty():
		log_label.append_text("[color=red]Player loses this round![/color]\n")
	elif current_e.hp <= 0 and e_queue.is_empty():
		log_label.append_text("[color=green]Enemy defeated![/color]\n")

	# If both have more cards, continue auto
	if current_p.hp <= 0 and not p_queue.is_empty():
		log_label.append_text("Next player card steps in!\n")
		var next_p: BattleCard = p_queue.pop_front()
		current_p = next_p
		player_card_tex.texture = current_p.icon
		player_hp.max_value = current_p.hp_max
		player_hp.value = current_p.hp
		await _run_pair()
	elif current_e.hp <= 0 and not e_queue.is_empty():
		log_label.append_text("Next enemy card steps in!\n")
		var next_e: BattleCard = e_queue.pop_front()
		current_e = next_e
		enemy_card_tex.texture = current_e.icon
		enemy_hp.max_value = current_e.hp_max
		enemy_hp.value = current_e.hp
		await _run_pair()

	# End reached if someone ran out of cards
	if (current_p.hp <= 0 and p_queue.is_empty()) or (current_e.hp <= 0 and e_queue.is_empty()):
		log_label.append_text("[b]Battle complete.[/b]\n")
		next_btn.disabled = false
