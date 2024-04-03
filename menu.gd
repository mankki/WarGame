extends Control

func _on_play_red_pressed():
	get_tree().change_scene_to_file("res://game_red.tscn")

func _on_play_blue_pressed():
	get_tree().change_scene_to_file("res://game_blue.tscn")

