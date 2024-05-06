

extends VBoxContainer

@onready var terminal :TextEdit = $PanelContainer/MarginContainer/TerminalText

func print_message (message_ :String) -> void:
    terminal.text += "\n>>> %s" %message_
    terminal.scroll_vertical += 1_000_000
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##