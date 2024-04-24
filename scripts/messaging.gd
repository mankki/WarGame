extends Node2D

signal red_signal
signal blue_signal
var connection_established = false

func _ready():
	rpc_config("receive_message", MultiplayerAPI.RPC_MODE_ANY_PEER)

func _process(delta):
	if connection_established == false and Network.peer and Network.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		connection_established = true
		$ReceivedMessages.text += "\n>>>" + "An enemy found!"
		
func _on_send_pressed():
	send_message()

func send_message():
	var message = $Message.text
	var username = $Username.text
	rpc("receive_message", username + ": " + message)
	$Message.text = ''
	print("Message sent!")

@rpc("any_peer", "call_local")
func receive_message(message: String):
	if $ReceivedMessages.text == '':
		$ReceivedMessages.text = "> " + message
	else:
		$ReceivedMessages.text += "\n> " + message
	print("Message received: ", message)


func _on_host_pressed():
	emit_signal("red_signal")
	var port = int($Port.text)
	Network.create_server(port)


func _on_join_pressed():
	emit_signal("blue_signal")
	# var peer = ENetMultiplayerPeer.new()
	var ip = $Ip.text
	var port = int($Port.text)
	Network.create_client(ip, port)
