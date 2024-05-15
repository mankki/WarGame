

extends Control

@onready var terminal :TextEdit = $MarginContainer/TerminalText

func print_message (message_ :String) -> void:
	terminal.text += "\n>>> %s" %message_
	terminal.scroll_vertical += 1_000_000
#...

	## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
