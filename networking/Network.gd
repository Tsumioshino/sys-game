extends Node

var SERVER_IP = 'localhost'
var SERVER_PORT = 10000
var MAX_PLAYERS = 4

var server_info = { lobby_id = 1, match_time = 300 }
var connected_players = []
var pname = "sadge"
	
remote func _ready():
	get_tree().connect("network_peer_connected", self, "_client_connection")
	get_tree().connect("server_disconnected", self, "_leave_room")
		
# Client-server-specifics
## Todos os nós precisam saber de todos os jogadores
func _client_connection(id):
	rpc_id(id, "register_player")

remote func register_player():
	connected_players.append(get_tree().get_rpc_sender_id())

# Server-specifics
# Inicializa o Jogo (apenas Servidor)
func _on_Button3_pressed():
	var peerId = get_tree().get_network_unique_id()
	if (peerId != 1):
		return;
		

	rpc_id(0, "world_initialized")
	get_tree().set_refuse_new_network_connections(true)
	
	
remote func change_player_pos(new_pos):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "update_player_pos", sender_id, new_pos)
			
func _on_position_changed(new_pos):
	rpc_unreliable_id(1, "change_player_pos", new_pos)

# This function is called on clients via an RPC to create the same world
sync func world_initialized():
	var peerId = get_tree().get_network_unique_id()
	connected_players.append(peerId)
	connected_players.sort()
	var world = load("res://world-levels-related/World.tscn").instance()
	
	var game_logic = get_node("/root/Main/GameLogic")
	game_logic.add_child(world)
	get_node("/root/Main/UILogic").queue_free()

	var counter = 1
	print(connected_players)
	for p in connected_players:
		var player = preload("res://player/Player.tscn").instance()
		player.connect("position_changed", self, "_on_position_changed") #!!!!
		player.set_name(str(p))
		player.set_network_master(p)
		if p == peerId:
			player.get_node("Camera2D")._set_current(true) 
		# Position players in the world (you may need to adjust this logic)
		player.position = get_node("/root/Main/GameLogic/World/Spawn/%d" % counter).position
		counter += 1
		game_logic.add_child(player)
	
	rpc_id(peerId, "world_created")
## Cliente morre quando servidor morre
func _leave_room():
	get_node("/root/").remove_child(get_node("Main"))
	get_tree().change_scene('res://Main.tscn')
	
# Criação do Servidor
func _on_Button_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)

	get_tree().network_peer = peer
	print(get_tree().network_peer)

# Criação do Cliente (servidor precisa existir)
func _on_Button2_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
			
	
var players_done = []
remote func world_created():
	var who = get_tree().get_rpc_sender_id()
	assert(who in connected_players) # Exists
	assert(not who in players_done) # Was not added yet
	players_done.append(who)
	print(players_done)
#	if players_done.size() == connected_players.size():
#		rpc("post_configure_game")

#remote func post_configure_game():
#	# Only the server is allowed to tell a client to unpause
#	if 1 == get_tree().get_rpc_sender_id():
#		get_tree().set_pause(false)
#		print("why do i hear boss music")
