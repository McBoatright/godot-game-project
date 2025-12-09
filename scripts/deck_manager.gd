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
	
	# Tier 1 spells (1 mana) - 6 spells (enough for full river run 1)
	all_spells.append(Spell.new("Spark", 1, "damage", "Quick lightning bolt", 15, false))
	all_spells.append(Spell.new("Minor Heal", 1, "heal", "Small health recovery", 10, true))
	all_spells.append(Spell.new("Shield", 1, "buff", "Temporary defense boost", 5, true))
	all_spells.append(Spell.new("Poke", 1, "damage", "Tiny damage", 10, false))
	all_spells.append(Spell.new("Rejuvenate", 1, "heal", "Slight heal over time", 8, true))
	all_spells.append(Spell.new("Ward", 1, "buff", "Minor protection", 3, true))
	
	# Tier 2 spells (2 mana) - 6 spells (enough for river run 2)
	all_spells.append(Spell.new("Fireball", 2, "damage", "Moderate fire damage", 30))
	all_spells.append(Spell.new("Ice Shard", 2, "damage", "Cold damage with slow", 25))
	all_spells.append(Spell.new("Haste", 2, "buff", "Speed boost", 10))
	all_spells.append(Spell.new("Poison Dart", 2, "damage", "Damage over time", 20))
	all_spells.append(Spell.new("Cure", 2, "heal", "Remove debuffs", 15))
	all_spells.append(Spell.new("Fortify", 2, "buff", "Increase defense", 12))
	
	# Tier 3 spells (3 mana) - 6 spells (enough for river run 3)
	all_spells.append(Spell.new("Lightning Strike", 3, "damage", "Heavy lightning damage", 50))
	all_spells.append(Spell.new("Greater Heal", 3, "heal", "Restore significant health", 40))
	all_spells.append(Spell.new("Weaken", 3, "debuff", "Reduce enemy damage", 15))
	all_spells.append(Spell.new("Chain Lightning", 3, "damage", "Multi-target lightning", 45))
	all_spells.append(Spell.new("Restoration", 3, "heal", "Strong healing", 35))
	all_spells.append(Spell.new("Slow", 3, "debuff", "Reduce enemy speed", 10))
	
	# Tier 4 spells (4 mana) - 6 spells (enough for river run 4)
	all_spells.append(Spell.new("Meteor", 4, "damage", "Massive area damage", 70))
	all_spells.append(Spell.new("Full Barrier", 4, "buff", "Strong damage absorption", 30))
	all_spells.append(Spell.new("Drain", 4, "utility", "Steal enemy health", 35))
	all_spells.append(Spell.new("Inferno", 4, "damage", "Burning damage", 65))
	all_spells.append(Spell.new("Divine Shield", 4, "buff", "Absorb damage", 40))
	all_spells.append(Spell.new("Life Steal", 4, "utility", "Damage and heal", 30))
	
	# Tier 5 spells (5 mana) - 6 spells (enough for river run 5)
	all_spells.append(Spell.new("Annihilation", 5, "damage", "Ultimate destruction", 100))
	all_spells.append(Spell.new("Resurrection", 5, "heal", "Full health restore", 100))
	all_spells.append(Spell.new("Time Stop", 5, "utility", "Freeze all enemies", 0))
	all_spells.append(Spell.new("Apocalypse", 5, "damage", "Massive destruction", 95))
	all_spells.append(Spell.new("Full Restore", 5, "heal", "Complete recovery", 90))
	all_spells.append(Spell.new("Invincibility", 5, "buff", "Temporary immunity", 50))
	
	print("Deck initialized with ", all_spells.size(), " spells")

func refresh_deck():
	# Reset the deck - all spells become available again
	available_spells.clear()
	picked_spells.clear()
	
	for spell in all_spells:
		available_spells.append(spell)
	
	# Don't shuffle - keep tier order
	deck_refreshed.emit()
	print("=== DECK REFRESHED - All 15 spells available again! ===")

func remove_spell_from_available(spell: Spell):
	# Remove spell from available pool (picked up from river)
	if available_spells.has(spell):
		available_spells.erase(spell)
		picked_spells.append(spell)
		print("  Spells remaining in deck: ", available_spells.size(), "/15")
		
		# Auto-refresh if all spells picked
		if available_spells.is_empty():
			print("=== ALL SPELLS PICKED! Deck refreshing... ===")
			refresh_deck()

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
