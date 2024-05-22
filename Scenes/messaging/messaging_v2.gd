

extends Control

signal red_signal
signal blue_signal
var connection_established = false

@export var _Received :TextEdit

@export var _Username :LineEdit
@export var _Message :LineEdit
@export var _Port :LineEdit
@export var _Ip :LineEdit

@export var _Host :Button
@export var _Join :Button

@export var _Connecting :Control
@export var _Messaging :Control


func _ready () -> void:
    _Host.pressed.connect(_on_host_pressed)
    _Join.pressed.connect(_on_join_pressed)

    mouse_entered.connect(func(): _Messaging.visible = true)
    mouse_exited.connect(func(): _Messaging.visible = false)


func _process(delta):
    if connection_established == false and Network.peer and Network.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        connection_established = true
        _Received.text += "\n>>>" + "Connection established!"


func send_message():
    var message = _Message.text
    var username = _Username.text
    rpc("receive_message", username + ": " + message)
    _Message.text = ''
    print("Message sent!")


@rpc("any_peer", "call_local")
func receive_message(message: String):
    if _Received.text == '':
        _Received.text = "> " + message
    else:
        _Received.text += "\n> " + message
    print("Message received: ", message)


func _on_host_pressed():
    emit_signal("red_signal")
    var port = int(_Port.text)
    Network.create_server(port)
    _Host.disabled = true
    _Join.disabled = true
    _Connecting.visible = false


func _on_join_pressed():
    emit_signal("blue_signal")
    # var peer = ENetMultiplayerPeer.new()
    var ip = _Ip.text
    var port = int(_Port.text)
    Network.create_client(ip, port)
    _Host.disabled = true
    _Join.disabled = true
    _Connecting.visible = false


func _input(event):
    if event.is_action_pressed("ui_accept"):
        send_message()