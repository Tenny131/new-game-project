extends Control
class_name BattleUI

signal battle_finished(player_won: bool, rewards: Array[InvItem])

@export var encounter: EncounterDef
@export var player_loadout: PlayerLoadout
@export var enemy_cards: Array[CardDef] = []
@export var battle_speed: float = 1.0  # 1.0 = normal, >1 = slower, <1 = faster

@onready var player_card_tex: TextureRect = $Panel/VBox/TopRow/PlayerPane/PlayerCard
@onready var enemy_card_tex:  TextureRect  = $Panel/VBox/TopRow/EnemyPane/EnemyCard
@onready var player_hp: ProgressBar       = $Panel/VBox/TopRow/PlayerPane/PlayerHP
@onready var enemy_hp:  ProgressBar       = $Panel/VBox/TopRow/EnemyPane/EnemyHP
@onready var log_label: RichTextLabel     = $Panel/VBox/TopRow/LogPane/Log
@onready var start_btn: Button            = $Panel/VBox/Controls/Start
@onready var close_btn: Button            = $Panel/VBox/Controls/Close   # reused as Close

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
		name = n; level = lv; atk = a; hp_max = h; hp = h; icon = ic; effects = fx

var p_queue: Array[BattleCard] = []
var e_queue: Array[BattleCard] = []
var current_p: BattleCard = null
var current_e: BattleCard = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	close_btn.text = "Close"
	# Pre-battle: you may open and close freely
	_show_prebattle_controls()
	start_btn.pressed.connect(_on_start_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	# Do not auto-build here for NPC; open_battle() will handle it.

# ---------------- Public API ----------------
# Open the UI, prepare queues, but DO NOT start fighting.
func open_battle(p_loadout: PlayerLoadout, enemy_team: BattleTeam) -> void:
	player_loadout = p_loadout
	encounter = null
	enemy_cards = enemy_team.battle.duplicate()
	visible = true
	log_label.clear()
	_build_queues()
	_show_prebattle_controls()

# (Optional wrapper if something still calls this)
func start_battle(p_loadout: PlayerLoadout, enemy_team: BattleTeam) -> void:
	open_battle(p_loadout, enemy_team)
	_on_start_pressed()

# ---------------- Controls ----------------
func _on_start_pressed() -> void:
	log_label.append_text("[i]Battle begins...[/i]\n")
	await get_tree().create_timer(1.0 * battle_speed).timeout

	if player_loadout == null:
		return
	var enemy_src: bool = (encounter != null and not encounter.enemy_cards.is_empty()) or (not enemy_cards.is_empty())
	if not enemy_src:
		return

	_hide_controls_during_battle()

	_next_pair()
	await _run_pair()
	await _finish_or_continue()

func _on_close_pressed() -> void:
	visible = false

func _show_prebattle_controls() -> void:
	start_btn.disabled = false
	start_btn.visible = true
	close_btn.visible = true
	close_btn.disabled = false

func _hide_controls_during_battle() -> void:
	start_btn.disabled = true
	start_btn.visible = false
	close_btn.visible = false
	close_btn.disabled = true

func _show_postbattle_close() -> void:
	close_btn.visible = true
	close_btn.disabled = false
	# keep Start hidden/disabled post-battle unless you want rematches

# ---------------- Setup ----------------
func _build_queues() -> void:
	p_queue.clear()
	e_queue.clear()

	# Player queue from loadout
	if player_loadout != null:
		for i: int in range(4):
			var it: InvItem = player_loadout.battle[i]
			if it != null and it.card_def != null:
				var d: CardDef = it.card_def
				var fx: Array[CardEffect] = []
				for eff: CardEffect in d.effects:
					fx.append(eff.duplicate(true) as CardEffect)
				p_queue.append(BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon, fx))
	else:
		log_label.append_text("[color=yellow]No player loadout set.[/color]\n")

	# Enemy queue: prefer encounter, fallback to inspector list
	var src: Array[CardDef] = []
	if encounter != null and not encounter.enemy_cards.is_empty():
		src = encounter.enemy_cards
	else:
		src = enemy_cards

	if src.is_empty():
		log_label.append_text("[color=yellow]No enemy cards set.[/color]\n")
	else:
		for d: CardDef in src:
			var fx_e: Array[CardEffect] = []
			for eff: CardEffect in d.effects:
				fx_e.append(eff.duplicate(true) as CardEffect)
			e_queue.append(BattleCard.new(d.name, d.level, d.atk, d.hp, d.icon, fx_e))

# ---------------- Battle core ----------------
func _next_pair() -> void:
	current_p = p_queue.pop_front()
	current_e = e_queue.pop_front()
	_set_ui_for_current()

func _set_ui_for_current() -> void:
	player_card_tex.texture = current_p.icon
	player_hp.max_value = current_p.hp_max
	player_hp.value = current_p.hp_max

	enemy_card_tex.texture = current_e.icon
	enemy_hp.max_value = current_e.hp_max
	enemy_hp.value = current_e.hp_max

	log_label.append_text("[b]%s[/b] vs [b]%s[/b]\n" % [current_p.name, current_e.name])

func _roll_initiative(p: BattleCard, e: BattleCard) -> String:
	var p_roll: float = rng.randf() + float(p.level) * 0.05
	var e_roll: float = rng.randf() + float(e.level) * 0.05
	return "P" if p_roll >= e_roll else "E"

func _run_pair() -> void:
	var who: String = _roll_initiative(current_p, current_e)
	log_label.append_text("Initiative: %s\n" % ("Player" if who == "P" else "Enemy"))
	await get_tree().create_timer(1.0 * battle_speed).timeout  # <- add real pause

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
		await get_tree().create_timer(1.0 * battle_speed).timeout  # <- add real pause

func _attack(att: BattleCard, def: BattleCard, player_is_attacking: bool) -> void:
	def.hp = max(def.hp - att.atk, 0)
	if player_is_attacking:
		log_label.append_text("[color=cyan]%s[/color] hits [color=tomato]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, att.atk])
		enemy_hp.value = def.hp
	else:
		log_label.append_text("[color=orange]%s[/color] hits [color=mediumseagreen]%s[/color] for [b]%d[/b]\n" % [att.name, def.name, att.atk])
		player_hp.value = def.hp
	await get_tree().create_timer(0.35 * battle_speed).timeout


func _finish_or_continue() -> void:
	# Advance queues automatically
	if current_p.hp <= 0 and not p_queue.is_empty():
		log_label.append_text("Next player card steps in!\n")
		current_p = p_queue.pop_front()
		player_card_tex.texture = current_p.icon
		player_hp.max_value = current_p.hp_max
		player_hp.value = current_p.hp
		await _run_pair()
	elif current_e.hp <= 0 and not e_queue.is_empty():
		log_label.append_text("Next enemy card steps in!\n")
		current_e = e_queue.pop_front()
		enemy_card_tex.texture = current_e.icon
		enemy_hp.max_value = current_e.hp_max
		enemy_hp.value = current_e.hp
		await _run_pair()

	# End if either side ran out of cards
	if (current_p.hp <= 0 and p_queue.is_empty()) or (current_e.hp <= 0 and e_queue.is_empty()):
		log_label.append_text("[b]Battle complete.[/b]\n")

		var won: bool = (current_e.hp <= 0 and e_queue.is_empty())
		var rewards: Array[InvItem] = []
		if won and encounter != null:
			var _dropper := Dropper.new()
			rewards = Dropper.roll(encounter, rng)

		battle_finished.emit(won, rewards)
		_show_postbattle_close()

# ---------------- Effects scaffolding ----------------
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
	for eff in att.effects:
		eff.on_pre_attack(ctx)

	var attacks: int = 1 + ctx.extra_attacks
	var i: int = 0
	while i < attacks:
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
		await get_tree().create_timer(0.25 * battle_speed).timeout
		i += 1
