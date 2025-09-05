extends Resource
class_name DropEntry

@export_enum("Currency","Item","Card") var drop_type: String = "Currency"
@export var id: String = ""                 # for Currency/Item (e.g., "Shard" or "Wood")
@export var amount_min: int = 1
@export var amount_max: int = 1
@export var weight: int = 1
@export var card_def: CardDef = null        # used if drop_type == "Card"
