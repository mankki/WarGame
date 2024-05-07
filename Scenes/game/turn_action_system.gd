
extends Node


const MAX_TURN_ACTIONS :int = 3

@export var _Actions :Control


var _curr_turn_actions :int = 0
var _team_turn :int = 0


func _ready () -> void:

    _team_turn = 0
    _curr_turn_actions = 0
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func _pass_turn () -> void:

    _team_turn = (_team_turn +1) %2
    _curr_turn_actions = 0
#...

    ## - --- --- --- --- ,,, ... ''' qp ''' ... ,,, --- --- --- --- - ##


func take_action (cost_ :int) -> void:

    rpc("_take_action", cost_)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


@rpc("any_peer", "call_local")
func _take_action (cost_ :int) -> bool:

    _curr_turn_actions += cost_
    if _curr_turn_actions == MAX_TURN_ACTIONS: _pass_turn()
    _Actions.set_actions_used(_curr_turn_actions)

    return true
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func can_take_action (cost_ :int) -> bool:

    return cost_ <= (MAX_TURN_ACTIONS - _curr_turn_actions)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func check_is_turn (team_ :int) -> bool:

    return team_ == _team_turn
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
    
