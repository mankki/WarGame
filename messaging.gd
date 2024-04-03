extends Node2D

func _ready():
	pass

func _process(delta):
	pass

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
	var port = int($Port.text)
	Network.create_server(port)


func _on_join_pressed():
	# var peer = ENetMultiplayerPeer.new()
	var ip = $Ip.text
	var port = int($Port.text)
	Network.create_client(ip, port)
