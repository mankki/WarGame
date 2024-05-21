

extends Control

@export var terminal :TextEdit
@export var unit_overview :Control



func print_message (message_ :String) -> void:
    terminal.text += "\n>>> %s" %message_
    terminal.scroll_vertical += 1_000_000


func display_overview (message_ :String, show_ :bool) -> void:
    unit_overview.visible = show_
    unit_overview.update_text(message_)
