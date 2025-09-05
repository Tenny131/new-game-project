extends CardEffect
class_name DoubleStrike

@export var chance_percent: float = 10.0

func on_pre_attack(ctx: BattleContext) -> void:
	var roll: float = ctx.rng.randf() * 100.0
	if roll < chance_percent:
		ctx.extra_attacks += 1
		ctx.log("[i]Double strike triggered![/i]\n")
