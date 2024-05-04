
extends Node


const MAX_TURN_ACTIONS :int = 3

var _curr_turn_actions :int = 0
var _team_turn :int = 0


func _ready () -> void:

    _team_turn = 0
    _curr_turn_actions = MAX_TURN_ACTIONS
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func pass_turn () -> void:

    _team_turn = (_team_turn +1) %2
    _curr_turn_actions = MAX_TURN_ACTIONS
#...

    ## - --- --- --- --- ,,, ... ''' qp ''' ... ,,, --- --- --- --- - ##


func take_action (cost_ :int) -> bool:

    if cost_ > _curr_turn_actions: return false

    _curr_turn_actions -= cost_
    if _curr_turn_actions == 0: pass_turn()

    return true
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
    
