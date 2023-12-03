extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# Called when the node enters the scene tree for the first time.

	
var server_info = { lobby_id = 1, match_time = 300 }
var connected_players = {}

func _client_connection(id):
	print("hi")
	rpc_id(id, "register_player", server_info)
	
func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	connected_players[id] = info
	print(connected_players)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func test3():
	return connected_players

# Called when the node enters the scene tree for the first time.
remote func _ready():
	print("test")
	get_tree().connect("network_peer_connected", self, "_client_connection")
	print(get_tree().get_network_unique_id())
	var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = load("res://World.tscn").instance()
	add_child(world)

	var player_pos = get_node("World/Spawn/1").position
	var player = load("res://Player2.tscn").instance()

	player.position = player_pos
	# Load my player
	player.set_name(str(selfPeerID))
	player.set_network_master(selfPeerID) # Will be explained later
	add_child(player)
	# Load other players
	for p in get_node("%Lobby").test3():
		player_pos = get_node("World/Spawn/2").position
		var player2 = load("res://Player2.tscn").instance()
		player2.position = player_pos
		# Load my player
		player2.set_name(str(p))
		player2.set_network_master(p) # Will be explained later
		add_child(player)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	get_tree().get_rpc_sender_id()
