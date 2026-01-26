extends CharacterBody2D

# Preload item drop scene
var item_drop_scene = preload("res://scenes/item_drop.tscn")

var speed = 40
var player_chase = false
var player = null
var target = null  # Can be player or AI enemy

var health = 2
var max_health = 2
var player_inattack_zone = false
var target_inattack_zone = false  # Track if any target (player or AI) is in attack zone
var can_take_damage = true
var last_attack_state = false  # Track previous frame's attack state

var initial_position: Vector2
var is_dead = false
var respawn_timer: Timer
var attack_timer: Timer
var attack_cooldown = 2.0  # Attack every 2 seconds

func _ready():
	# Add to enemies group so spells can find us
	add_to_group("enemies")
	
	# Store initial spawn position
	initial_position = global_position
	
	# Create respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 10.0
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)
	
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	attack_timer.start()

func _physics_process(_delta):
	if is_dead:
		return
		
	deal_with_damage()

	if player_chase and target:
		position += (target.position - position)/speed

		$AnimatedSprite2D.play("walk")

		if(target.position.x - position.x) > 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.play("idle")



func _on_detection_area_body_entered(body: Node2D) -> void:
	# Chase either player or AI enemy
	if body.name == "player" or body.name == "ai_enemy":
		target = body
		player = body  # Keep for compatibility
		player_chase = true
		print("Slime targeting: ", body.name)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		player = null
		target = null
		player_chase = false


func enemy():
	pass # Replace with function body.	


func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	print("[DEBUG] enemy_hitbox_body_entered - body name:", body.name, " has player method:", body.has_method("player"))
	if body.has_method("player"):
		player_inattack_zone = true
		target_inattack_zone = true
		print("Player entered slime attack zone!")
	elif body.name == "ai_enemy":
		target_inattack_zone = true
		print("AI enemy entered slime attack zone!")

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	print("[DEBUG] enemy_hitbox_body_exited - body name:", body.name)
	if body.has_method("player"):
		player_inattack_zone = false
		target_inattack_zone = false
		print("Player left slime attack zone!")
	elif body.name == "ai_enemy":
		target_inattack_zone = false
		print("AI enemy left slime attack zone!")


func deal_with_damage():
	# Only take damage when player STARTS attacking (transition from false to true)
	if player_inattack_zone:
		# Check if this is a NEW attack (transition from false to true)
		if Global.player_current_attack == true and last_attack_state == false:
			if can_take_damage == true:
				print("[DEBUG] Slime taking damage from player - NEW ATTACK DETECTED")
				health = health - 1
				can_take_damage = false
				$take_damage_cooldown.start()
				print("slime health = ", health, "/2")
				if health <= 0:
					die()
	
	# Update last attack state for next frame
	last_attack_state = Global.player_current_attack
				
func attack_target():
	# Deal damage to whoever the slime is attacking
	if target == null:
		print("[DEBUG] attack_target: target is null")
		return
		
	print("[DEBUG] attack_target called - target_inattack_zone:", target_inattack_zone, " target:", target.name)
	if target_inattack_zone and target:
		print("[DEBUG] Target name:", target.name)
		print("[DEBUG] Has 'player' method:", target.has_method("player"))
		print("[DEBUG] Has 'take_spell_damage' method:", target.has_method("take_spell_damage"))
		
		if target.has_method("player"):
			# Attacking human player - use Global system
			if Global.player_current_attack == false:
				Global.player_current_attack = true
				print("Slime attacked player!")
		elif target.has_method("take_spell_damage"):
			# Attacking AI enemy - deal direct damage
			print("[DEBUG] Calling take_spell_damage(1) on:", target.name)
			target.take_spell_damage(1)
			print("Slime dealt 1 damage to AI enemy!")
		else:
			print("[DEBUG] Target has neither 'player' nor 'take_spell_damage' method!")
	else:
		print("[DEBUG] target_inattack_zone is false or target is null")

func _on_take_damage_cooldown_timeout():
	can_take_damage = true

func take_spell_damage(damage: int):
	# Take damage from player spells
	health -= damage
	print("Slime took ", damage, " spell damage! Health: ", health, "/2")
	
	if health <= 0:
		print("Slime defeated!")
		die()

func drop_item():
	# Spawn a random item at the slime's position
	var item_types = ["item1", "item2", "item3"]
	var random_index = randi() % 3
	var random_item = item_types[random_index]
	
	print("Random index: ", random_index, " | Dropping ", random_item, " at position: ", global_position)
	var item = item_drop_scene.instantiate()
	item.set_item_type(random_item)
	item.position = global_position
	# Add to the world (parent to avoid being deleted with slime)
	get_parent().add_child(item)
	print("Item dropped successfully!")

func die():
	# Drop item
	drop_item()
	
	# Mark as dead and hide
	is_dead = true
	visible = false
	player_chase = false
	
	# Disable collision
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	print("Slime will respawn in 10 seconds...")
	# Start respawn timer
	respawn_timer.start()

func _on_respawn_timer_timeout():
	# Respawn the slime
	print("Slime respawning!")
	health = max_health
	is_dead = false
	visible = true
	can_take_damage = true
	
	# Reset position
	global_position = initial_position
	
	# Re-enable collision and physics
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)

func _on_attack_timer_timeout():
	# Try to attack target if in attack zone
	attack_target()
