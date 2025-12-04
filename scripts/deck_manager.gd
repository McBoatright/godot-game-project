extends Node
class_name DeckManager

const Spell = preload("res://scripts/spell.gd")

# Deck configuration
var all_spells: Array[Spell] = []  # The full pool of 15 spells
var available_spells: Array[Spell] = []  # Spells that haven't been picked yet
var picked_spells: Array[Spell] = []  # Spells that have been used

signal deck_refreshed
signal spell_cast(spell: Spell)

func _ready():
	initialize_spells()
	refresh_deck()

func initialize_spells():
	# This will be populated with 15 unique spells
	# For now, creating placeholder spells with varied costs
	
	# Tier 1 spells (1 mana) - 3 spells
	all_spells.append(Spell.new("Spark", 1, "damage", "Quick lightning bolt", 15))
	all_spells.append(Spell.new("Minor Heal", 1, "heal", "Small health recovery", 10))
	all_spells.append(Spell.new("Shield", 1, "buff", "Temporary defense boost", 5))
	
	# Tier 2 spells (2 mana) - 3 spells
	all_spells.append(Spell.new("Fireball", 2, "damage", "Moderate fire damage", 30))
	all_spells.append(Spell.new("Ice Shard", 2, "damage", "Cold damage with slow", 25))
	all_spells.append(Spell.new("Haste", 2, "buff", "Speed boost", 10))
	
	# Tier 3 spells (3 mana) - 3 spells
	all_spells.append(Spell.new("Lightning Strike", 3, "damage", "Heavy lightning damage", 50))
	all_spells.append(Spell.new("Greater Heal", 3, "heal", "Restore significant health", 40))
	all_spells.append(Spell.new("Weaken", 3, "debuff", "Reduce enemy damage", 15))
	
	# Tier 4 spells (4 mana) - 3 spells
	all_spells.append(Spell.new("Meteor", 4, "damage", "Massive area damage", 70))
	all_spells.append(Spell.new("Full Barrier", 4, "buff", "Strong damage absorption", 30))
	all_spells.append(Spell.new("Drain", 4, "utility", "Steal enemy health", 35))
	
	# Tier 5 spells (5 mana) - 3 spells
	all_spells.append(Spell.new("Annihilation", 5, "damage", "Ultimate destruction", 100))
	all_spells.append(Spell.new("Resurrection", 5, "heal", "Full health restore", 100))
	all_spells.append(Spell.new("Time Stop", 5, "utility", "Freeze all enemies", 0))
	
	print("Deck initialized with ", all_spells.size(), " spells")

func refresh_deck():
	# Reset the deck - all spells become available again
	available_spells.clear()
	picked_spells.clear()
	
	for spell in all_spells:
		available_spells.append(spell)
	
	available_spells.shuffle()
	deck_refreshed.emit()
	print("Deck refreshed! ", available_spells.size(), " spells available")

func cast_spell(spell: Spell, current_mana: int) -> bool:
	# Check if spell can be cast
	if not spell.can_cast(current_mana):
		print("Not enough mana to cast ", spell.spell_name)
		return false
	
	if not available_spells.has(spell):
		print("Spell ", spell.spell_name, " is not available")
		return false
	
	# Cast the spell
	available_spells.erase(spell)
	picked_spells.append(spell)
	spell_cast.emit(spell)
	print("Cast ", spell.spell_name, " (", spell.mana_cost, " mana)")
	
	# Check if deck needs refresh
	if available_spells.is_empty():
		print("All spells used! Refreshing deck...")
		refresh_deck()
	
	return true

func get_castable_spells(current_mana: int) -> Array[Spell]:
	# Return only spells the player can afford
	var castable: Array[Spell] = []
	for spell in available_spells:
		if spell.can_cast(current_mana):
			castable.append(spell)
	return castable

func get_spells_by_tier(tier: int) -> Array[Spell]:
	# Get all available spells of a specific mana cost
	var tier_spells: Array[Spell] = []
	for spell in available_spells:
		if spell.mana_cost == tier:
			tier_spells.append(spell)
	return tier_spells
