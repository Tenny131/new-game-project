extends Resource
class_name BattleTeam

# Up to 4 front-line and 4 support cards (CardDef .tres)
@export var name: String = "Enemy Team"
@export var battle: Array[CardDef] = []
@export var support: Array[CardDef] = []

# Optional drops later, if you want
# @export var drops: Array[DropEntry] = []
