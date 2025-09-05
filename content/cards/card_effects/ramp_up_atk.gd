extends CardEffect
class_name RampUpAtk

@export var percent_per_turn: float = 10.0

func on_turn_start(ctx: BattleContext) -> void:
	var mult: float = 1.0 + (percent_per_turn / 100.0)
	ctx.atk_multiplier *= mult
	ctx.log("[i]+%d%% ATK this turn[/i]\n" % int(percent_per_turn))
