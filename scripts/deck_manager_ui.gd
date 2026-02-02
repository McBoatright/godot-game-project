extends Control

# References to UI elements
@onready var deck_list = $MarginContainer/HBoxContainer/LeftPanel/DeckList
@onready var spell_collection = $MarginContainer/HBoxContainer/RightPanel/ScrollContainer/SpellGrid
@onready var deck_name_label = $MarginContainer/HBoxContainer/LeftPanel/DeckNameLabel
@onready var back_button = $BackButton

# Current state
var owned_spells: Dictionary = {}  # spell_name: count
var current_deck: DeckConfig = null
var all_decks: Array[DeckConfig] = []

func _ready():
	# Initialize with test data
	setup_owned_spells()
	setup_default_deck()
	refresh_ui()
	
	# Connect button
	back_button.pressed.connect(_on_back_button_pressed)

func setup_owned_spells():
	# For now, player owns 8 Shield and 7 Fireball
	owned_spells["Shield"] = 8
	owned_spells["Fireball"] = 7

func setup_default_deck():
	# Create the default "Test Deck"
	var test_deck = DeckConfig.new("Test Deck")
	
	# Add 8 Shield spells
	for i in range(8):
		test_deck.add_spell("Shield")
	
	# Add 7 Fireball spells
	for i in range(7):
		test_deck.add_spell("Fireball")
	
	all_decks.append(test_deck)
	current_deck = test_deck

func refresh_ui():
	refresh_deck_list()
	refresh_spell_collection()
	update_deck_name()

func refresh_deck_list():
	# Clear existing deck buttons
	for child in deck_list.get_children():
		child.queue_free()
	
	# Create buttons for each deck
	for deck in all_decks:
		var button = Button.new()
		button.text = deck.deck_name + " (" + str(deck.get_spell_count()) + " cards)"
		button.pressed.connect(_on_deck_selected.bind(deck))
		
		# Highlight current deck
		if deck == current_deck:
			button.modulate = Color(0.7, 1.0, 0.7)
		
		deck_list.add_child(button)

func refresh_spell_collection():
	# Clear existing spell cards
	for child in spell_collection.get_children():
		child.queue_free()
	
	# Display each owned spell type
	for spell_name in owned_spells.keys():
		var count = owned_spells[spell_name]
		var spell_card = create_spell_card(spell_name, count)
		spell_collection.add_child(spell_card)

func create_spell_card(spell_name: String, count: int) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 100)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Spell name
	var name_label = Label.new()
	name_label.text = spell_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Count owned
	var count_label = Label.new()
	count_label.text = "Owned: " + str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(count_label)
	
	# Count in current deck
	if current_deck:
		var in_deck = current_deck.spell_names.count(spell_name)
		var deck_label = Label.new()
		deck_label.text = "In deck: " + str(in_deck)
		deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(deck_label)
	
	# Add/Remove buttons
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	var add_button = Button.new()
	add_button.text = "+"
	add_button.pressed.connect(_on_add_spell_to_deck.bind(spell_name))
	button_hbox.add_child(add_button)
	
	var remove_button = Button.new()
	remove_button.text = "-"
	remove_button.pressed.connect(_on_remove_spell_from_deck.bind(spell_name))
	button_hbox.add_child(remove_button)
	
	return card

func update_deck_name():
	if current_deck:
		deck_name_label.text = "Editing: " + current_deck.deck_name

func _on_deck_selected(deck: DeckConfig):
	current_deck = deck
	refresh_ui()

func _on_add_spell_to_deck(spell_name: String):
	if not current_deck:
		return
	
	# Check if player owns this spell and hasn't used all copies
	var owned_count = owned_spells.get(spell_name, 0)
	var in_deck_count = current_deck.spell_names.count(spell_name)
	
	if in_deck_count < owned_count:
		current_deck.add_spell(spell_name)
		refresh_ui()
		print("Added ", spell_name, " to deck")
	else:
		print("Can't add more - you only own ", owned_count, " copies")

func _on_remove_spell_from_deck(spell_name: String):
	if not current_deck:
		return
	
	if spell_name in current_deck.spell_names:
		current_deck.remove_spell(spell_name)
		refresh_ui()
		print("Removed ", spell_name, " from deck")

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
