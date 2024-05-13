extends ColorRect

signal mouse_button_left_held_over_rect

var is_mouse_button_left_pressed = false

func _ready():
    set_process_input(true)
    set_process(true)

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        is_mouse_button_left_pressed = event.pressed


func _process(delta):
    if is_mouse_button_left_pressed:
        var mouse_pos = get_global_mouse_position()
        if get_global_rect().has_point(mouse_pos):
            emit_signal("mouse_button_left_held_over_rect")


func show_range (range_ :int) -> void:
    var x :float = 20 + range_*20
    size = Vector2(x, x)
    visible = true


func hide_range () -> void:
    visible = false
