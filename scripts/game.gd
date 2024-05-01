# Red's script

extends Node2D


enum TeamColor { RED = 0, BLUE = 1, NUM_TEAMS = 2, NONE = 3}
enum GameState { TEAM = 0, PLACEMENT, PLAYING, OVER }

# Must be indexed using TeamColor
const TEAM_STRINGS :Array[String] = ['red', 'blue']
const TEAM_COLORS :Array[Color] = [Color(0.7, 0.2, 0.3, 1), Color(0.2, 0.3, 0.9, 1)]
const TEAM_BOUNDS:Array = [[0, 16], [-17, -1]]

const GRID_X_RIGHT_BOUND = -9
const GRID_X_LEFT_BOUND = -30
const GRID_Y_BLUE_BOUND = -2
const GRID_Y_RED_BOUND = 1

@export var unit_data_tres :Array[UnitData] = []
var moving_range_scene = load("res://Scenes/moving_range_node.tscn")

# Instantiate things
var unit_plant_id_counter = 0
var units = ['soldier', 'tank', 'radar', 'missile', 'airplane']
var unit_data :Dictionary = {} 


var team = TeamColor.NONE
var game_state :GameState = GameState.TEAM
var instances :Dictionary = {}
var enemies :Dictionary = {}
var previews :Dictionary = {}

var preview_type
var preview_type_str = ""

var moving_range_center: Vector2

var last_mouse_position = Vector2.ZERO
var tile_position = Vector2i.ZERO
var mouse_position = Vector2.ZERO

var tilemap: TileMap
var selected_instance: Node2D = null	# Viittaus valittuun instanssiin, jonka haluat liikuttaa.


var moving = false
var piece_instance

@onready var world_node = $World
@onready var moving_range = moving_range_scene.instantiate()



class GridPosition:
    var pos :Vector2i

    func _init (x :int, y :int) -> void:
        pos = Vector2i(x, y)
#...

    ## - --- --- --- --- ,,, ... ''' qCp ''' ... ,,, --- --- --- --- - ##


func _ready():
    # Configurate RPC
    rpc_config("receive_data", MultiplayerAPI.RPC_MODE_ANY_PEER)

    # Create the server
    # Create the world  TODO: change to get tilemap from existing world node
    add_child(world_node)
    tilemap = world_node.get_node("TileMap") as TileMap


    moving_range.size = Vector2.ZERO
    add_child(moving_range)

    $Messaging.connect("red_signal", playing_team.bind(TeamColor.RED))
    $Messaging.connect("blue_signal", playing_team.bind(TeamColor.BLUE))
#...

    ## - --- --- --- --- ,,, ... ''' qp ''' ... ,,, --- --- --- --- - ##


func _process (delta) -> void:
    mouse_position = get_global_mouse_position()
    tile_position = tilemap.local_to_map(mouse_position)

    # if tilemap and mouse_position:
    preview_piece()
    preview(preview_type)


    if selected_instance != null:
        moving = true
        move_mouse() # If an instance has been selected, follow the mouse

#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func _input(event_ :InputEvent) -> void:
    if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and event_.pressed: match game_state:
        GameState.PLACEMENT:
            if not (GRID_X_LEFT_BOUND < tile_position.x and tile_position.x < GRID_X_RIGHT_BOUND): return
            if team == TeamColor.NONE: return 
            if team == TeamColor.BLUE and tile_position.y > GRID_Y_BLUE_BOUND: return 
            if team == TeamColor.RED and tile_position.y < GRID_Y_RED_BOUND: return

            var unit = units[unit_plant_id_counter]
            if unit_data[unit].number < unit_data[unit].max:
                unit_data[unit].number = plant(tile_position, unit_data[unit].scene, unit_data[unit].number)
            if unit_data[unit].number == unit_data[unit].max: unit_plant_id_counter += 1

            if unit_plant_id_counter == len(units):
                game_state = GameState.PLAYING
                set_moving_to_false.call_deferred()
                hide_previews()
                print("Game on!")
        
        GameState.PLAYING:
            how_far_can_a_piece_move()
            moving_range_func()

            var clicked_tile_position = tilemap.local_to_map(get_global_mouse_position())
            for instance in instances.values():
                if tilemap.local_to_map(instance.global_position) == clicked_tile_position:
                    selected_instance = instance

    if event_ is InputEventMouseButton and event_.button_index == MOUSE_BUTTON_LEFT and !event_.pressed: match game_state:
        GameState.PLAYING:

            if not selected_instance: return
            var terminal = $Terminal/TerminalText
            terminal.text += "\n>>> " + "Moving!" #TODO: update to print which team and unit has moved
            moving = false

            var new_tile_position = tilemap.local_to_map(selected_instance.global_position)
            for pos in instances.keys(): if instances[pos] == selected_instance: instances.erase(pos)
            instances[new_tile_position] = selected_instance
            selected_instance.global_position = tilemap.map_to_local(new_tile_position)

            selected_instance = null	

            moving_range.size = Vector2(0, 0)
            tile_position = new_tile_position
            send_data(instances)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func how_far_can_a_piece_move():
    if not instances.has(tile_position): return
    var piece_type = instances[tile_position].get_meta("piece_type").get_slice('_', 0)
    moving_range.size = unit_data[piece_type].range
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func moving_range_func():
    if not tile_position in instances.keys(): return
    var correction = Vector2(-moving_range.size.x/2, -moving_range.size.y/2)
    moving_range.global_position = tilemap.map_to_local(tile_position) + correction
    moving_range_center = moving_range.position
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func set_moving_to_false():
    moving = false
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


# A function to plant enemy pieces
func update_other_pieces(instances_):
    # print(instances_)
    if instances_.is_empty(): return
    print(enemies)
    for enemy in enemies.values(): enemy.free()
    enemies.clear()
    for pos in instances_.keys():    
        plant_enemy(pos, unit_data[ instances_[pos] ].scene)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


# A function to plant the enemy pieces (and remove the piece instance from the initial tile, that is, the tile we're moving from)
func plant_enemy(tile_pos_: Vector2, scene):
    enemies[tile_pos_] = scene.instantiate()
    enemies[tile_pos_].get_node(TEAM_STRINGS[(int(team)+1) %2].capitalize()).visible = true
    enemies[tile_pos_].global_position = tilemap.map_to_local(tile_pos_)
    add_child(enemies[tile_pos_])
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func plant(tile_pos :Vector2, scene :PackedScene, num_of_pieces :int) -> int:
    if tile_pos in instances.keys(): return num_of_pieces

    instances[tile_position] = scene.instantiate()
    instances[tile_position].get_node(TEAM_STRINGS[int(team)].capitalize()).visible = true
    instances[tile_position].set_meta("piece_type", preview_type_str.get_slice('_', 0))
    instances[tile_position].global_position = tilemap.map_to_local(tile_pos)
    add_child(instances[tile_position])
    # $Terminal/TerminalText.text += '\n>>>' + 'Roger that!'

    send_data(instances)

    return num_of_pieces + 1
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func send_data(instances_ :Dictionary):
    var send_data :Dictionary = {}
    for key in instances_.keys(): send_data[key] = instances_[key].get_meta('piece_type')

    rpc("receive_data", send_data)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
        

@rpc("any_peer", "call_remote")
func receive_data(recieve_data_ :Dictionary):
    update_other_pieces(recieve_data_)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func playing_team (team_ :TeamColor) -> void:
    team = team_

    # create unit_data
    for data in unit_data_tres:
        var unit_name = data.resource_path.get_file().get_slice('.', 0)
        unit_data[unit_name] = {
            range = data.range,
            number = 0,
            max = data.max,
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
    $Terminal/TerminalText.text += "\n>>> May the %s nation be victorious! We will destroy the %s nation!" %[TEAM_STRINGS[int(team)], TEAM_STRINGS[(int(team)+1) %TeamColor.NUM_TEAMS]]
    game_state = GameState.PLACEMENT
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func move_mouse():
    selected_instance.global_position = mouse_position
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func preview(preview):

    if previews.is_empty(): return
    if team == TeamColor.NONE: return
    if GRID_X_LEFT_BOUND < tile_position.x and tile_position.x < GRID_X_RIGHT_BOUND: 
        if TEAM_BOUNDS[int(team)][0] < tile_position.y and tile_position.y < TEAM_BOUNDS[int(team)][1]:
            preview.global_position = tilemap.map_to_local(tile_position)
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
    

