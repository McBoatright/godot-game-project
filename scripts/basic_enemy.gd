extends CharacterBody2D

# Preload item drop scene
var item_drop_scene = preload("res://scenes/item_drop.tscn")

var speed = 40
var player_chase = false
var player = null

var health = 2
var max_health = 2
var player_inattack_zone = false
var can_take_damage = true

var initial_position: Vector2
var is_dead = false
var respawn_timer: Timer

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

func _physics_process(_delta):
	if is_dead:
		return
		
	deal_with_damage()

	if player_chase:
		position += (player.position -position)/speed

		$AnimatedSprite2D.play("walk")

		if(player.position.x - position.x) > 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.play("idle")



func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(_body: Node2D) -> void:
	player = null
	player_chase = false


func enemy():
	pass # Replace with function body.	


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
			print("slime health = ", health, "/2")
			if health <= 0:
				die()

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
