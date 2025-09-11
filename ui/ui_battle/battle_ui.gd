extends Control
class_name BattleUI

signal battle_finished(player_won: bool)

@export var player: Player                          # <- get equipped cards from player.loadout.battle
@export var enemy_cards: Array[CardDef] = []
@export var step_pause: float = 0.35

@onready var player_image: TextureRect   = $Panel/VBox/TopRow/PlayerPane/PlayerCard
@onready var player_hp_bar: ProgressBar  = $Panel/VBox/TopRow/PlayerPane/PlayerHP
@onready var enemy_image: TextureRect    = $Panel/VBox/TopRow/EnemyPane/EnemyCard
@onready var enemy_hp_bar: ProgressBar   = $Panel/VBox/TopRow/EnemyPane/EnemyHP
@onready var start_button: Button        = $Panel/VBox/Controls/Start
@onready var close_button: Button        = $Panel/VBox/Controls/Close
@onready var log_label: RichTextLabel    = $Panel/VBox/TopRow/LogPane/Log

var player_card_index: int = 0
var enemy_card_index: int = 0
var player_current_hp: int = 0
var enemy_current_hp: int = 0
var battle_cancelled: bool = false

func _ready() -> void:
	# Buttons
	if start_button:
		start_button.pressed.connect(func() -> void:
			start_button.disabled = true
			battle_cancelled = false
			await _run_battle()
			start_button.disabled = false
		)
	if close_button:
		close_button.pressed.connect(func() -> void:
			battle_cancelled = true
			visible = false
		)
	# Initial preview (shows first player/enemy card if present)
	_refresh_preview()

# --- Helpers to get equipped cards from the Player ---
func _get_player_battle_cards() -> Array[CardDef]:
	var equipped: Array[CardDef] = []
	if player != null and player.get("loadout") != null and player.loadout.battle != null:
		for ghost_item: InvItem in player.loadout.battle:
			if ghost_item != null and ghost_item.card_def != null:
				equipped.append(ghost_item.card_def)
	return equipped

# Preview first cards before battle starts
func _refresh_preview() -> void:
	player_card_index = 0
	enemy_card_index = 0

	var equipped := _get_player_battle_cards()

	# Player preview
	if equipped.size() > 0:
		var first_player := equipped[0]
		player_current_hp = first_player.hp
		player_image.texture = first_player.icon
		player_hp_bar.max_value = first_player.hp
		player_hp_bar.value = player_current_hp
	else:
		player_current_hp = 0
		player_image.texture = null
		player_hp_bar.max_value = 1
		player_hp_bar.value = 0

	# Enemy preview
	if enemy_cards.size() > 0:
		var first_enemy := enemy_cards[0]
		enemy_current_hp = first_enemy.hp
		enemy_image.texture = first_enemy.icon
		enemy_hp_bar.max_value = first_enemy.hp
		enemy_hp_bar.value = enemy_current_hp
	else:
		enemy_current_hp = 0
		enemy_image.texture = null
		enemy_hp_bar.max_value = 1
		enemy_hp_bar.value = 0

# --- Core battle ---
func _run_battle() -> void:
	var player_cards := _get_player_battle_cards() # snapshot at battle start

	if player_cards.is_empty() or enemy_cards.is_empty():
		_append_log("Cannot start: player or enemy team is empty.")
		return

	player_card_index = 0
	enemy_card_index = 0

	# Load first cards into UI (fresh in case preview changed)
	var player_card := player_cards[player_card_index]
	var enemy_card := enemy_cards[enemy_card_index]
	player_current_hp = player_card.hp
	enemy_current_hp = enemy_card.hp
	player_image.texture = player_card.icon
	player_hp_bar.max_value = player_card.hp
	player_hp_bar.value = player_current_hp
	enemy_image.texture = enemy_card.icon
	enemy_hp_bar.max_value = enemy_card.hp
	enemy_hp_bar.value = enemy_current_hp

	_append_log("Battle begins!")

	while not battle_cancelled and player_card_index < player_cards.size() and enemy_card_index < enemy_cards.size():
		player_card = player_cards[player_card_index]
		enemy_card = enemy_cards[enemy_card_index]

		_append_log("[%s] vs [%s]" % [player_card.name, enemy_card.name])
		await get_tree().create_timer(step_pause).timeout
		if battle_cancelled: break

		# Player attacks
		enemy_current_hp = max(0, enemy_current_hp - player_card.atk)
		enemy_hp_bar.value = enemy_current_hp
		_append_log("%s hits %s for %d (Enemy HP: %d/%d)" % [player_card.name, enemy_card.name, player_card.atk, enemy_current_hp, enemy_card.hp])
		await get_tree().create_timer(step_pause).timeout
		if battle_cancelled: break

		if enemy_current_hp <= 0:
			_append_log("%s is defeated!" % enemy_card.name)
			enemy_card_index += 1
			if enemy_card_index >= enemy_cards.size():
				break
			var next_enemy := enemy_cards[enemy_card_index]
			enemy_current_hp = next_enemy.hp
			enemy_image.texture = next_enemy.icon
			enemy_hp_bar.max_value = next_enemy.hp
			enemy_hp_bar.value = enemy_current_hp
			_append_log("Next enemy: %s (HP %d)" % [next_enemy.name, next_enemy.hp])
			await get_tree().create_timer(step_pause).timeout
			continue

		# Enemy attacks
		player_current_hp = max(0, player_current_hp - enemy_card.atk)
		player_hp_bar.value = player_current_hp
		_append_log("%s hits %s for %d (Player HP: %d/%d)" % [enemy_card.name, player_card.name, enemy_card.atk, player_current_hp, player_card.hp])
		await get_tree().create_timer(step_pause).timeout
		if battle_cancelled: break

		if player_current_hp <= 0:
			_append_log("%s is defeated!" % player_card.name)
			player_card_index += 1
			if player_card_index >= player_cards.size():
				break
			var next_player := player_cards[player_card_index]
			player_current_hp = next_player.hp
			player_image.texture = next_player.icon
			player_hp_bar.max_value = next_player.hp
			player_hp_bar.value = player_current_hp
			_append_log("Next player card: %s (HP %d)" % [next_player.name, next_player.hp])
			await get_tree().create_timer(step_pause).timeout

	var player_won := (enemy_card_index >= enemy_cards.size()) and (player_card_index < player_cards.size()) and not battle_cancelled
	_append_log("Battle complete. Result: %s" % ("Player WIN" if player_won else "Player LOSE"))
	emit_signal("battle_finished", player_won)

func _append_log(message: String) -> void:
	if log_label != null:
		log_label.append_text(message + "\n")
