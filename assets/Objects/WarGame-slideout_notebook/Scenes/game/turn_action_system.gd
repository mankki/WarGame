
extends Node


const MAX_TURN_ACTIONS :int = 3

@export var _Actions :Control


var _curr_turn_actions :int = 0
var _team_turn :int = 0

var action_taken: bool



func _ready () -> void:
	_team_turn = 0
	_curr_turn_actions = 0
	_Actions.set_no_turn()


func _pass_turn () -> void:
	_team_turn = (_team_turn +1) %2
	_curr_turn_actions = 0
	indicate_turn()

func take_action (cost_ :int) -> void:
	rpc("_take_action", cost_)


@rpc("any_peer", "call_local")
func _take_action (cost_ :int) -> bool:
	action_taken = true

	_curr_turn_actions += cost_
	if _curr_turn_actions == MAX_TURN_ACTIONS: _pass_turn()
	_Actions.set_actions_used(_curr_turn_actions)

	return true


func can_take_action (cost_ :int) -> bool:
	return cost_ <= (MAX_TURN_ACTIONS - _curr_turn_actions)


func check_is_turn (team_ :int) -> bool:
	return team_ == _team_turn

func indicate_turn () -> void:
	_Actions.set_player_turn((_team_turn +get_parent().team) %2)
