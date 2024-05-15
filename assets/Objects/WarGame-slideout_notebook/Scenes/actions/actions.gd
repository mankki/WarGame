

extends Control


@export var _Ally :Label
@export var _Enemy :Label

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


func set_player_turn (team_ :int) -> void:
    var modColors :Array[Color] = [Color.WHITE, Color.BLACK]
    
    _Ally.self_modulate = modColors[team_]
    _Enemy.self_modulate = modColors[(team_ +1) %2]


func set_no_turn () -> void:
    _Ally.self_modulate = Color.BLACK
    _Enemy.self_modulate = Color.BLACK