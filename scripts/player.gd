extends CharacterBody2D

const DeckManager = preload("res://scripts/deck_manager.gd")

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true

var attack_ip = false
var can_take_damage = true

# Mana system
var mana = 0
var max_mana = 99  # No limit mentioned, but setting a cap for UI
const MANA_REGEN_INTERVAL = 10.0  # Seconds between mana regeneration

# Deck system
var deck_manager: DeckManager

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
	
	# Initialize mana display
	update_mana_ui()

func _physics_process(delta):
	player_movement(delta)
	enemy_attack()
	attack()
	update_health()
	update_mana_ui()
	
	# Test spell casting with 'E' key
	if Input.is_action_just_pressed("ui_accept"):  # Space bar
		test_cast_spell()

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
	var mana_label = get_node_or_null("mana_label")
	if mana_label:
		mana_label.text = "Mana: " + str(mana)
	else:
		print("WARNING: mana_label not found!")

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
