

extends Control


@export var _Green :Control
@export var _Yellow :Control
@export var _Red :Control

func set_actions_used (used_ :int) -> void:

    if used_ < 0 or 3 < used_: 
        printerr("Actions used does not match with number of action indicators")
        return

    var lights :Array = [_Green, _Yellow, _Red]
    for light in lights: light.self_modulate = Color(1, 1, 1, 1)
    for i in range (0, used_): lights[i].self_modulate = Color.from_hsv(0.0, 0.0, 0.5)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
