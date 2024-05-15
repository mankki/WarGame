

extends Node2D


var _is_in :bool = false



func slide_in () -> void:
    if _is_in: return

    var tween = get_tree().create_tween()
    tween.tween_property(self, "global_position:x", global_position.x -400, 1.0).from_current()
    tween.tween_callback(func(): _is_in = true)
    # global_position.x -= 400


func slide_out () -> void:
    if not _is_in: return

    var tween = get_tree().create_tween()
    tween.tween_property(self, "global_position:x", global_position.x +400, 1.0).from_current()
    tween.tween_callback(func(): _is_in = false)
    # global_position.x += 400
