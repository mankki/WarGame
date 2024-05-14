

extends Control


enum TeamColor { RED = 0, BLUE = 1, NUM_TEAMS = 2, NONE = 3}
enum GameState { TEAM = 0, PLACEMENT, PLAYING, OVER }

# Must be indexed using TeamColor
const TEAM_STRINGS :Array[String] = ['red', 'blue']
const TEAM_COLORS :Array[Color] = [Color(0.596, 0.718, 0.518), Color(0.596, 0.718, 0.518)]
# const TEAM_BOUNDS:Array = [[0, 16], [-17, -1]]
const TEAM_BOUNDS:Array = [[0, 16], [0, 16]]
const BOUNDARY := Rect2i(-10, -16, 20, 32)

const GRID_X_RIGHT_BOUND = 10
const GRID_X_LEFT_BOUND = -11
const GRID_Y_BLUE_BOUND = -2
const GRID_Y_RED_BOUND = 1

@export var unit_data_tres :Array[UnitData] = []
@export var _Turn_Action_System :Node

var moving_range_scene = load("res://Scenes/moving_range/moving_range_node.tscn")

var unit_plant_id_counter = 0
var units = ['soldier', 'tank', 'radar', 'missile', 'airplane']
var unit_data :Dictionary = {} 

var team = TeamColor.NONE
var game_state :GameState = GameState.TEAM

#TODO: this logic doesn't work if one player has pressed their color before the other player pressed 'play game'
var num_players_ready :int = 0:
	set (value_):
		num_players_ready += 1
		if num_players_ready == 2: 
			game_state = GameState.PLAYING
			_Turn_Action_System.indicate_turn()

var allies :Dictionary = {}
var enemies :Dictionary = {}
var previews :Dictionary = {}

var preview_type
var preview_type_str = ""

var moving_range_center: Vector2

var last_mouse_pos = Vector2.ZERO
var tile_pos = Vector2i.ZERO
var mouse_pos = Vector2.ZERO

var selected_instance: Node2D = null	# Viittaus valittuun instanssiin, jonka haluat liikuttaa.
var selected_instance_tile_pos :Vector2i

var tilemap

var moving = false
var piece_instance

var old_world_pos: Vector2

@onready var world_node = $GUI/HBoxContainer/World
@onready var terminal = $GUI/HBoxContainer/VBoxContainer/Terminal
@onready var moving_range = moving_range_scene.instantiate()



func _ready():
	randomize()

	tilemap = world_node.tilemap

	moving_range.size = Vector2.ZERO
	add_child(moving_range)

	$GUI/HBoxContainer/VBoxContainer/Messaging.connect("red_signal", playing_team.bind(TeamColor.RED))
	$GUI/HBoxContainer/VBoxContainer/Messaging.connect("blue_signal", playing_team.bind(TeamColor.BLUE))


func _process (delta) -> void:
	mouse_pos = get_global_mouse_position()
	tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))

	match game_state:
		GameState.PLACEMENT:
			if previews.is_empty(): return
			_preview_piece()
			_preview(preview_type)

		GameState.PLAYING:
			if selected_instance == null: return
			# moving = true
			if moving == true:
				selected_instance.global_position = mouse_pos
			else:
				selected_instance.global_position = old_world_pos


func _input(event_ :InputEvent) -> void:
	# left mouse button pressed
	if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and event_.pressed: match game_state:
		GameState.PLACEMENT:
			if unit_plant_id_counter == len(units): return
			if not (GRID_X_LEFT_BOUND < tile_pos.x and tile_pos.x < GRID_X_RIGHT_BOUND): return
			if team == TeamColor.NONE: return 
			if tile_pos.y < GRID_Y_RED_BOUND: return

			var unit = units[unit_plant_id_counter]
			if unit_data[unit].number < unit_data[unit].max_number:
				unit_data[unit].number = _place_ally(tile_pos, unit_data[unit].scene, unit_data[unit].number)
			if unit_data[unit].number == unit_data[unit].max_number: unit_plant_id_counter += 1

			if unit_plant_id_counter == len(units):
				terminal.print_message("Your army is in position")
				rpc("signal_end_placement")
				num_players_ready += 1
				(func(): moving = false).call_deferred()
				_hide_previews()
		
		GameState.PLAYING:
			if not _Turn_Action_System.check_is_turn(int(team)): return
			if not allies.has(tile_pos): return
			
			moving = true

			var piece_type = allies[tile_pos].type.get_slice('_', 0)
			moving_range.show_range(unit_data[piece_type].move_range.x)
			var scan = unit_data[piece_type].scan_range

			var correction = Vector2(-moving_range.size.x/2, -moving_range.size.y/2)
			moving_range.global_position = _get_global_pos(tile_pos) + correction
			moving_range_center = moving_range.position

			selected_instance_tile_pos = tile_pos
			selected_instance = allies[tile_pos]

			for i in range(-scan.x, scan.x +1): for j in range(-scan.y, scan.y +1):
				var vec := Vector2i(i, j)
				if vec == Vector2i.ZERO: continue
				var new_loc = selected_instance_tile_pos + vec
				if enemies.has(new_loc): 
					enemies[new_loc].visible = true
					rpc("reveal_enemy", new_loc)


	# left mouse button released
	if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and !event_.pressed: match game_state:
		GameState.PLAYING:
			if not selected_instance: return

			_Turn_Action_System.action_taken = false

			var newTilePos :Vector2i = tilemap.local_to_map(tilemap.to_local(selected_instance.global_position))
			old_world_pos = _get_global_pos(selected_instance_tile_pos)


#              db     w    w             8    w
#             dPYb   w8ww w8ww .d88 .d8b 8.dP w 8d8b. .d88
#            dPwwYb   8    8   8  8 8    88b  8 8P Y8 8  8
#           dP    Yb  Y8P  Y8P `Y88 `Y8P 8 Yb 8 8   8 `Y88
#                                                     wwdP

			if newTilePos in enemies.keys():
				if unit_data[selected_instance.type].cannot_attack:
					_reset_unit(newTilePos, "Unit cannot attack")
				elif not _Turn_Action_System.can_take_action(unit_data[selected_instance.type].primary_attack_cost):
					_reset_unit(newTilePos, "Not enough action points for primary attack")
				else:
					_Turn_Action_System.take_action(unit_data[selected_instance.type].primary_attack_cost)
					selected_instance.isit_visible = true

					var distance = Vector2(selected_instance_tile_pos).distance_to(Vector2(newTilePos))
					var hit_chance = 1 - (unit_data[selected_instance.type].primary_attack_hit_chance/32.0) *distance
					_reset_unit(newTilePos, "%s is attacking enemy %s with hit chance %.2f" %[
						selected_instance.type.capitalize(), enemies[newTilePos].type, hit_chance
					])

					var attack_roll :float = randf_range(0.0, 1.0)
					
					#TODO: convert this into boolean check for 'unit_data.death_on_attack' or something
					if selected_instance.type == 'missile':
						selected_instance.queue_free()
						allies.erase(selected_instance_tile_pos)

					if attack_roll <= hit_chance: _handle_attack_hit(newTilePos)
					else: terminal.print_message("Attack MISSES")

					if len(enemies) == 0:
						terminal.print_message("%s won the war!" %[TEAM_STRINGS[int(team)].capitalize()])
						$WinnerPopup.show()
						$WinnerPopup/VBoxContainer/WinnerLabel.text = "%s nation won the war!" %[TEAM_STRINGS[int(team)].capitalize()]
						rpc("end_game")

#           8b   d8                                           w
#           8YbmdP8 .d8b. Yb  dP .d88b 8d8b.d8b. .d88b 8d8b. w8ww
#           8  "  8 8' .8  YbdP  8.dP' 8P Y8P Y8 8.dP' 8P Y8  8
#           8     8 `Y8P'   YP   `Y88P 8   8   8 `Y88P 8   8  Y8P
			elif _movement_bounds_checking(newTilePos):
				if not _Turn_Action_System.can_take_action(unit_data[selected_instance.type].move_cost):
					_reset_unit(newTilePos, "Not enough action points to move this unit")
				else:
					allies[newTilePos] = selected_instance
					allies.erase(selected_instance_tile_pos)

					selected_instance.global_position = _get_global_pos(newTilePos)
					terminal.print_message("%s %s charging from %s to %s!" %[
						TEAM_STRINGS[int(team)].capitalize(), selected_instance.type,
						GridToIndex.to_index(selected_instance_tile_pos), GridToIndex.to_index(newTilePos)
					])

					_Turn_Action_System.take_action(unit_data[selected_instance.type].move_cost)
					moving = false
					selected_instance.isit_visible = false
			
			# This makes a click count as an action
			if _Turn_Action_System.action_taken == false:
				_Turn_Action_System.take_action(1)

			selected_instance = null	
			moving = false
			moving_range.hide_range()
			_send_data(allies)



## ooooooooo.             o8o                            .
## `888   `Y88.           `"'                          .o8
##  888   .d88' oooo d8b oooo  oooo    ooo  .oooo.   .o888oo  .ooooo.
##  888ooo88P'  `888""8P `888   `88.  .8'  `P  )88b    888   d88' `88b
##  888          888      888    `88..8'    .oP"888    888   888ooo888
##  888          888      888     `888'    d8(  888    888 . 888    .o
## o888o        d888b    o888o     `8'     `Y888""8o   "888" `Y8bod8P'


func _handle_attack_hit (tile_pos_ :Vector2i) -> void:
	terminal.print_message("Attack HITS")

	var damage = unit_data[selected_instance.type].primary_attack_damage
	var health = enemies[tile_pos_].current_health
	var atk_range = unit_data[selected_instance.type].primary_attack_range

	for i in range(-atk_range, atk_range +1): for j in range(-atk_range, atk_range +1):   
		var new_loc = tile_pos_ + Vector2i(i, j)
		if not enemies.has(new_loc): continue

		if damage >= health: # unit is killed
			enemies[new_loc].queue_free()
			enemies.erase(new_loc)
			rpc('remove_enemy', new_loc)

		else: # unit is only hurt
			enemies[new_loc].current_health -= damage
			rpc("damage_enemy", new_loc, damage)


func _send_data(instances_ :Dictionary):
	var data_to_send :Dictionary = {}
	for key in instances_.keys():
		data_to_send[key] = {
			health = instances_[key].current_health,
			type = instances_[key].type,
			visible = instances_[key].isit_visible
		}

	rpc("receive_data", data_to_send)
#...


func playing_team (team_ :TeamColor) -> void:
	team = team_

	# create unit_data
	for data in unit_data_tres:
		var unit_name = data.resource_path.get_file().get_slice('.', 0)
		unit_data[unit_name] = data
		data.string = unit_name

	# Add _preview units
	for unit in unit_data.keys():
		previews[unit] = unit_data[unit].scene.instantiate()
		previews[unit].global_position = Vector2(0, -400)
		previews[unit].get_node(TEAM_STRINGS[int(team)].capitalize()).visible = true
		previews[unit].get_node(TEAM_STRINGS[int(team)].capitalize()).modulate = Color(1, 1, 1, 0.5)
		add_child(previews[unit])

	$Background.set_color(TEAM_COLORS[int(team)])
	terminal.print_message("May the %s nation be victorious! We will destroy the %s nation!" %[TEAM_STRINGS[int(team)], TEAM_STRINGS[(int(team)+1) %TeamColor.NUM_TEAMS]])
	game_state = GameState.PLACEMENT



#  888b.             8
#  8wwwP .d8b. .d8b. 8
#  8   b 8' .8 8' .8 8
#  888P' `Y8P' `Y8P' 8


func _movement_bounds_checking (tile_pos_ :Vector2i) -> bool:
	# check unit movement is on grid
	if !BOUNDARY.has_point(tile_pos_):
		_reset_unit(tile_pos_, "Cannot move outside of game area")
		return false

	# check unit movement is in range
	elif !Rect2(old_world_pos -(moving_range.size/2), moving_range.size).has_point(selected_instance.global_position):
		_reset_unit(tile_pos_, "Cannot move outside of range")
		return false

	# check movement location is empty
	elif tile_pos_ in allies.keys():
		_reset_unit(tile_pos_, "Cannot move into space of other units")
		return false

	return true



#  888b. 8
#  8  .8 8 .d88 .d8b .d88b
#  8wwP' 8 8  8 8    8.dP'
#  8     8 `Y88 `Y8P `Y88P


## updates enemy piece positions on the board
##
## clears the board of previous enemy pieces then iterates over structure 
## containing enemy piece metadata, placing a new piece where requried
##
## > dict: instances_ = the structure of enemy metadata
##
## < void

func _update_enemy_pieces(instances_ :Dictionary) -> void:
	if instances_.is_empty(): return
	for enemy in enemies.values(): enemy.free()
	enemies.clear()
	for pos in instances_.keys():    
		_place_enemy(pos, unit_data[ instances_[pos].type ].scene, instances_[pos])


## places an enemy piece on the board
##
## a new enemy piece is added to the board at the position indicated 
##
## > Vector2i :tile_pos_ = the position to place the enemy piece
## > PackedScene :scene = the scene representing the enemy piece
##
## < void

func _place_enemy(tile_pos_ :Vector2i, scene_ :PackedScene, unit_data_ :Dictionary) -> void:
	var translated_pos = GridToIndex.translate_180(tile_pos_)
	enemies[translated_pos] = scene_.instantiate()

	enemies[translated_pos].type = unit_data_.type
	enemies[translated_pos].current_health = unit_data_.health
	enemies[translated_pos].visible = unit_data_.visible

	enemies[translated_pos].get_node(TEAM_STRINGS[(int(team)+1) %2].capitalize()).visible = true
	enemies[translated_pos].global_position = tilemap.to_global(tilemap.map_to_local(translated_pos))
	add_child(enemies[translated_pos])


## places and ally piece on the board
##
## a new ally piece is added to the board at the position indicated
##
## > Vector2i :tile_pos_ = the position to place the ally piece
## > PackedScene :scene_ = the scene representing the ally piece
## > int :num_of_pieces_ = the number of this unit pieces placed so far
##
## < int = the updated number of this unit pieces placed so far

func _place_ally(tile_pos_ :Vector2i, scene_ :PackedScene, num_of_pieces_ :int) -> int:
	if tile_pos_ in allies.keys(): return num_of_pieces_

	var newAlly = scene_.instantiate()
	newAlly.get_node(TEAM_STRINGS[int(team)].capitalize()).visible = true
	newAlly.type = preview_type_str.get_slice('_', 0)
	newAlly.current_health = unit_data[newAlly.type].health
	newAlly.isit_visible = false
	newAlly.global_position = tilemap.to_global(tilemap.map_to_local(tile_pos_))
	allies[tile_pos_] = newAlly

	add_child(newAlly)
	terminal.print_message("%s team placed %s unit at position %s" %[
		TEAM_STRINGS[int(team)].capitalize(), preview_type_str.get_slice('_', 0), GridToIndex.to_index(tile_pos_)
	])

	_send_data(allies)

	return num_of_pieces_ + 1



#  888b. 888b. .d88b
#  8  .8 8  .8 8P
#  8wwK' 8wwP' 8b
#  8  Yb 8     `Y88P


@rpc("any_peer", "call_remote")
func receive_data(recieve_data_ :Dictionary):
	_update_enemy_pieces(recieve_data_)


@rpc("any_peer", "call_remote")
func signal_end_placement () -> void:
	num_players_ready += 1
	terminal.print_message("%s's army is in position" %TEAM_STRINGS[(int(team)+1)%2].capitalize())


@rpc("any_peer", "call_remote")
func damage_enemy (pos_ :Vector2i, damage_ :int) -> void:
	var pos = GridToIndex.translate_180(pos_)
	allies[pos].current_health -= damage_


@rpc("any_peer", "call_remote")
func remove_enemy (pos_ :Vector2i) -> void:
	var pos = GridToIndex.translate_180(pos_)
	allies[pos].queue_free()
	allies.erase(pos)


@rpc("any_peer", "call_remote")
func reveal_enemy (pos_ :Vector2i) -> void:
	var pos = GridToIndex.translate_180(pos_)
	allies[pos].isit_visible = true
	
@rpc("any_peer", "call_remote")
func end_game():
	terminal.print_message("%s won the war!" %[TEAM_STRINGS[int(team)].capitalize()])
	$WinnerPopup.show()
	$WinnerPopup/VBoxContainer/WinnerLabel.text = "%s nation won the war!" %[TEAM_STRINGS[int(team)].capitalize()]



#  888b.                   w
#  8  .8 8d8b .d88b Yb  dP w .d88b Yb  db  dP
#  8wwP' 8P   8.dP'  YbdP  8 8.dP'  YbdPYbdP
#  8     8    `Y88P   YP   8 `Y88P   YP  YP


func _preview(preview_):
	if team == TeamColor.NONE: return
	if GRID_X_LEFT_BOUND < tile_pos.x and tile_pos.x < GRID_X_RIGHT_BOUND: 
		if TEAM_BOUNDS[int(team)][0] < tile_pos.y and tile_pos.y < TEAM_BOUNDS[int(team)][1]:
			preview_.global_position = _get_global_pos(tile_pos)


func _preview_piece():
	if unit_plant_id_counter == len(units): return
	if team == TeamColor.NONE: return
	var unit = units[unit_plant_id_counter]
	preview_type = previews[unit]
	preview_type_str = unit_data[unit].string


func _hide_previews():
	for unit in previews:
		previews[unit].queue_free()
	previews.clear()



#  8   8       8
#  8www8 .d88b 8 88b.
#  8   8 8.dP' 8 8  8
#  8   8 `Y88P 8 88P'
#                8

func _get_global_pos(pos_ :Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(pos_))


func _reset_unit (tile_pos_ :Vector2i, message_ :String):
	selected_instance.global_position = old_world_pos             
	if tile_pos_ != selected_instance_tile_pos:
		terminal.print_message(message_)


func _on_replay_pressed():
	get_tree().reload_current_scene()
