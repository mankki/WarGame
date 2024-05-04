
@tool
extends EditorScript


func _run():
    var root  = get_scene()
    var hbox = root.get_node("HBoxContainer/VBoxContainer")
    var character :int = 1
    for i in range(32):
        var label = Label.new()
        label.name = &"label_%s" %str(character +i)
        label.text = str(character +i)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.custom_minimum_size = Vector2(16, 20)
        hbox.add_child(label)
        label.set_owner(get_scene())
    get_scene().print_tree_pretty()
