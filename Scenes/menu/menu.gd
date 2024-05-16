extends Control

func _on_play_red_pressed():
    get_tree().change_scene_to_file("res://Scenes/game/game.tscn")


func _on_exit_pressed():
    get_tree().quit()

func _on_options_pressed():
    get_tree().change_scene_to_file("res://Scenes/options.tscn")
    
    
