extends ColorRect

# Signaalin määritelmä
signal mouse_button_left_held_over_rect

# Boolean-arvo, joka kertoo onko vasen hiiren nappi painettuna
var is_mouse_button_left_pressed = false

func _ready():
	# Varmista, että input ja process ovat käytössä
	set_process_input(true)
	set_process(true)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_mouse_button_left_pressed = event.pressed

func _process(delta):
	if is_mouse_button_left_pressed:
		var mouse_pos = get_global_mouse_position()
		# Tarkista, onko hiiri ColorRectin päällä
		if get_global_rect().has_point(mouse_pos):
			emit_signal("mouse_button_left_held_over_rect")
