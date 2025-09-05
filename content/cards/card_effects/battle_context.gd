extends Resource
class_name BattleContext

var rng: RandomNumberGenerator
var attacker_name: String
var defender_name: String

var atk_multiplier: float = 1.0
var extra_attacks: int = 0

var log_cb: Callable = Callable()  # default empty callable

func log(msg: String) -> void:
	if log_cb.is_valid():
		log_cb.call(msg)
