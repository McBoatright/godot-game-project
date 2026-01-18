extends Area2D

var item_type: String = "item1"

@onready var label: Label = $Label

func _ready():
	# Add to item_drops group for easy finding
	add_to_group("item_drops")
	
	# Set the label text based on item type
	if label:
		label.text = item_type
	
	# Add a simple float animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.5)
	tween.tween_property(self, "position:y", position.y + 5, 0.5)
	
	# Auto-vanish after 5 seconds
	var vanish_timer = Timer.new()
	vanish_timer.wait_time = 5.0
	vanish_timer.one_shot = true
	vanish_timer.timeout.connect(_on_vanish_timeout)
	add_child(vanish_timer)
	vanish_timer.start()

func set_item_type(type: String):
	item_type = type
	if label:
		label.text = item_type

func is_player_near() -> bool:
	# Check if player is within pickup range
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.name == "player":
			return true
	return false

func _on_vanish_timeout():
	print("Item ", item_type, " vanished after 5 seconds")
	queue_free()
