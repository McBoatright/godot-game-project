extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_scene()


func _on_cliffside_transition_point_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true

func _on_cliffside_transition_point_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = false


		func change_scene():
			if Global.transition_scene == true:
				if Global.current_scene =="world":
					get_tree().change_scene_to_file("res://scenes/cliff_side.tscn")
					global.finish_changescenes()