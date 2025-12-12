extends Control

func _on_vs_computer_button_pressed() -> void:
	# Load world with AI enemy
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_two_player_button_pressed() -> void:
	# Load world with 2 players (no AI)
	get_tree().change_scene_to_file("res://scenes/world_2player.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
