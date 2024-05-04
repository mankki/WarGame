

extends VBoxContainer


func print_message (message_ :String) -> void:
    $TerminalText.text += "\n>>> %s" %message_
    $TerminalText.scroll_vertical += 1_000_000
#...

    ## - --- --- --- --- ,,, ... ''' qFp ''' ... ,,, --- --- --- --- - ##