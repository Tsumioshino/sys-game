extends Node

var SERVER_IP = 'localhost'
var SERVER_PORT = 10000
var MAX_PLAYERS = 3

var server_info = { lobby_id = 1, match_time = 300 }
var connected_players = {}
var pname = "sadge"
	
# Called when the node enters the scene tree for the first time.
remote func _ready():
	get_tree().connect("network_peer_connected", self, "_client_connection")

func _client_connection(id):
	rpc_id(id, "register_player", pname)
	
remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	connected_players[id] = info
	print(connected_players)

func _on_Button_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)

	get_tree().network_peer = peer
	print(get_tree().network_peer)


func _on_Button2_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	
	
#remote func start():

	
	
var players_done = []
remote func done_preconfiguring():
	var who = get_tree().get_rpc_sender_id()
	   # Here are some checks you can do, for example
	assert(get_tree().is_network_server())
	assert(who in connected_players) # Exists
	assert(not who in players_done) # Was not added yet
	players_done.append(who)
	if players_done.size() == connected_players.size():
		rpc("post_configure_game")

#remote func post_configure_game():
#	# Only the server is allowed to tell a client to unpause
#	if 1 == get_tree().get_rpc_sender_id():
#		get_tree().set_pause(false)
#		print("why do i hear boss music")
		
func _on_Button3_pressed():
	var peerId = get_tree().get_network_unique_id()

	# Create the world scene instance
	var world = load("res://World.tscn").instance()
	get_node("/root/Main").add_child(world)

	# Create the player instance for the server
	var player = preload("res://Player2.tscn").instance()
	player.set_name(str(peerId))
	player.set_network_master(peerId)
	get_node("/root/Main").add_child(player)

	# Iterate through connected players and create player instances for each
	var counter = 1
	for p in connected_players:
		var player2 = preload("res://Player2.tscn").instance()
		player2.set_name(str(p))
		player2.set_network_master(p)
		
		# Position players in the world (you may need to adjust this logic)
		player2.position = get_node("/root/Main/World/Spawn/%d" % counter).position
		counter += 1
		
		get_node("/root/Main").add_child(player2)

	# Set refuse_new_network_connections to prevent new connections during gameplay
	get_tree().set_refuse_new_network_connections(true)

	# Inform clients about the world creation using an RPC
	rpc("initialize_world", peerId)

# This function is called on clients via an RPC to create the same world
remote func initialize_world(serverId):
	# Create the world scene instance
	var world = load("res://World.tscn").instance()
	get_node("/root/Main").add_child(world)

	# Create the player instance for the client
	var peerId = get_tree().get_network_unique_id()
	var player = preload("res://Player2.tscn").instance()
	player.set_name(str(peerId))
	player.set_network_master(peerId)
	get_node("/root/Main").add_child(player)
	
	var counter = 1
	for p in connected_players:
		var player2 = preload("res://Player2.tscn").instance()
		player2.set_name(str(p))
		player2.set_network_master(p)
		
		# Position players in the world (you may need to adjust this logic)
		player2.position = get_node("/root/Main/World/Spawn/%d" % counter).position
		counter += 1
		
		get_node("/root/Main").add_child(player2)

	# Set refuse_new_network_connections to prevent new connections during gameplay
	get_tree().set_refuse_new_network_connections(true)
