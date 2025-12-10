extends Area2D
class_name Projectile

var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 20
var lifetime: float = 3.0
var caster = null  # Who cast this spell (player or enemy)

func _ready():
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_timeout)
	add_child(timer)
	timer.start()
	
	# Connect collision detection
	body_entered.connect(_on_body_entered)

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

func _on_lifetime_timeout():
	# Projectile expired without hitting anything
	queue_free()
