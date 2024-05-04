extends Node

var peer: ENetMultiplayerPeer

func _ready():
	pass
	
# Make sure to properly configure the function to be called remotely
func _init():
	pass
	
func create_server(port: int):
	print("Creating the server...")
	# Start as server.
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		print("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer

func create_client(ip: String, port: int):
	# Start as client.
	print("Creating the client...")
	if ip == "":
		OS.alert("Need a remote to connect to.")
		print("Need a remote to connect to.")
		return
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		print("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	print("Connected to server!")
