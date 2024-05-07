# Red's script

extends Control


enum TeamColor { RED = 0, BLUE = 1, NUM_TEAMS = 2, NONE = 3}
enum GameState { TEAM = 0, PLACEMENT, PLAYING, OVER }

# Must be indexed using TeamColor
const TEAM_STRINGS :Array[String] = ['red', 'blue']
const TEAM_COLORS :Array[Color] = [Color(0.7, 0.2, 0.3, 1), Color(0.2, 0.3, 0.9, 1)]
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
var num_players_ready :int = 0:
    set (value_):
        num_players_ready += 1
        if num_players_ready == 2: game_state = GameState.PLAYING

var instances :Dictionary = {}
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

@onready var world_node = $GUI/HBoxContainer/World
@onready var terminal = $GUI/HBoxContainer/VBoxContainer/Terminal
@onready var moving_range = moving_range_scene.instantiate()



func _ready():
    tilemap = world_node.tilemap

    moving_range.size = Vector2.ZERO
    add_child(moving_range)

    $GUI/HBoxContainer/VBoxContainer/Messaging.connect("red_signal", playing_team.bind(TeamColor.RED))
    $GUI/HBoxContainer/VBoxContainer/Messaging.connect("blue_signal", playing_team.bind(TeamColor.BLUE))
#...

    ## - --- --- --- --- ,,, ... ''' qp ''' ... ,,, --- --- --- --- - ##


func _process (delta) -> void:

    mouse_pos = get_global_mouse_position()
    tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))

    match game_state:
        GameState.PLACEMENT:
            if previews.is_empty(): return
            preview_piece()
            preview(preview_type)

        GameState.PLAYING:
            if selected_instance == null: return
            moving = true
            selected_instance.global_position = mouse_pos
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func _input(event_ :InputEvent) -> void:
    
    # left mouse button pressed
    if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and event_.pressed: match game_state:
        GameState.PLACEMENT:
            if unit_plant_id_counter == len(units): return
            if not (GRID_X_LEFT_BOUND < tile_pos.x and tile_pos.x < GRID_X_RIGHT_BOUND): return
            if team == TeamColor.NONE: return 
            # if team == TeamColor.BLUE and tile_pos.y > GRID_Y_BLUE_BOUND: return 
            # if team == TeamColor.RED and tile_pos.y < GRID_Y_RED_BOUND: return
            if tile_pos.y < GRID_Y_RED_BOUND: return

            var unit = units[unit_plant_id_counter]
            if unit_data[unit].number < unit_data[unit].max:
                unit_data[unit].number = place_ally(tile_pos, unit_data[unit].scene, unit_data[unit].number)
            if unit_data[unit].number == unit_data[unit].max: unit_plant_id_counter += 1

            if unit_plant_id_counter == len(units):
                terminal.print_message("Your army is in position")
                rpc("signal_end_placement")
                num_players_ready += 1
                (func(): moving = false).call_deferred()
                hide_previews()
        
        GameState.PLAYING:
            if not _Turn_Action_System.check_is_turn(int(team)): return
            if not instances.has(tile_pos): return

            var piece_type = instances[tile_pos].get_meta("piece_type").get_slice('_', 0)
            moving_range.size = unit_data[piece_type].range

            if not tile_pos in instances.keys(): return
            var correction = Vector2(-moving_range.size.x/2, -moving_range.size.y/2)
            moving_range.global_position = tilemap.to_global(tilemap.map_to_local(tile_pos)) + correction
            moving_range_center = moving_range.position

            selected_instance_tile_pos = tile_pos
            selected_instance = instances[tile_pos]

    # left mouse button released
    if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and !event_.pressed: match game_state:
        GameState.PLAYING:
            if not selected_instance: return

            var new_tile_pos :Vector2i = tilemap.local_to_map(tilemap.to_local(selected_instance.global_position))
            var old_world_pos :Vector2 = tilemap.to_global(tilemap.map_to_local(selected_instance_tile_pos))
            
            var reset_unit :Callable = func (message_ :String):
                selected_instance.global_position = old_world_pos             
                if new_tile_pos != selected_instance_tile_pos:
                    terminal.print_message(message_)

            if !BOUNDARY.has_point(new_tile_pos):
                reset_unit.call("Cannot move outside of game area")

            if not _Turn_Action_System.can_take_action(1):
                reset_unit.call("not enough points to take action")

            # check unit movement is in range
            elif !Rect2(old_world_pos -(moving_range.size/2), moving_range.size).has_point(selected_instance.global_position):
                reset_unit.call("Cannot move outside of range")

            # check movement location is empty
            #TODO: check if enemy unit is present HANDLE HERE
            elif new_tile_pos in instances.keys():
                reset_unit.call("Cannot move into space of other units")

            
            else: # movement is successful
                # swap dictionary keys for instance reference
                instances.erase(selected_instance_tile_pos)
                instances[new_tile_pos] = selected_instance

                selected_instance.global_position = tilemap.to_global(tilemap.map_to_local(new_tile_pos))
                terminal.print_message("%s %s charging from %s to %s!" %[
                    TEAM_STRINGS[int(team)].capitalize(), selected_instance.get_meta("piece_type"),
                    GridToIndex.to_index(selected_instance_tile_pos), GridToIndex.to_index(new_tile_pos)
                ])
                _Turn_Action_System.take_action(1)
                

            selected_instance = null	
            moving = false
            moving_range.size = Vector2(0, 0)
            send_data(instances)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


## updates enemy piece positions on the board
##
## clears the board of previous enemy pieces then iterates over structure 
## containing enemy piece metadata, placing a new piece where requried
##
## > dict: instances_ = the structure of enemy metadata
##
## < void

func update_enemy_pieces(instances_ :Dictionary) -> void:
    if instances_.is_empty(): return
    for enemy in enemies.values(): enemy.free()
    enemies.clear()
    for pos in instances_.keys():    
        place_enemy(pos, unit_data[ instances_[pos] ].scene)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


## places an enemy piece on the board
##
## a new enemy piece is added to the board at the position indicated 
##
## > Vector2i :tile_pos_ = the position to place the enemy piece
## > PackedScene :scene = the scene representing the enemy piece
##
## < void

func place_enemy(tile_pos_ :Vector2i, scene_ :PackedScene) -> void:
    enemies[tile_pos_] = scene_.instantiate()
    enemies[tile_pos_].get_node(TEAM_STRINGS[(int(team)+1) %2].capitalize()).visible = true
    enemies[tile_pos_].global_position = tilemap.to_global(tilemap.map_to_local(GridToIndex.translate_180(tile_pos_)))
    add_child(enemies[tile_pos_])
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


## places and ally piece on the board
##
## a new ally piece is added to the board at the position indicated
##
## > Vector2i :tile_pos_ = the position to place the ally piece
## > PackedScene :scene_ = the scene representing the ally piece
## > int :num_of_pieces_ = the number of this unit pieces placed so far
##
## < int = the updated number of this unit pieces placed so far

func place_ally(tile_pos_ :Vector2i, scene_ :PackedScene, num_of_pieces_ :int) -> int:
    if tile_pos_ in instances.keys(): return num_of_pieces_

    instances[tile_pos_] = scene_.instantiate()
    instances[tile_pos_].get_node(TEAM_STRINGS[int(team)].capitalize()).visible = true
    instances[tile_pos_].set_meta("piece_type", preview_type_str.get_slice('_', 0))
    instances[tile_pos_].global_position = tilemap.to_global(tilemap.map_to_local(tile_pos_))
    add_child(instances[tile_pos_])
    terminal.print_message("%s team placed %s unit at position %s" %[
        TEAM_STRINGS[int(team)].capitalize(), preview_type_str.get_slice('_', 0), GridToIndex.to_index(tile_pos_)
    ])

    send_data(instances)

    return num_of_pieces_ + 1
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func send_data(instances_ :Dictionary):
    var data_to_send :Dictionary = {}
    for key in instances_.keys(): data_to_send[key] = instances_[key].get_meta('piece_type')

    rpc("receive_data", data_to_send)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
        

@rpc("any_peer", "call_remote")
func receive_data(recieve_data_ :Dictionary):
    update_enemy_pieces(recieve_data_)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##

@rpc("any_peer", "call_remote")
func signal_end_placement () -> void:
    num_players_ready += 1
    terminal.print_message("%s's army is in position" %TEAM_STRINGS[(int(team)+1)%2])
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func playing_team (team_ :TeamColor) -> void:
    team = team_

    # create unit_data
    for data in unit_data_tres:
        var unit_name = data.resource_path.get_file().get_slice('.', 0)
        unit_data[unit_name] = {
            range = data.move_range,
            number = 0,
            max = data.max_number,
            scene = data.scene,
            preview = null,
            string = "%s_preview" %unit_name
        }

    # Add preview units
    for unit in unit_data.keys():
        previews[unit] = unit_data[unit].scene.instantiate()
        previews[unit].global_position = Vector2(0, -400)
        previews[unit].get_node(TEAM_STRINGS[int(team)].capitalize()).visible = true
        previews[unit].get_node(TEAM_STRINGS[int(team)].capitalize()).modulate = Color(1, 1, 1, 0.5)
        add_child(previews[unit])

    $Background.set_color(TEAM_COLORS[int(team)])
    terminal.print_message("May the %s nation be victorious! We will destroy the %s nation!" %[TEAM_STRINGS[int(team)], TEAM_STRINGS[(int(team)+1) %TeamColor.NUM_TEAMS]])
    game_state = GameState.PLACEMENT
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func preview(preview_):

    if team == TeamColor.NONE: return
    if GRID_X_LEFT_BOUND < tile_pos.x and tile_pos.x < GRID_X_RIGHT_BOUND: 
        if TEAM_BOUNDS[int(team)][0] < tile_pos.y and tile_pos.y < TEAM_BOUNDS[int(team)][1]:
            preview_.global_position = tilemap.to_global(tilemap.map_to_local(tile_pos))
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func preview_piece():
    if unit_plant_id_counter == len(units): return
    if team == TeamColor.NONE: return
    var unit = units[unit_plant_id_counter]
    preview_type = previews[unit]
    preview_type_str = unit_data[unit].string
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##

        
func hide_previews():

    for unit in previews:
        previews[unit].queue_free()
    previews.clear()
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
    

