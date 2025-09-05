extends Control
class_name BattleUI

#const BattleContext = preload("res://scripts/items/card_effects/battle_context.gd")
#const CardEffect = preload("res://scripts/items/card_effects/card_effect.gd")

signal battle_finished(player_won: bool, rewards: Array[InvItem])
@export var encounter: EncounterDef

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
	var effects: Array[CardEffect] = []
	var atk_turn_multiplier: float = 1.0

	func _init(n: String, lv: int, a: int, h: int, ic: Texture2D, fx: Array[CardEffect]) -> void:
		name = n; level = lv; atk = a; hp_max = h; hp = h; icon = ic
		effects = fx


var p_queue: Array[BattleCard] = []
var e_queue: Array[BattleCard] = []
var current_p: BattleCard = null
var current_e: BattleCard = null
var rng :RandomNumberGenerator= RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	next_btn.disabled = true
	start_btn.pressed.connect(_on_start_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	_build_queues()

func _build_queues() -> void:
	p_queue.clear()
	e_queue.clear()

	# --- Player queue from equipped battle slots ---
	if player_loadout != null:
		for i: int in range(4):
			var it: InvItem = player_loadout.battle[i]
			if it != null and it.card_def != null:
				var d: CardDef = it.card_def
				var fx: Array[CardEffect] = []
				for eff: CardEffect in d.effects:
					fx.append(eff.duplicate(true) as CardEffect)
				var bc: BattleCard = BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon, fx)
				p_queue.append(bc)
	else:
		log_label.append_text("[color=yellow]No player loadout set.[/color]\n")

	# --- Enemy queue from inspector-provided list (simple MVP) ---
	if enemy_cards.is_empty():
		log_label.append_text("[color=yellow]No enemy cards set.[/color]\n")
	else:
		for d: CardDef in encounter.enemy_cards:
			var fx_e: Array[CardEffect] = []
			for eff: CardEffect in d.effects:
				fx_e.append(eff.duplicate(true) as CardEffect)
			var be: BattleCard = BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon, fx_e)
			e_queue.append(be)


func _on_start_pressed() -> void:
	if (player_loadout == null) or (encounter == null) or encounter.enemy_cards.is_empty():

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
			var ctx: BattleContext = _run_turn_start_fx(current_p, current_e)
			await _attack_with_fx(current_p, current_e, true, ctx)
			if current_e.hp <= 0: break
			who = "E"
		else:
			var ctx2: BattleContext = _run_turn_start_fx(current_e, current_p)
			await _attack_with_fx(current_e, current_p, false, ctx2)
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
		
	var won: bool = (current_e.hp <= 0 and e_queue.is_empty())
	var rewards: Array[InvItem] = []
	if won and encounter != null:
		var _dropper := Dropper.new()
		rewards = Dropper.roll(encounter, rng)
	battle_finished.emit(won, rewards)



func _ctx_for(att: BattleCard, def: BattleCard) -> BattleContext:
	var ctx: BattleContext = BattleContext.new()
	ctx.rng = rng
	ctx.attacker_name = att.name
	ctx.defender_name = def.name
	ctx.log_cb = func(msg: String) -> void:
		log_label.append_text(msg)
	return ctx


func _run_turn_start_fx(att: BattleCard, def: BattleCard) -> BattleContext:
	var ctx: BattleContext = _ctx_for(att, def)
	ctx.atk_multiplier = 1.0
	ctx.extra_attacks = 0
	for eff in att.effects:
		eff.on_turn_start(ctx)
	att.atk_turn_multiplier = ctx.atk_multiplier
	return ctx

func _attack_with_fx(att: BattleCard, def: BattleCard, player_is_attacking: bool, ctx: BattleContext) -> void:
	# pre-attack fx (e.g., double strike)
	for eff in att.effects:
		eff.on_pre_attack(ctx)

	var attacks: int = 1 + ctx.extra_attacks
	for _i in attacks:
		var dmg: int = int(round(float(att.atk) * att.atk_turn_multiplier))
		def.hp = max(def.hp - dmg, 0)
		if player_is_attacking:
			log_label.append_text("[color=cyan]%s[/color] hits [color=tomato]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, dmg])
			enemy_hp.value = def.hp
		else:
			log_label.append_text("[color=orange]%s[/color] hits [color=mediumseagreen]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, dmg])
			player_hp.value = def.hp

		for eff in att.effects:
			eff.on_post_attack(ctx)
		if def.hp <= 0:
			var ctx_dead: BattleContext = _ctx_for(att, def)
			for eff in def.effects:
				eff.on_death(ctx_dead)
			break
		await get_tree().create_timer(0.25).timeout
