extends Area2D

# Reference to the spell this orb contains
var spell: Spell = null
var is_player_orb: bool = true  # true = player can pick, false = opponent orb
var orb_index: int = 0

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

# Colors for different orb types
const PLAYER_ORB_COLOR = Color(0.3, 0.7, 1.0, 0.8)  # Light blue
const OPPONENT_ORB_COLOR = Color(1.0, 0.3, 0.3, 0.8)  # Red

func _ready():
	# Add to spell_orbs group for easy finding
	add_to_group("spell_orbs")
	
	# Connect pickup signal
	body_entered.connect(_on_body_entered)
	
	# Set visual appearance
	update_visual()

func setup(p_spell: Spell, p_is_player_orb: bool, p_index: int):
	spell = p_spell
	is_player_orb = p_is_player_orb
	orb_index = p_index
	
	if is_node_ready():
		update_visual()

func update_visual():
	if not spell:
		return
	
	# Set orb color based on who can pick it up
	var orb_color = PLAYER_ORB_COLOR if is_player_orb else OPPONENT_ORB_COLOR
	
	if sprite:
		sprite.modulate = orb_color
	
	if color_rect:
		color_rect.color = orb_color
	
	# Display spell info
	if label:
		label.text = spell.spell_name + " (" + str(spell.mana_cost) + ")"

func _on_body_entered(_body: Node2D):
	# Don't auto-pickup - player must press button near orb
	# Just track that player is nearby
	pass

func is_player_near() -> bool:
	# Check if player is within pickup range
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("player"):
			return true
	return false

func pickup_orb(player):
	# Player is now standing near the orb - add spell to first empty slot
	if player.has_method("add_spell_to_hand") and spell:
		# Tell river manager this orb was picked
		var river_manager = player.get_node_or_null("RiverManager")
		if river_manager:
			var picked_spell = river_manager.pick_orb(orb_index, true)
			if picked_spell:
				# Successfully picked from river - add to hand
				player.add_spell_to_hand(picked_spell)
				# Remove this orb from the world
				queue_free()
