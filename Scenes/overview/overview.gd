extends Control

@onready var overview :TextEdit = $MarginContainer/OverviewText

func print_message (message_ :String) -> void:
	overview.text += "\n %s" %message_
	overview.scroll_vertical += 1_000_000
	
func erase_message () -> void:
	overview.text = ''
	overview.scroll_vertical += 1_000_000
#...

	## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##
