extends Resource
class_name DeckConfig

# A saved deck configuration
@export var deck_name: String = "New Deck"
@export var spell_names: Array[String] = []  # List of spell names in this deck

func _init(name: String = "New Deck"):
	deck_name = name
	spell_names = []

func add_spell(spell_name: String) -> void:
	spell_names.append(spell_name)

func remove_spell(spell_name: String) -> void:
	spell_names.erase(spell_name)

func get_spell_count() -> int:
	return spell_names.size()

func clear() -> void:
	spell_names.clear()

func duplicate_deck() -> DeckConfig:
	var new_deck = DeckConfig.new(deck_name + " (Copy)")
	for spell_name in spell_names:
		new_deck.add_spell(spell_name)
	return new_deck
