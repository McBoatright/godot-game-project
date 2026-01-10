extends Node2D

func _ready():
	# Optional: Add a simple float animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.5)
	tween.tween_property(self, "position:y", position.y + 5, 0.5)
