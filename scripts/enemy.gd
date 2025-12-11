extends CharacterBody2D

var speed = 40
var player_chase = false
var player = null
var last_direction = Vector2.ZERO  # Track last movement direction for idle animations

var health = 20
var player_inattack_zone = false
var can_take_damage = true

# AI Spell System
var current_mana = 0  # Available mana to spend
var max_mana = 0  # Maximum mana accumulated over time
const MAX_MANA_CAP = 99  # Hard cap
const MAX_MANA_ACCUMULATE_INTERVAL = 5.0  # Max mana grows by 1 every 5 seconds
const CURRENT_MANA_REGEN_INTERVAL = 1.0  # Current mana regenerates 1 per second
var hand: Array = [null, null]  # 2 spell slots for AI
var river_manager = null
var ai_pickup_timer = 0.0
var ai_cast_timer = 0.0
var max_mana_timer = 0.0  # Timer for max mana accumulation
var current_mana_timer = 0.0  # Timer for current mana regen
const AI_PICKUP_INTERVAL = 8.0  # Pick up orb every 8 seconds
const AI_CAST_INTERVAL = 3.0  # Try to cast every 3 seconds

# AI Shield system
var shield_health: int = 0
var shield_visual = null

func _ready():
	# Add to enemies group so spells can find us
	add_to_group("enemies")
	
	# Find river manager
	await get_tree().process_frame
	var world = get_parent()
	print("AI: World parent: ", world)
	if world:
		# Try both "Player" and "player" (case sensitive)
		var player_node = world.get_node_or_null("player")
		if not player_node:
			player_node = world.get_node_or_null("Player")
		
		print("AI: Player node: ", player_node)
		if player_node:
			river_manager = player_node.get_node_or_null("RiverManager")
			print("AI: RiverManager: ", river_manager)
			if river_manager:
				print("Enemy AI connected to river system!")
			else:
				print("ERROR: AI could not find RiverManager as child of player")
		else:
			print("ERROR: AI could not find player node in world")
	
	# Start with 0 mana (will accumulate over time)
	current_mana = 0
	max_mana = 0
	
	# Start with default animation
	$AnimatedSprite2D.play("front_idle")


func _physics_process(delta):
	deal_with_damage()
	
	# AI mana system
	max_mana_timer += delta
	current_mana_timer += delta
	
	# Accumulate max mana every 5 seconds
	if max_mana_timer >= MAX_MANA_ACCUMULATE_INTERVAL and max_mana < MAX_MANA_CAP:
		max_mana += 1
		max_mana_timer = 0.0
		print("AI max mana increased! Max: ", max_mana, " Current: ", current_mana)
	
	# Regenerate current mana every 1 second
	if current_mana_timer >= CURRENT_MANA_REGEN_INTERVAL and current_mana < max_mana:
		current_mana += 1
		current_mana_timer = 0.0
		print("AI mana regenerated! Current: ", current_mana, "/", max_mana)
	
	# AI spell system
	ai_pickup_timer += delta
	ai_cast_timer += delta
	
	# Try to pick up red orbs periodically
	if ai_pickup_timer >= AI_PICKUP_INTERVAL:
		if river_manager:
			print("AI: Trying to pick up orb...")
			ai_try_pickup_orb()
		else:
			print("AI: No river manager connected!")
		ai_pickup_timer = 0.0
	
	# Try to cast spells periodically
	if ai_cast_timer >= AI_CAST_INTERVAL:
		print("AI: Trying to cast spell... Hand: ", hand, " Mana: ", current_mana, "/", max_mana)
		ai_try_cast_spell()
		ai_cast_timer = 0.0

	# AI movement priority: orbs > player
	var moving = false
	var target_position = null
	
	# Try to move toward nearest opponent orb first
	if river_manager:
		var nearest_orb = ai_find_nearest_opponent_orb()
		if nearest_orb:
			target_position = nearest_orb.global_position
			moving = true
	
	# If no orb, move toward player
	if not moving and player_chase:
		target_position = player.position
		moving = true
	
	if moving and target_position:
		# Move using the original working code
		var direction = (target_position - position).normalized()
		var distance_to_target = position.distance_to(target_position)
		
		# Only move if we're not already at the target
		if distance_to_target > 5.0:  # Stop within 5 pixels of target
			position += (target_position - position) / speed
			last_direction = direction  # Save direction for idle animation
			
			# Update animation based on movement direction (8-directional)
			var angle_threshold = 0.4  # Threshold for diagonal detection
			
			# Determine if movement is more diagonal or cardinal
			if abs(direction.x) > angle_threshold and abs(direction.y) > angle_threshold:
				# Diagonal movement
				if direction.x > 0 and direction.y < 0:
					$AnimatedSprite2D.play("diagonal_up_right_walk")
				elif direction.x < 0 and direction.y < 0:
					$AnimatedSprite2D.play("diagonal_up_left_walk")
				elif direction.x > 0 and direction.y > 0:
					$AnimatedSprite2D.play("diagonal_down_right_walk")
				elif direction.x < 0 and direction.y > 0:
					$AnimatedSprite2D.play("diagonal_down_left_walk")
			else:
				# Cardinal movement
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						$AnimatedSprite2D.play("side_right_walk")
					else:
						$AnimatedSprite2D.play("side_left_walk")
				else:
					if direction.y > 0:
						$AnimatedSprite2D.play("front_walk")
					else:
						$AnimatedSprite2D.play("back_walk")
		else:
			# At target - play idle animation
			play_idle_animation()
	else:
		# Not moving - play idle animation
		play_idle_animation()

func play_idle_animation():
	# Determine idle animation based on last movement direction
	if last_direction == Vector2.ZERO:
		$AnimatedSprite2D.play("front_idle")
		return
	
	var angle_threshold = 0.4
	
	# Check for diagonal idle
	if abs(last_direction.x) > angle_threshold and abs(last_direction.y) > angle_threshold:
		if last_direction.x > 0 and last_direction.y < 0:
			$AnimatedSprite2D.play("diagonal_up_right_idle")
		elif last_direction.x < 0 and last_direction.y < 0:
			$AnimatedSprite2D.play("diagonal_up_left_idle")
		elif last_direction.x > 0 and last_direction.y > 0:
			$AnimatedSprite2D.play("diagonal_down_right_idle")
		elif last_direction.x < 0 and last_direction.y > 0:
			$AnimatedSprite2D.play("diagonal_down_left_idle")
	else:
		# Cardinal idle
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				$AnimatedSprite2D.play("side_right_idle")
			else:
				$AnimatedSprite2D.play("side_left_idle")
		else:
			if last_direction.y > 0:
				$AnimatedSprite2D.play("front_idle")
			else:
				$AnimatedSprite2D.play("back_idle")

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(_body: Node2D) -> void:
	player = null
	player_chase = false


# Removed enemy() function so AI doesn't damage player on touch
# AI only damages through spells


func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false


func deal_with_damage():
	if player_inattack_zone and Global.player_current_attack == true:
		if can_take_damage == true:
			health = health - 1
			can_take_damage = false
			$take_damage_cooldown.start()
			print("AI enemy health = ", health, "/20")
			if health <= 0:
				self.queue_free()

func _on_take_damage_cooldown_timeout():
	can_take_damage = true

func take_spell_damage(damage: int):
	# Check shield first
	if shield_health > 0:
		var damage_to_shield = min(damage, shield_health)
		shield_health -= damage_to_shield
		damage -= damage_to_shield
		print("Enemy shield blocked ", damage_to_shield, " damage! Shield: ", shield_health)
		
		if shield_health <= 0:
			print("Enemy shield broken!")
			remove_shield_visual()
			shield_health = 0
	
	# Apply remaining damage to health
	if damage > 0:
		health -= damage
		print("Enemy took ", damage, " spell damage! Health: ", health, "/20")
	
	if health <= 0:
		print("Enemy defeated!")
		queue_free()

# AI Spell Functions
func ai_find_nearest_opponent_orb():
	# Find all opponent orbs and return the closest one
	var all_orbs = get_tree().get_nodes_in_group("spell_orbs")
	var nearest_orb = null
	var nearest_distance = 999999.0
	
	for orb in all_orbs:
		if orb.has_method("update_visual") and not orb.is_player_orb and orb.spell != null:
			var distance = global_position.distance_to(orb.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_orb = orb
	
	return nearest_orb

func ai_try_pickup_orb():
	if not river_manager:
		print("AI: No river manager!")
		return
	
	# Find all SpellOrb nodes in the world (in spell_orbs group)
	var all_orbs = get_tree().get_nodes_in_group("spell_orbs")
	var available_orbs = []
	
	for orb in all_orbs:
		# Check if it's an opponent orb (is_player_orb == false means red/opponent)
		if orb.has_method("update_visual") and not orb.is_player_orb and orb.spell != null:
			available_orbs.append(orb)
	
	if available_orbs.is_empty():
		print("AI: No opponent orbs available")
		return
	
	# Find nearest orb
	var nearest_orb = ai_find_nearest_opponent_orb()
	if not nearest_orb:
		print("AI: No nearest orb found")
		return
	
	# Check if close enough to pick up (within 30 pixels)
	var distance = global_position.distance_to(nearest_orb.global_position)
	if distance > 30.0:
		print("AI: Orb too far (distance: ", distance, ")")
		return
	
	var spell_data = nearest_orb.spell
	
	# Add to hand if there's room
	for i in range(hand.size()):
		if hand[i] == null:
			hand[i] = spell_data
			print("Enemy AI picked up: ", spell_data.spell_name, " (", spell_data.mana_cost, " mana)")
			# Pick the orb from river (marks it as picked)
			river_manager.pick_orb(nearest_orb.orb_index, false)  # false = opponent orb
			# Remove the visual orb
			nearest_orb.queue_free()
			return
	
	print("Enemy AI hand full, can't pick up orb")

func ai_try_cast_spell():
	# Find a spell we can cast
	for i in range(hand.size()):
		var spell = hand[i]
		if spell != null:
			print("AI: Checking spell slot ", i, ": ", spell.spell_name, " costs ", spell.mana_cost, " (have ", current_mana, ")")
			if current_mana >= spell.mana_cost:
				# Cast the spell
				print("AI: Casting spell from slot ", i)
				ai_cast_spell(spell, i)
				return
			else:
				print("AI: Not enough mana to cast ", spell.spell_name)

func ai_cast_spell(spell: Spell, hand_index: int):
	# Spend mana
	current_mana -= spell.mana_cost
	print("Enemy AI casting: ", spell.spell_name, " (", spell.effect_type, ") - Mana: ", current_mana, "/", max_mana)
	
	# Apply spell effect based on type
	if spell.effect_type == "projectile":
		ai_cast_fireball(spell)
	elif spell.effect_type == "shield":
		ai_apply_shield(spell)
	
	# Remove from hand
	hand[hand_index] = null

func ai_cast_fireball(spell: Spell):
	# Find player in world if we don't have reference
	if player == null:
		var world = get_parent()
		if world:
			player = world.get_node_or_null("player")
			if not player:
				player = world.get_node_or_null("Player")
	
	if player == null:
		print("AI: Cannot cast Fireball - no player found in world!")
		return
	
	print("AI: Creating Fireball projectile...")
	var ProjectileScene = preload("res://scenes/projectile.tscn")
	var projectile = ProjectileScene.instantiate()
	get_parent().add_child(projectile)
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	# Spawn projectile offset from AI center so it doesn't hit own hitbox
	var spawn_offset = direction * 20.0  # 20 pixels in front of AI
	projectile.setup(global_position + spawn_offset, direction, spell.power, self)
	print("Enemy AI fired Fireball projectile at player! Damage: ", spell.power)

func ai_apply_shield(spell: Spell):
	shield_health = spell.power
	print("Enemy AI activated shield! Shield health: ", shield_health)
	spawn_shield_visual()

func spawn_shield_visual():
	if shield_visual:
		return
	
	# Create a blue circle as shield visual
	shield_visual = ColorRect.new()
	shield_visual.color = Color(0.3, 0.3, 1.0, 0.3)  # Blue semi-transparent
	shield_visual.size = Vector2(40, 40)
	shield_visual.position = Vector2(-20, -20)  # Center it
	shield_visual.z_index = -1  # Behind the sprite
	add_child(shield_visual)
	print("AI: Shield visual created!")

func remove_shield_visual():
	if shield_visual:
		shield_visual.queue_free()
		shield_visual = null
