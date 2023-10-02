extends Node

var SERVER_IP = '192.168.0.1'
var SERVER_PORT = 8080
var MAX_PLAYERS = 3
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func create_client():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	create_client() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
