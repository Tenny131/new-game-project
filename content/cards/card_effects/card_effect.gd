extends Resource
class_name CardEffect

func on_battle_start(_ctx: BattleContext) -> void: 
	pass
func on_turn_start(_ctx: BattleContext) -> void: 
	pass
func on_pre_attack(_ctx: BattleContext) -> void: 
	pass   # before damage calc
func on_post_attack(_ctx: BattleContext) -> void: 
	pass  # after damage applied
func on_take_hit(_ctx: BattleContext) -> void: 
	pass
func on_death(_ctx: BattleContext) -> void: 
	pass
func on_battle_end(_ctx: BattleContext) -> void: 
	pass
