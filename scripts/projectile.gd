extends Area2D
class_name Projectile

var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 20
var lifetime: float = 3.0
var caster = null  # Who cast this spell (player or enemy)

func _ready():
	print("Projectile created - damage: ", damage, " speed: ", speed)
	
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_timeout)
	add_child(timer)
	timer.start()
	
	# Connect collision detection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	print("Projectile collision_mask: ", collision_mask, " collision_layer: ", collision_layer)

func _physics_process(delta):
	# Move projectile in direction
	position += direction * speed * delta

func setup(start_pos: Vector2, target_dir: Vector2, spell_damage: int, spell_caster):
	position = start_pos
	direction = target_dir.normalized()
	damage = spell_damage
	caster = spell_caster
	
	# Rotate sprite to face direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D):
	# Check if we hit something
	if body == caster:
		return  # Don't hit the caster
	
	print("Projectile collided with: ", body.name)
	
	# Check if it's an enemy
	if body.is_in_group("enemies"):
		if body.has_method("take_spell_damage"):
			body.take_spell_damage(damage)
			print("Projectile hit ", body.name, " for ", damage, " damage!")
		else:
			print("Enemy doesn't have take_spell_damage method")
		queue_free()  # Destroy projectile
	elif body.has_method("player"):
		# Hit player, don't destroy if it's the caster
		if body != caster:
			print("Hit player")
			queue_free()
	else:
		# Hit something else (wall, obstacle, etc.)
		print("Hit obstacle")
		queue_free()

func _on_area_entered(area: Area2D):
	print("Projectile hit area: ", area.name)
	
	# Check if we hit another projectile (projectile vs projectile collision)
	if area is Projectile:
		var other_projectile = area as Projectile
		# Only cancel out if projectiles are from different casters
		if other_projectile.caster != caster:
			print("PROJECTILE CLASH! Both projectiles cancelled out!")
			other_projectile.queue_free()
			queue_free()
			return
	
	# Ignore detection_area (enemy chase detection) - only hit enemy_hitbox
	if area.name == "detection_area":
		print("  Ignoring detection_area")
		return
	
	# Walk up the parent chain to find the enemy
	var node = area
	while node:
		if node.is_in_group("enemies"):
			# Don't hit the caster
			if node == caster:
				print("  Ignoring caster (area collision)")
				return
			
			if node.has_method("take_spell_damage"):
				node.take_spell_damage(damage)
				print("Area collision - dealt ", damage, " damage to ", node.name, "!")
			queue_free()
			return
		node = node.get_parent()
	
	# Check if we hit the player
	node = area
	while node:
		if node.has_method("player"):
			# Don't hit the caster
			if node == caster:
				print("  Ignoring caster (player area collision)")
				return
			
			if node.has_method("take_damage"):
				node.take_damage(damage)
				print("Area collision - dealt ", damage, " damage to player!")
			queue_free()
			return
		node = node.get_parent()
	
	print("  Hit area but couldn't find valid target in parent chain")

func _on_lifetime_timeout():
	# Projectile expired without hitting anything
	print("Projectile lifetime expired")
	queue_free()
