extends Resource
class_name Spell

# Spell properties
@export var spell_name: String = ""
@export var mana_cost: int = 1
@export var effect_type: String = ""  # "damage", "heal", "buff", "debuff", "utility"
@export var description: String = ""
@export var power: int = 0  # Damage amount, heal amount, etc.

func _init(p_name: String = "", p_cost: int = 1, p_effect: String = "", p_desc: String = "", p_power: int = 0):
	spell_name = p_name
	mana_cost = p_cost
	effect_type = p_effect
	description = p_desc
	power = p_power

func can_cast(current_mana: int) -> bool:
	return current_mana >= mana_cost

func get_display_name() -> String:
	return spell_name + " (" + str(mana_cost) + " mana)"
