# Red's script

extends Node2D

var red_soldier_scene = load("res://PieceNodes/red_soldier_node.tscn")
var red_tank_scene = load("res://PieceNodes/red_tank_node.tscn")
var red_radar_scene = load("res://PieceNodes/red_radar_node.tscn")
var red_missile_scene = load("res://PieceNodes/red_missile_node.tscn")
var red_airplane_scene = load("res://PieceNodes/red_airplane_node.tscn")
var blue_soldier_scene = load("res://PieceNodes/blue_soldier_node.tscn")
var blue_tank_scene = load("res://PieceNodes/blue_tank_node.tscn")
var blue_radar_scene = load("res://PieceNodes/blue_radar_node.tscn")
var blue_missile_scene = load("res://PieceNodes/blue_missile_node.tscn")
var blue_airplane_scene = load("res://PieceNodes/blue_airplane_node.tscn")
var world_scene = load("res://Scenes/world.tscn")
var red_soldier_preview_scene = load("res://PiecePreviewNodes/red_soldier_preview_node.tscn")
var red_tank_preview_scene = load("res://PiecePreviewNodes/red_tank_preview_node.tscn")
var red_radar_preview_scene = load("res://PiecePreviewNodes/red_radar_preview_node.tscn")
var red_missile_preview_scene = load("res://PiecePreviewNodes/red_missile_preview_node.tscn")
var red_airplane_preview_scene = load("res://PiecePreviewNodes/red_airplane_preview_node.tscn")
var blue_soldier_preview_scene = load("res://PiecePreviewNodes/blue_soldier_preview_node.tscn")
var blue_tank_preview_scene = load("res://PiecePreviewNodes/blue_tank_preview_node.tscn")
var blue_radar_preview_scene = load("res://PiecePreviewNodes/blue_radar_preview_node.tscn")
var blue_missile_preview_scene = load("res://PiecePreviewNodes/blue_missile_preview_node.tscn")
var blue_airplane_preview_scene = load("res://PiecePreviewNodes/blue_airplane_preview_node.tscn")
var moving_range_scene = load("res://Scenes/moving_range_node.tscn")
var moving_range_script = load("res://scripts/moving_range_node.gd")
var messaging_scene = load("res://Scenes/messaging.tscn")

# Instantiate things
@onready var world_node = world_scene.instantiate()
@onready var red_soldier_preview = red_soldier_preview_scene.instantiate()
@onready var red_tank_preview = red_tank_preview_scene.instantiate()
@onready var red_radar_preview = red_radar_preview_scene.instantiate()
@onready var red_missile_preview = red_missile_preview_scene.instantiate()
@onready var red_airplane_preview = red_airplane_preview_scene.instantiate()
@onready var blue_soldier_preview = blue_soldier_preview_scene.instantiate()
@onready var blue_tank_preview = blue_tank_preview_scene.instantiate()
@onready var blue_radar_preview = blue_radar_preview_scene.instantiate()
@onready var blue_missile_preview = blue_missile_preview_scene.instantiate()
@onready var blue_airplane_preview = blue_airplane_preview_scene.instantiate()
@onready var moving_range = moving_range_scene.instantiate()
@onready var messaging = messaging_scene.instantiate()

var num_of_red_soldiers := 0
var num_of_red_tanks := 0
var num_of_red_radars := 0
var num_of_red_missiles := 0
var num_of_red_airplanes := 0
const max_red_soldiers := 1
const max_red_tanks := 1
const max_red_radars := 1
const max_red_missiles := 1
const max_red_airplanes := 1
var is_placement_in_progress := false
var radar_instance: Node2D
var tilemap: TileMap
var red_radars_count = 0
var max_radar_soldiers = 10
var last_mouse_position = Vector2.ZERO
var red_soldier_instance
var instances = []
var preview_type
var piece_positions = []
var preview_type_str = ""
var moving_range_center: Vector2
var tile_before_moving
var game_on = false
var tile_position
var mouse_position
var selected_instance: Node2D = null	# Viittaus valittuun instanssiin, jonka haluat liikuttaa.
var red_soldier_positions = []
var red_tank_positions = []
var red_radar_positions = []
var red_missile_positions = []
var red_airplane_positions = []
var red = false
var blue = false

func _ready():
	# Create the server
	# Create the world
	add_child(world_node)
	tilemap = world_node.get_node("TileMap") as TileMap
	# Add children
	add_child(red_soldier_preview)
	add_child(red_tank_preview)
	add_child(red_radar_preview)
	add_child(red_missile_preview)
	add_child(red_airplane_preview)
	add_child(blue_soldier_preview)
	add_child(blue_tank_preview)
	add_child(blue_radar_preview)
	add_child(blue_missile_preview)
	add_child(blue_airplane_preview)
	add_child(moving_range)
	add_child(messaging)
	
	### Signals
	# Determine the color of the player (red or blue)
	$Messaging.connect("red_signal", Callable(self, "playing_red"))
	$Messaging.connect("blue_signal", Callable(self, "playing_blue"))


func _process(delta):
	if  Network.peer and Network.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("Connected!")
	# Send pieces to blue's script
	save_pieces_to_send()
	mouse_position = get_global_mouse_position()
	tile_position = tilemap.local_to_map(mouse_position)
	if tilemap and mouse_position:
		preview_piece()
		preview(preview_type)
	if red == true and Input.is_action_just_pressed("ui_select") and mouse_position.y > 20 and -30  < tile_position.x and tile_position.x < -9:
		if num_of_red_soldiers < max_red_soldiers:
			num_of_red_soldiers = plant(tile_position, red_soldier_scene, num_of_red_soldiers)
		elif num_of_red_soldiers == max_red_soldiers and num_of_red_tanks < max_red_tanks:
			num_of_red_tanks = plant(tile_position, red_tank_scene, num_of_red_tanks)
		elif num_of_red_tanks == max_red_tanks and num_of_red_radars < max_red_radars:
			num_of_red_radars = plant(tile_position, red_radar_scene, num_of_red_radars)
		elif num_of_red_radars == max_red_radars and num_of_red_missiles < max_red_missiles:
			num_of_red_missiles = plant(tile_position, red_missile_scene, num_of_red_missiles)
		elif num_of_red_missiles == max_red_missiles and num_of_red_airplanes < max_red_airplanes:
			num_of_red_airplanes = plant(tile_position, red_airplane_scene, num_of_red_airplanes)
		elif num_of_red_airplanes == max_red_airplanes:
			game_on = true
	elif blue == true and Input.is_action_just_pressed("ui_select") and mouse_position.y < -3 and -30  < tile_position.x and tile_position.x < -9:
		if num_of_red_soldiers < max_red_soldiers:
			num_of_red_soldiers = plant(tile_position, blue_soldier_scene, num_of_red_soldiers)
		elif num_of_red_soldiers == max_red_soldiers and num_of_red_tanks < max_red_tanks:
			num_of_red_tanks = plant(tile_position, blue_tank_scene, num_of_red_tanks)
		elif num_of_red_tanks == max_red_tanks and num_of_red_radars < max_red_radars:
			num_of_red_radars = plant(tile_position, blue_radar_scene, num_of_red_radars)
		elif num_of_red_radars == max_red_radars and num_of_red_missiles < max_red_missiles:
			num_of_red_missiles = plant(tile_position, blue_missile_scene, num_of_red_missiles)
		elif num_of_red_missiles == max_red_missiles and num_of_red_airplanes < max_red_airplanes:
			num_of_red_airplanes = plant(tile_position, blue_airplane_scene, num_of_red_airplanes)
		elif num_of_red_airplanes == max_red_airplanes:
			game_on = true
	if Input.is_action_just_pressed("ui_select") and num_of_red_airplanes == max_red_airplanes and game_on == true:
			hide_previews()
			how_far_can_a_piece_move()
			moving_range_func()
	if selected_instance != null:
		# If an instance has been selected, follow the mouse
		mouse_position = get_global_mouse_position()
		tile_position = tilemap.local_to_map(mouse_position)
		moving_range.connect("mouse_button_left_held_over_rect", Callable(self, "move_mouse"))
		if Input.is_action_just_released("ui_select"):
			var new_position = selected_instance.global_position
			var new_tile_position = tilemap.local_to_map(new_position)
			### Send data to the other player
			# Data formatting
			var red_positions_ints = []
			for i in len(red_soldier_positions):
				red_positions_ints.append(red_soldier_positions[i].x)
				red_positions_ints.append(red_soldier_positions[i].y)
			for i in len(red_tank_positions):
				red_positions_ints.append(red_tank_positions[i].x)
				red_positions_ints.append(red_tank_positions[i].y)
			for i in len(red_radar_positions):
				red_positions_ints.append(red_radar_positions[i].x)
				red_positions_ints.append(red_radar_positions[i].y)
			for i in len(red_missile_positions):
				red_positions_ints.append(red_missile_positions[i].x)
				red_positions_ints.append(red_missile_positions[i].y)
			for i in len(red_airplane_positions):
				red_positions_ints.append(red_airplane_positions[i].x)
				red_positions_ints.append(red_airplane_positions[i].y)
				# Send data to the other player
			send_data(red_positions_ints)
			# Let's update the piece_positions list
			print("moving_range_center: ", tilemap.local_to_map(moving_range_center))
			for i in range(len(piece_positions)):
				var correction = + (moving_range.size.x - 20) / 40
				if piece_positions[i] == Vector2(tilemap.local_to_map(moving_range_center).x + correction, tilemap.local_to_map(moving_range_center).y + correction):
					print("Updating the piece_positions list...")
					piece_positions[i] = Vector2(new_tile_position.x, new_tile_position.y)
			selected_instance.global_position = tilemap.map_to_local(new_tile_position)
			selected_instance = null	
			moving_range.size = Vector2(0, 0)
			tile_position = new_tile_position

# Funktion to send data
func send_data(positions: Array):
	rpc("receive_instance_positions", positions)

# Function to receive data
func receive_data(positions: Array):
	print("Received instance positions:", positions)


func playing_red():
	red = true
	print("Playing red")

	
func playing_blue():
	blue = true
	print("Playing blue")


func save_pieces_to_send():
	red_soldier_positions = []
	red_tank_positions = []
	red_radar_positions = []
	red_missile_positions = []
	red_airplane_positions = []

	for position in piece_positions:
		if position in red_soldier_positions and red_soldier_positions.size() < max_red_soldiers:
			red_soldier_positions.append(position)
		elif position in red_tank_positions and red_tank_positions.size() < max_red_tanks:
			red_tank_positions.append(position)
		elif position in red_radar_positions and red_radar_positions.size() < max_red_radars:
			red_radar_positions.append(position)
		elif position in red_missile_positions and red_missile_positions.size() < max_red_missiles:
			red_missile_positions.append(position)
		elif position in red_airplane_positions and red_airplane_positions.size() < max_red_airplanes:
			red_airplane_positions.append(position)

func move_mouse():
	mouse_position = get_global_mouse_position()
	tile_position = tilemap.local_to_map(mouse_position)
	selected_instance.global_position = mouse_position
	print("Mouse moved!")

func plant(tile_position: Vector2, scene, num_of_pieces: int) -> int:
	if tile_position not in piece_positions:
		var world_position: Vector2 = tilemap.map_to_local(tile_position)
		var piece_instance = scene.instantiate()
		add_child(piece_instance)
		piece_instance.set_meta("piece_type", preview_type_str)
		piece_instance.global_position = world_position
		instances.append(piece_instance)
		piece_positions.append(tile_position)
		$Terminal/TerminalText.text += '\n>>>' + 'Roger that!'
		return num_of_pieces + 1
	else:
		return num_of_pieces

func preview(preview):
	if mouse_position and tile_position:
		if red == true:
			if mouse_position.y > 20 and -30  < tile_position.x and tile_position.x < -9:
				var mouse_position = get_global_mouse_position()
				var tile_position = tilemap.local_to_map(mouse_position)
				if tilemap and mouse_position:
					if preview and mouse_position != last_mouse_position:
						preview.global_position = tilemap.map_to_local(tile_position)
						last_mouse_position = mouse_position
		elif blue == true:
			if mouse_position.y < -3 and -30  < tile_position.x and tile_position.x < -9:
				var mouse_position = get_global_mouse_position()
				var tile_position = tilemap.local_to_map(mouse_position)
				if tilemap and mouse_position:
					if preview and mouse_position != last_mouse_position:
						preview.global_position = tilemap.map_to_local(tile_position)
						last_mouse_position = mouse_position

func preview_piece():
	if red == true:
		if num_of_red_soldiers < max_red_soldiers:
			preview_type = red_soldier_preview
			preview_type_str = 'soldier_preview'
		if num_of_red_soldiers == max_radar_soldiers and num_of_red_tanks < max_red_tanks:
			preview_type = red_tank_preview
			preview_type_str = 'tank_preview'
		if num_of_red_tanks == max_red_tanks and num_of_red_radars < max_red_radars:
			preview_type = red_radar_preview
			preview_type_str = 'radar_preview'
		if num_of_red_radars == max_red_radars and num_of_red_missiles < max_red_missiles:
			preview_type = red_missile_preview
			preview_type_str = 'missile_preview'
		if num_of_red_missiles == max_red_missiles and num_of_red_airplanes < max_red_airplanes:
			preview_type = red_airplane_preview
			preview_type_str = 'airplane_preview'
		if num_of_red_airplanes == max_red_airplanes:
			preview_type = null
	elif blue == true:
		if num_of_red_soldiers < max_red_soldiers:
			preview_type = blue_soldier_preview
			preview_type_str = 'soldier_preview'
		if num_of_red_soldiers == max_radar_soldiers and num_of_red_tanks < max_red_tanks:
			preview_type = blue_tank_preview
			preview_type_str = 'tank_preview'
		if num_of_red_tanks == max_red_tanks and num_of_red_radars < max_red_radars:
			preview_type = blue_radar_preview
			preview_type_str = 'radar_preview'
		if num_of_red_radars == max_red_radars and num_of_red_missiles < max_red_missiles:
			preview_type = blue_missile_preview
			preview_type_str = 'missile_preview'
		if num_of_red_missiles == max_red_missiles and num_of_red_airplanes < max_red_airplanes:
			preview_type = blue_airplane_preview
			preview_type_str = 'airplane_preview'
		if num_of_red_airplanes == max_red_airplanes:
			preview_type = null

func how_far_can_a_piece_move():
	var mouse_position = get_global_mouse_position()
	var tile_position = tilemap.map_to_local(tilemap.local_to_map(mouse_position))
	for instance in instances:
		if instance.global_position == tile_position:
			if instance.has_meta("piece_type"):
				var piece_type = instance.get_meta("piece_type")
				if piece_type == "soldier_preview":
					moving_range.size = Vector2(60, 60)
					return
				elif piece_type == "tank_preview":
					moving_range.size = Vector2(100, 100)
					return
				elif piece_type == "radar_preview":
					moving_range.size = Vector2(140, 140)
					return
				elif piece_type == "missile_preview":
					moving_range.size = Vector2(0, 0)
					return
				elif piece_type == "airplane_preview":
					moving_range.size = Vector2(180, 180)
					return
			
func moving_range_func():
	mouse_position = get_global_mouse_position()
	tile_position = tilemap.local_to_map(mouse_position)
	print("tile_position: ", tile_position)
	print("piece_positions: ", piece_positions)
	var tile_position_Vector2 = Vector2(tile_position.x, tile_position.y)
	if Input.is_action_just_pressed("ui_select") and tile_position_Vector2 in piece_positions:
		var correction = Vector2(-moving_range.size.x/2, -moving_range.size.y/2)
		moving_range.global_position = tilemap.map_to_local(tile_position) + correction
		moving_range_center = moving_range.position
		print("The moving range should now be visible")
		
func hide_previews():
	remove_child(red_soldier_preview)
	remove_child(red_tank_preview)
	remove_child(red_radar_preview)
	remove_child(red_missile_preview)
	remove_child(red_airplane_preview)
	remove_child(blue_soldier_preview)
	remove_child(blue_tank_preview)
	remove_child(blue_radar_preview)
	remove_child(blue_missile_preview)
	remove_child(blue_airplane_preview)
	

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Määritellään hiiren klikkauksen sijainti ja tarkistetaan osuuko se mihinkään instanssiin.
		var mouse_position = get_global_mouse_position()
		var clicked_tile_position = tilemap.local_to_map(mouse_position)
		
		for instance in instances:
			if tilemap.local_to_map(instance.global_position) == clicked_tile_position:
				# Tallennetaan viite valittuun instanssiin.
				selected_instance = instance
				return

