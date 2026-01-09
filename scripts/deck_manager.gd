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
	# TESTING DECK: 8 Shield + 7 Fireball = 15 total
	# Shield: 3 mana, blocks 3 damage, one-time use
	# Fireball: 2 mana, projectile, reusable
	
	# 8 Shield spells (3 mana)
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	all_spells.append(Spell.new("Shield", 3, "shield", "Protects you from 3 damage. One-time use.", 3, false))
	
	# 7 Fireball spells (2 mana)
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	all_spells.append(Spell.new("Fireball", 2, "projectile", "Shoots a fireball projectile. Reusable!", 2, true))
	
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
