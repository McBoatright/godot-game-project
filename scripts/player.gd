extends CharacterBody2D

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true

var attack_ip = false
var can_take_damage = true

# Mana system
var mana = 0
var max_mana = 99  # No limit mentioned, but setting a cap for UI
const MANA_REGEN_INTERVAL = 5.0  # 5 seconds for testing (was 10.0)

# Deck system
var deck_manager
var river_manager

# Hand/Inventory system (Phantom Dust style)
const MAX_HAND_SIZE = 4  # 4 spell slots like Phantom Dust
var hand: Array = [null, null, null, null]  # 4 slots, can be null
var consumed_spells: int = 0  # Count of spells overwritten/cast (for synergy mechanics)
var slot_cooldowns: Array = [0.0, 0.0, 0.0, 0.0]  # Prevent multiple triggers

# Buff/Debuff system
var active_buffs: Array = []  # Array of {name, duration, power}
var speed_buff: float = 0.0  # Speed multiplier from buffs
var defense_buff: float = 0.0  # Damage reduction from buffs

const speed = 100
var current_dir = "none"

func _ready():
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("front_idle")
	
	# Debug: Print all children
	print("Player children:")
	for child in get_children():
		print("  - ", child.name)
	
	# Setup mana regeneration timer
	setup_mana_timer()
	
	# Initialize deck system
	setup_deck()
	
	# Initialize river system
	setup_river()
	
	# Initialize all UI
	update_mana_ui()
	update_hand_ui()
	update_river_ui()
	update_deck_progress_ui()

func _physics_process(delta):
	player_movement(delta)
	enemy_attack()
	attack()
	update_health()
	update_mana_ui()
	
	# Update slot cooldowns
	for i in range(4):
		if slot_cooldowns[i] > 0:
			slot_cooldowns[i] -= delta
	
	# Update active buffs/debuffs
	update_buffs(delta)
	
	# Button-based spell pickup AND casting (Phantom Dust style)
	# Press 1-4 to either pick up spell to that slot OR cast from that slot
	if Input.is_action_just_pressed("ui_accept"):
		# Space bar for old test
		test_cast_spell()
	
	if Input.is_action_just_pressed("ui_cancel"):
		# ESC for old orb test
		if river_manager:
			test_pick_orb()
	
	# Keys 1-4: Pick up spell to slot OR cast from slot (with cooldown to prevent spam)
	if Input.is_key_pressed(KEY_1) and slot_cooldowns[0] <= 0:
		handle_slot_action(0)
		slot_cooldowns[0] = 0.3  # 300ms cooldown
	elif Input.is_key_pressed(KEY_2) and slot_cooldowns[1] <= 0:
		handle_slot_action(1)
		slot_cooldowns[1] = 0.3
	elif Input.is_key_pressed(KEY_3) and slot_cooldowns[2] <= 0:
		handle_slot_action(2)
		slot_cooldowns[2] = 0.3
	elif Input.is_key_pressed(KEY_4) and slot_cooldowns[3] <= 0:
		handle_slot_action(3)
		slot_cooldowns[3] = 0.3
		if river_manager:
			test_pick_orb()

	if health <= 0 and player_alive:
		player_alive = false	#Add whatever it is you add when player dies
		health = 0
		print("Player has died")
		self.queue_free()

func player_movement(_delta):
	# Get input direction
	var input_x = 0
	var input_y = 0
	
	if Input.is_action_pressed("ui_right"):
		input_x = 1
	elif Input.is_action_pressed("ui_left"):
		input_x = -1
	
	if Input.is_action_pressed("ui_down"):
		input_y = 1
	elif Input.is_action_pressed("ui_up"):
		input_y = -1
	
	# Determine direction based on input
	if input_x != 0 or input_y != 0:
		# Moving
		if input_x == 1 and input_y == 0:
			current_dir = "right"
		elif input_x == -1 and input_y == 0:
			current_dir = "left"
		elif input_x == 0 and input_y == 1:
			current_dir = "down"
		elif input_x == 0 and input_y == -1:
			current_dir = "up"
		elif input_x == 1 and input_y == -1:
			current_dir = "up_right"
		elif input_x == -1 and input_y == -1:
			current_dir = "up_left"
		elif input_x == 1 and input_y == 1:
			current_dir = "down_right"
		elif input_x == -1 and input_y == 1:
			current_dir = "down_left"
		
		# Set velocity (normalized for diagonal movement)
		var direction = Vector2(input_x, input_y).normalized()
		velocity = direction * speed
		play_anim(1)
	else:
		# Not moving
		velocity = Vector2.ZERO
		play_anim(0)
	
	move_and_slide()

func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		if movement == 1:
			anim.play("side_right_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("side_right_idle")
	elif dir == "left":
		if movement == 1:
			anim.play("side_left_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("side_left_idle")
	elif dir == "down":
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("front_idle")
	elif dir == "up":
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("back_idle")
	# Diagonal directions
	elif dir == "up_right":
		if movement == 1:
			anim.play("diagonal_up_right_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("diagonal_up_right_idle")
	elif dir == "up_left":
		if movement == 1:
			anim.play("diagonal_up_left_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("diagonal_up_left_idle")
	elif dir == "down_right":
		if movement == 1:
			anim.play("diagonal_down_right_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("diagonal_down_right_idle")
	elif dir == "down_left":
		if movement == 1:
			anim.play("diagonal_down_left_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("diagonal_down_left_idle")    

func player():
	pass # Replace with function body.    


func _on_player_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = true

func _on_player_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false

func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown == true:
		health = health - 20
		enemy_attack_cooldown = false
		$player_hitbox/attack_cooldown.start()
		print(health)


func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true


func attack():
	var dir = current_dir

	if Input.is_action_just_pressed("attack"):
		Global.player_current_attack = true 
		attack_ip = true
		if dir == "right":
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.play("side_attack")
			if $deal_attack_timer:
				$deal_attack_timer.start()
		if dir == "left":
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("side_attack")
			if $deal_attack_timer:
				$deal_attack_timer.start()
		if dir == "down":
			$AnimatedSprite2D.play("front_attack")
			if $deal_attack_timer:
				$deal_attack_timer.start()
		if dir == "up":
			$AnimatedSprite2D.play("back_attack")
			if $deal_attack_timer:
				$deal_attack_timer.start()
			

func _on_deal_attack_timer_timeout():
	$deal_attack_timer.stop()
	Global.player_current_attack = false
	attack_ip = false




func update_health():
	var healthbar = get_node_or_null("ProgressBar")
	if healthbar:
		healthbar.value = health
		
		if health >= 100:
			healthbar.visible = false
		else:
			healthbar.visible = true





func _on_regin_timer_timeout():
	if health < 100:
		health = health + 20
		if health > 100:
			health = 100
	if health <= 0:
		health = 0


# ===== MANA SYSTEM =====

func setup_mana_timer():
	# Create a timer for mana regeneration
	var mana_timer = Timer.new()
	mana_timer.name = "ManaTimer"
	mana_timer.wait_time = MANA_REGEN_INTERVAL
	mana_timer.autostart = true
	mana_timer.one_shot = false
	add_child(mana_timer)
	mana_timer.timeout.connect(_on_mana_timer_timeout)

func _on_mana_timer_timeout():
	# Add 1 mana every 10 seconds
	if mana < max_mana:
		mana += 1
		print("Mana regenerated! Current mana: ", mana)

func update_mana_ui():
	# Find HUD dynamically from the scene tree
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		print("WARNING: HUD CanvasLayer not found in scene tree")
		return
	
	# Try to find mana_label under HUD
	var mana_label = hud.find_child("mana_label", true, false)
	
	if mana_label:
		mana_label.text = "Mana: " + str(mana)
	else:
		print("WARNING: mana_label not found under HUD")

# ===== DECK SYSTEM =====

func setup_deck():
	# Create and initialize the deck manager
	deck_manager = DeckManager.new()
	deck_manager.name = "DeckManager"
	add_child(deck_manager)
	
	# Connect signals
	deck_manager.deck_refreshed.connect(_on_deck_refreshed)
	deck_manager.spell_cast.connect(_on_spell_cast)
	
	print("Deck system initialized!")

func _on_deck_refreshed():
	print("DECK REFRESHED - All 15 spells available again!")

func _on_spell_cast(spell):
	print("SPELL CAST: ", spell.spell_name, " for ", spell.power, " ", spell.effect_type)
	# This is where spell effects will be applied
	# For now, just deduct the mana cost
	mana -= spell.mana_cost
	update_mana_ui()

func test_cast_spell():
	# Test function to cast a random affordable spell
	var castable = deck_manager.get_castable_spells(mana)
	if castable.size() > 0:
		var spell = castable[0]
		if deck_manager.cast_spell(spell, mana):
			print("Successfully cast ", spell.spell_name)
		else:
			print("Failed to cast spell")
	else:
		print("No castable spells available (need more mana)")

# ===== RIVER SYSTEM =====

func setup_river():
	# Create and initialize the river manager
	var RiverManager = load("res://scripts/river_manager.gd")
	river_manager = RiverManager.new()
	river_manager.name = "RiverManager"
	add_child(river_manager)
	
	# Connect deck manager to river
	river_manager.set_deck_manager(deck_manager)
	
	# Connect world node for spawning visual orbs
	var world = get_parent()
	if world:
		river_manager.set_world_node(world)
	else:
		print("WARNING: World node not found in setup_river!")
	
	# Connect signals
	river_manager.river_refreshed.connect(_on_river_refreshed)
	river_manager.orb_picked.connect(_on_orb_picked)
	river_manager.river_run_complete.connect(_on_river_run_complete)
	river_manager.timer_updated.connect(_on_river_timer_updated)
	
	# Delay river start to next frame to ensure world is ready
	await get_tree().process_frame
	
	# Start first river run (run 0 = 1-cost only)
	river_manager.start_river_run(0)
	
	print("River system initialized!")

func _on_river_refreshed(run_number: int):
	print("RIVER REFRESHED - Run ", run_number + 1, "/5 ready!")
	update_river_ui()

func _on_orb_picked(orb_index: int, spell: Spell, is_player: bool):
	if is_player:
		print("Player picked orb ", orb_index, ": ", spell.spell_name)
		update_deck_progress_ui()
	else:
		print("Opponent picked orb ", orb_index)

func _on_river_run_complete(run_number: int):
	print("RIVER RUN COMPLETE - Run ", run_number + 1, " ended. Next run starting...")
	update_river_ui()

func _on_river_timer_updated(time_left: float):
	# Find HUD dynamically
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	
	# Update river timer UI
	var timer_label = hud.find_child("river_timer_label", true, false)
	if timer_label:
		timer_label.text = str(int(time_left)) + "s"

func test_pick_orb():
	# Test function to pick the first available player orb
	var player_orbs = river_manager.get_player_orbs()
	if player_orbs.size() > 0:
		var orb = player_orbs[0]
		var spell = river_manager.pick_orb(orb.index, true)
		if spell:
			print("Picked up: ", spell.spell_name, " (Cost: ", spell.mana_cost, ")")
	else:
		print("No player orbs available to pick!")

# ===== HAND/INVENTORY SYSTEM (PHANTOM DUST STYLE) =====

func handle_slot_action(slot_index: int):
	# Unified function: Pick up spell to slot OR cast from slot
	# Priority: If player is near orbs, pick up. Otherwise, cast.
	
	# Check if player is near any orbs
	var nearby_orb = find_nearby_orb()
	if nearby_orb:
		# Player is near an orb - PICK UP mode
		pickup_nearby_orb(nearby_orb, slot_index)
		return
	
	# No orbs nearby - CAST mode
	cast_spell_from_slot(slot_index)

func find_nearby_orb():
	# Find a player orb that the player is standing near
	if not river_manager:
		return null
	
	var orbs = get_tree().get_nodes_in_group("spell_orbs")
	for orb in orbs:
		if orb.has_method("is_player_near") and orb.is_player_near() and orb.is_player_orb:
			return orb
	return null

func pickup_nearby_orb(orb, slot_index: int):
	# Pick up the orb and assign to slot
	if orb and orb.spell and river_manager:
		var spell = river_manager.pick_orb(orb.orb_index, true)
		if spell:
			assign_spell_to_slot(slot_index, spell)
			orb.queue_free()  # Remove orb from world

func assign_spell_to_slot(slot_index: int, spell: Spell):
	if slot_index < 0 or slot_index >= MAX_HAND_SIZE:
		return
	
	# Check if slot already has a spell (overwrite = consume)
	if hand[slot_index] != null:
		var old_spell = hand[slot_index]
		consumed_spells += 1
		print("CONSUMED: ", old_spell.spell_name, " (Total consumed: ", consumed_spells, ")")
	
	# Assign new spell to slot
	hand[slot_index] = spell
	print("ASSIGNED to slot [", slot_index + 1, "]: ", spell.spell_name, " (", spell.mana_cost, " mana)")
	print_hand()
	update_hand_ui()

func cast_spell_from_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_HAND_SIZE:
		return false
	
	var spell = hand[slot_index]
	if spell == null:
		print("Slot [", slot_index + 1, "] is empty!")
		return false
	
	# Check if player has enough mana
	if not spell.can_cast(mana):
		print("Not enough mana! Need ", spell.mana_cost, ", have ", mana)
		return false
	
	# Cast the spell
	mana -= spell.mana_cost
	
	# Check if spell is reusable or consumable
	if spell.is_reusable:
		# Reusable spell - stays in hand
		print("CAST (reusable) from slot [", slot_index + 1, "]: ", spell.spell_name, " (", spell.effect_type, ", power: ", spell.power, ")")
	else:
		# Consumable spell - remove from hand
		hand[slot_index] = null
		consumed_spells += 1
		print("CAST (consumed) from slot [", slot_index + 1, "]: ", spell.spell_name, " (", spell.effect_type, ", power: ", spell.power, ")")
		print("  Spells consumed this match: ", consumed_spells)
	
	apply_spell_effect(spell)
	update_mana_ui()
	update_hand_ui()
	print_hand()
	
	return true

func add_spell_to_hand(spell: Spell) -> bool:
	# Legacy function - find first empty slot
	for i in range(MAX_HAND_SIZE):
		if hand[i] == null:
			assign_spell_to_slot(i, spell)
			return true
	
	print("Hand is full! Use buttons 1-4 to overwrite a slot.")
	return false

func cast_spell_from_hand(slot_index: int) -> bool:
	# Legacy function - redirects to new system
	return cast_spell_from_slot(slot_index)

func apply_spell_effect(spell: Spell):
	# Apply the spell effect based on type
	match spell.effect_type:
		"damage":
			apply_damage_spell(spell)
		"heal":
			apply_heal_spell(spell)
		"buff":
			apply_buff_spell(spell)
		"debuff":
			apply_debuff_spell(spell)
		"utility":
			apply_utility_spell(spell)

func apply_damage_spell(spell: Spell):
	# Find nearest enemy and deal damage
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		print("  -> No enemies to damage!")
		return
	
	# Find closest enemy
	var nearest_enemy = null
	var nearest_distance = 999999.0
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy and nearest_enemy.has_method("take_spell_damage"):
		nearest_enemy.take_spell_damage(spell.power)
		print("  -> ", spell.spell_name, " dealt ", spell.power, " damage to enemy!")
	else:
		print("  -> Could not damage enemy")

func apply_heal_spell(spell: Spell):
	# Heal the player
	var old_health = health
	health = min(health + spell.power, 100)
	var healed = health - old_health
	print("  -> ", spell.spell_name, " healed ", healed, " health!")
	update_health()

func apply_buff_spell(spell: Spell):
	# Apply a buff to the player
	var buff_duration = 10.0  # 10 seconds
	
	match spell.spell_name:
		"Shield", "Ward", "Full Barrier", "Divine Shield":
			# Defense buffs
			defense_buff += spell.power
			active_buffs.append({"name": spell.spell_name, "duration": buff_duration, "type": "defense", "power": spell.power})
			print("  -> ", spell.spell_name, " increased defense by ", spell.power, " for ", buff_duration, "s!")
		"Haste":
			# Speed buff
			speed_buff += spell.power / 100.0  # Convert to multiplier
			active_buffs.append({"name": spell.spell_name, "duration": buff_duration, "type": "speed", "power": spell.power})
			print("  -> ", spell.spell_name, " increased speed by ", spell.power, "% for ", buff_duration, "s!")
		_:
			# Generic buff
			active_buffs.append({"name": spell.spell_name, "duration": buff_duration, "type": "generic", "power": spell.power})
			print("  -> Applied ", spell.spell_name, " buff!")

func apply_debuff_spell(spell: Spell):
	# Apply debuff to nearest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		print("  -> No enemies to debuff!")
		return
	
	# Find closest enemy
	var nearest_enemy = null
	var nearest_distance = 999999.0
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy:
		print("  -> Applied ", spell.spell_name, " debuff to enemy!")
		# TODO: Implement enemy debuff system

func apply_utility_spell(spell: Spell):
	# Apply utility effect
	match spell.spell_name:
		"Drain", "Life Steal":
			# Damage enemy and heal player
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 0:
				var nearest_enemy = enemies[0]
				if nearest_enemy.has_method("take_spell_damage"):
					nearest_enemy.take_spell_damage(spell.power)
					health = min(health + spell.power / 2, 100)  # Heal for half damage dealt
					print("  -> ", spell.spell_name, " dealt ", spell.power, " damage and healed ", spell.power / 2, "!")
					update_health()
		_:
			print("  -> Used ", spell.spell_name, "!")

func update_buffs(delta: float):
	# Update all active buffs, remove expired ones
	var i = 0
	while i < active_buffs.size():
		var buff = active_buffs[i]
		buff.duration -= delta
		
		if buff.duration <= 0:
			# Buff expired - remove its effects
			if buff.type == "defense":
				defense_buff -= buff.power
			elif buff.type == "speed":
				speed_buff -= buff.power / 100.0
			
			print("Buff '", buff.name, "' expired!")
			active_buffs.remove_at(i)
		else:
			i += 1

func print_hand():
	print("=== HAND [Consumed: ", consumed_spells, "] ===")
	for i in range(MAX_HAND_SIZE):
		var spell = hand[i]
		if spell:
			print("  [", i + 1, "] ", spell.spell_name, " - ", spell.mana_cost, " mana")
		else:
			print("  [", i + 1, "] (empty)")
	print("=====================")

func update_hand_ui():
	# Find HUD dynamically
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	
	# Update hand UI labels
	for i in range(MAX_HAND_SIZE):
		var label_name = "hand_slot_" + str(i + 1)
		var label = hud.find_child(label_name, true, false)
		if label:
			var spell = hand[i]
			if spell:
				label.text = "[" + str(i + 1) + "] " + spell.spell_name + " (" + str(spell.mana_cost) + ")"
				label.visible = true
			else:
				label.text = "[" + str(i + 1) + "] Empty"
				label.visible = true

func update_river_ui():
	# Find HUD dynamically
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	
	# Update river run indicator
	if river_manager:
		var run_label = hud.find_child("river_run_label", true, false)
		if run_label:
			var current_run = river_manager.current_run
			run_label.text = "Run " + str(current_run + 1) + "/5"

func update_deck_progress_ui():
	# Find HUD dynamically
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	
	# Update deck progress
	if deck_manager:
		var progress_label = hud.find_child("deck_progress_label", true, false)
		if progress_label:
			var total = deck_manager.all_spells.size()
			var available = deck_manager.available_spells.size()
			progress_label.text = "Deck: " + str(available) + "/" + str(total)
