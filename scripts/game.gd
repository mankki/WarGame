# Red's script

extends Node2D


enum TeamColor { RED = 0, BLUE = 1, NONE = 2}
enum GameState { TEAM = 0, PLACEMENT, PLAYING, OVER }

const TEAM_STRINGS :Array[String] = ['red', 'blue']
const TEAM_COLORS :Array[Color] = [Color(0.7, 0.2, 0.3, 1), Color(0.2, 0.3, 0.9, 1)]
var moving_range_scene = load("res://Scenes/moving_range_node.tscn")

# Instantiate things
var unit_plant_id_counter = 0
var units = ['soldier', 'tank', 'radar', 'missile', 'airplane']
var unit_data = {
    soldier = {
        range = Vector2(60, 60),
        number = 0,
        max = 1,
        scene = { 
            red = load("res://PieceNodes/red_soldier_node.tscn"),
            blue = load("res://PieceNodes/blue_soldier_node.tscn"),
        },
        preview = { 
            red = {
                scene = load("res://PiecePreviewNodes/red_soldier_preview_node.tscn"),
                instance = null,
            },
            blue = {
                scene = load("res://PiecePreviewNodes/blue_soldier_preview_node.tscn"),
                instance = null,
            },
            string = "soldier_preview",
        },
    }, 

    tank = {
        range = Vector2(100, 100),
        number = 0,
        max = 1,
        scene = {
            red = load("res://PieceNodes/red_tank_node.tscn"),
            blue = load("res://PieceNodes/blue_tank_node.tscn"),
        },
        preview = {
            red = {
                scene = load("res://PiecePreviewNodes/red_tank_preview_node.tscn"),
                instance = null,
            },
            blue = {
                scene = load("res://PiecePreviewNodes/blue_tank_preview_node.tscn"),
                instance = null,
            },
            string = "tank_preview",
        }
    },

    radar = {
        range = Vector2(100, 100),
        number = 0,
        max = 1,
        scene = {
            red = load("res://PieceNodes/red_radar_node.tscn"),
            blue = load("res://PieceNodes/blue_radar_node.tscn"),
        },
        preview = {
            red = {
                scene = load("res://PiecePreviewNodes/red_radar_preview_node.tscn"),
                instance = null,
            },
            blue = {
                scene = load("res://PiecePreviewNodes/blue_radar_preview_node.tscn"),
                instance = null,
            },
            string = "radar_preview",
        },
    },

    missile = {
        range = Vector2(140, 140),
        number = 0,
        max = 1,
        scene = {
            red = load("res://PieceNodes/red_missile_node.tscn"),
            blue = load("res://PieceNodes/blue_missile_node.tscn"),
        },
        preview = {
            red = {
                scene = load("res://PiecePreviewNodes/red_missile_preview_node.tscn"),
                instance = null,
            },
            blue = {
                scene = load("res://PiecePreviewNodes/blue_missile_preview_node.tscn"),
                instance = null,
            },
            string = "missile_preview",
        },
    },

    airplane = {
        range = Vector2(180, 180),
        number = 0,
        max = 1,
        scene = {
            red = load("res://PieceNodes/red_airplane_node.tscn"),
            blue = load("res://PieceNodes/blue_airplane_node.tscn"),
        },
        preview = {
            red = {
                scene = load("res://PiecePreviewNodes/red_airplane_preview_node.tscn"),
                instance = null,
            },
            blue = {
                scene = load("res://PiecePreviewNodes/blue_airplane_preview_node.tscn"),
                instance = null,
            },
            string = "airplane_preview",
        },
    },
}


var total_num_of_pieces = 1 # Should be 0, but 1 makes the code work
const max_blue_soldiers := 1
const max_blue_tanks := 1
const max_blue_radars := 1
const max_blue_missiles := 1
const max_blue_airplanes := 1
var total_max_num_of_pieces = unit_data.soldier.max + unit_data.tank.max + unit_data.radar.max + unit_data.missile.max + unit_data.airplane.max

var game_state :GameState = GameState.TEAM

var is_placement_in_progress := false

var instances :Dictionary = {}
var old_piece_positions_ints = []

var preview_type
var preview_type_str = ""

var moving_range_center: Vector2
var tile_before_moving

var last_mouse_position = Vector2.ZERO
var tile_position
var mouse_position

var tilemap: TileMap
var selected_instance: Node2D = null	# Viittaus valittuun instanssiin, jonka haluat liikuttaa.


var team = TeamColor.NONE
var moving = false
var old_tile_position
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

    # Add units
    for unit in unit_data.keys(): for color in TEAM_STRINGS:
        unit_data[unit].preview[color].instance = unit_data[unit].preview[color].scene.instantiate()
        add_child(unit_data[unit].preview[color].instance)

    add_child(moving_range)

    $Messaging.connect("red_signal", playing_team.bind(TeamColor.RED))
    $Messaging.connect("blue_signal", playing_team.bind(TeamColor.BLUE))
#...

    ## - --- --- --- --- ,,, ... ''' qp ''' ... ,,, --- --- --- --- - ##


func _process (delta) -> void:
    mouse_position = get_global_mouse_position()
    tile_position = tilemap.local_to_map(mouse_position)

    if moving == false:
        old_tile_position = tile_position
    if tilemap and mouse_position:
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
            if not (-30 < tile_position.x and tile_position.x < -9): return
            if team == TeamColor.NONE: return 
            if team == TeamColor.BLUE and mouse_position.y > 20: return 
            if team == TeamColor.RED and mouse_position.y < -3: return

            var unit = units[unit_plant_id_counter]
            if unit_data[unit].number < unit_data[unit].max:
                unit_data[unit].number = plant(tile_position, unit_data[unit].scene[TEAM_STRINGS[int(team)]], unit_data[unit].number)
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

            var new_position = selected_instance.global_position
            var new_tile_position = tilemap.local_to_map(new_position)

            # Let's update the piece_positions list
            for pos in instances.keys(): if pos == new_tile_position: instances.erase(pos)
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
func update_other_pieces(piece_positions_ints):
    for piece in piece_positions_ints:
        if len(old_piece_positions_ints) < len(piece_positions_ints):
            old_piece_positions_ints.append(0)
        print(old_piece_positions_ints)

    if not piece_positions_ints: return

    print("Determining the team...")
    if team == TeamColor.BLUE:
        print("Trying to update red's pieces on blue's board...")
        print("old_piece_positions_ints: ", old_piece_positions_ints)
        print("piece_positions_ints: ", piece_positions_ints)
        var correction = -moving_range.size.x/2
        for i in range(0, len(piece_positions_ints) - 1, 2):
            if old_piece_positions_ints[i] != piece_positions_ints[i] and old_piece_positions_ints[i+1] != piece_positions_ints[i+1]:
                print("Updating red's pieces on blue's board")
                if i + 1 < unit_data.soldier.max * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.soldier.scene)
                elif i + 1 > unit_data.soldier.max * 2 and i < unit_data.soldier.max * 2 + unit_data.tank.max * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.tank.scene)
                elif i + 1 > unit_data.tank.max * 2 and i < unit_data.soldier.max * 2 + unit_data.tank.max * 2 + unit_data.radar.max * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.radar.scene)
                elif i + 1 > unit_data.radar.max * 2 and i < unit_data.soldier.max * 2 + unit_data.tank.max * 2 + unit_data.radar.max * 2 + unit_data.missile.max * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.missile.scene)
                elif i + 1> unit_data.missile.max * 2 and i < unit_data.soldier.max * 2 + unit_data.tank.max * 2 + unit_data.radar.max * 2 + unit_data.missile.max * 2 + unit_data.airplane.max * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.airplane.scene)
    elif team == TeamColor.RED:
        print("Trying to update blue's pieces on red's board...")
        print("old_piece_positions_ints: ", old_piece_positions_ints)
        print("piece_positions_ints: ", piece_positions_ints)
        var correction = -moving_range.size.x/2
        for i in range(0, len(piece_positions_ints) - 1, 2):
            if old_piece_positions_ints[i] and old_piece_positions_ints[i] != piece_positions_ints[i] and old_piece_positions_ints[i+1] != piece_positions_ints[i+1]:
                print("Updating blue's pieces on red's board")
                if i + 1 < max_blue_soldiers * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.soldier.scene.blue)
                elif i + 1 > max_blue_soldiers * 2 and i < max_blue_soldiers * 2 + max_blue_tanks * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.tank.scene.blue)
                elif i +1 > max_blue_tanks * 2 and i < max_blue_soldiers * 2 + max_blue_tanks * 2 + max_blue_radars * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.radar.scene.blue)
                elif i + 1> unit_data.radar.max * 2 and i < max_blue_soldiers * 2 + max_blue_tanks * 2 + max_blue_radars * 2 + max_blue_missiles * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.missile.scene.blue)
                elif i + 1> max_blue_missiles * 2 and i < max_blue_soldiers * 2 + max_blue_tanks * 2 + max_blue_radars * 2 + max_blue_missiles * 2 + max_blue_airplanes * 2:
                    plant_enemy(Vector2(piece_positions_ints[i],piece_positions_ints[i+1]), unit_data.airplane.scene.blue)
    old_piece_positions_ints = piece_positions_ints
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


# A function to plant the enemy pieces (and remove the piece instance from the initial tile, that is, the tile we're moving from)
var piece_instances = {}
func plant_enemy(tile_position: Vector2, scene):
    if game_state == GameState.PLAYING:
        for i in range(0, len(piece_positions_ints) - 1, 2):
            var piece_positions_Vector2_list = []
            piece_positions_Vector2_list.append(Vector2(old_piece_positions_ints[i], old_piece_positions_ints[i+1]))
            if tile_position not in piece_positions_Vector2_list:
                # Remove the piece_instance from the initial tile
                var key = str(tile_position.x) + "," + str(tile_position.y)
                if piece_instance and piece_instances.has(key):
                    var piece_instance_to_remove = piece_instances[key]
                    remove_child(piece_instance_to_remove)
                    piece_instance_to_remove.queue_free() # Free th resources
                    piece_instances.erase(key) # Remove the piece instance from the dictionary
                # Plant the enemy pieces
                print("Planting enemy pieces...")
                var world_position = tilemap.map_to_local(tile_position)
                piece_instance = scene.instantiate()
                piece_instance.position = world_position
                add_child(piece_instance)
                # Save the piece_instance to a dictionary
                piece_instances[key] = piece_instance
    else:
        # Remove the piece_instance from the initial tile
        var key = str(tile_position.x) + "," + str(tile_position.y)
        if piece_instance and piece_instances.has(key):
            var piece_instance_to_remove = piece_instances[key]
            remove_child(piece_instance_to_remove)
            piece_instance_to_remove.queue_free() # Free th resources
            piece_instances.erase(key) # Remove the piece instance from the dictionary
        # Plant the enemy pieces
        print("Planting enemy pieces...")
        var world_position = tilemap.map_to_local(tile_position)
        piece_instance = scene.instantiate()
        piece_instance.position = world_position
        add_child(piece_instance)
        # Save the piece_instance to a dictionary
        piece_instances[key] = piece_instance
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


# Funktion to send data
func send_data(positions :Dictionary):
    rpc("receive_data", positions)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
        

# Function to receive data
@rpc("any_peer", "call_remote")
func receive_data(positions :Dictionary):
    update_other_pieces(positions)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func playing_team (team_ :TeamColor) -> void:
    team = team_
    $Background.set_color(TEAM_COLORS[int(team)])
    $Terminal/TerminalText.text += "\n>>> May the %s nation be victorious! We will destroy the %s nation!" %[TEAM_STRINGS[int(team)], TEAM_STRINGS[(int(team)+1) %2]]
    game_state = GameState.PLACEMENT
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func move_mouse():
    selected_instance.global_position = mouse_position
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func plant(tile_pos :Vector2, scene :PackedScene, num_of_pieces :int) -> int:
    if tile_pos in instances.keys(): return num_of_pieces

    var world_position: Vector2 = tilemap.map_to_local(tile_pos)
    var piece_instance = scene.instantiate()
    add_child(piece_instance)

    piece_instance.set_meta("piece_type", preview_type_str.get_slice('_', 0))
    piece_instance.global_position = world_position
    instances[tile_position] = piece_instance
    # $Terminal/TerminalText.text += '\n>>>' + 'Roger that!'

    send_data(instances)

    return num_of_pieces + 1
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func preview(preview):
    if mouse_position and tile_position:
        if team == TeamColor.RED:
            if mouse_position.y > 20 and -30  < tile_position.x and tile_position.x < -9:
                var mouse_position = get_global_mouse_position()
                var tile_position = tilemap.local_to_map(mouse_position)
                if tilemap and mouse_position:
                    if preview and mouse_position != last_mouse_position:
                        preview.global_position = tilemap.map_to_local(tile_position)
                        last_mouse_position = mouse_position
        elif team == TeamColor.BLUE:
            if mouse_position.y < -3 and -30  < tile_position.x and tile_position.x < -9:
                var mouse_position = get_global_mouse_position()
                var tile_position = tilemap.local_to_map(mouse_position)
                if tilemap and mouse_position:
                    if preview and mouse_position != last_mouse_position:
                        preview.global_position = tilemap.map_to_local(tile_position)
                        last_mouse_position = mouse_position
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##


func preview_piece():
    if unit_plant_id_counter == len(units): return
    if team == TeamColor.NONE: return
    var unit = units[unit_plant_id_counter]
    preview_type = unit_data[unit].preview[TEAM_STRINGS[int(team)]]
    preview_type_str = unit_data[unit].preview.string
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##

        
func hide_previews():

    for unit in unit_data.keys(): for color in TEAM_STRINGS:
        remove_child(unit_data[unit].preview[color].instance)
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
    

