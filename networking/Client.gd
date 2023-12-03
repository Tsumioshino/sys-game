extends Node

var SERVER_IP = 'localhost'
var SERVER_PORT = 10000
var connected_players = []
var players_info = {}

func _ready():
	get_node("/root/Main/UILogic/HBoxContainer/CC").connect("pressed", self, "_create_client")
#	get_tree().connect("connected_to_server", self, "_send_info")
	get_tree().connect("server_disconnected", self, "_leave_room")
		
# Client-server-specifics
# Criação do Cliente (servidor precisa existir)
func _create_client():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
	print(peer)
	
remote func register_player():
	connected_players.append(get_tree().get_rpc_sender_id())

remote func send_info():
	print("wicked sick")
	rpc_id(1, "register_info", players_info)

# This function is called on clients via an RPC to create the same world
puppet func _initialize_world():
	var peerId = get_tree().get_network_unique_id()
	connected_players.append(peerId)
	connected_players.sort()
	var world = load("res://world-levels-related/World.tscn").instance()
	
	var game_logic = get_node("/root/Main/GameLogic")
	game_logic.add_child(world)
	get_node("/root/Main/UILogic").queue_free()
	var counter = 1
	for p_id in connected_players:
		var player = configure_player(p_id) 
		player.position = get_node("/root/Main/GameLogic/World/Spawn/%d" % counter).position
		if p_id == peerId:
			player.get_node("Camera2D")._set_current(true) 
		counter += 1
		game_logic.add_child(player)
	get_tree().set_pause(true)
	rpc_id(1, "world_created")
	
puppet func start_game():
	get_tree().set_pause(false)
	
func configure_player(player_id):
	var player = preload("res://player/Player.tscn").instance()
	connect_signals(player)
	player.set_name(str(player_id))
	player.set_network_master(player_id)

	return player
	
## Cliente morre quando servidor morre
func _leave_room():
	get_node("/root/").remove_child(get_node("Main"))
	get_tree().change_scene('res://Main.tscn')
	
func connect_signals(player):
	player.connect("position_changed", self, "_on_position_changed") #!!!!
	player.connect("apply_spd_negative", self, "_on_debuff_apply") #!!!!
	
# Atributos
## Posicao
remote func update_player_pos(id: int, pos: Vector2) -> void:
	players_info[id].position = pos
# Client-specifics
remote func change_player_pos(new_pos):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "update_player_pos", sender_id, new_pos)
	
func _on_position_changed(new_pos):
	rpc_unreliable_id(1, "change_player_pos", new_pos)

## Debuffs
remote func update_player_debuff(id):
	print("hiiiiiii")
	players_info[id].apply_effect_speed_negative()

remote func apply_debuff_player():
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			print("Step 2")
			rpc_unreliable_id(player_id, "update_player_debuff", sender_id)
	
func _on_debuff_apply():
	print("Step 1")
	rpc_unreliable_id(1, "apply_debuff_player")
	
remote func update_player_spd_scale(id, spd_scale):
	print("hiiiiiii")
	players_info[id].spd_scaling = spd_scale

remote func apply_spd_scaling_player(spd_scale):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			print("Step 2")
			rpc_unreliable_id(player_id, "update_player_spd_scale", sender_id, spd_scale)
	
func _on_spd_scaling_changed(spd_scale):
	print("Step 1")
	rpc_unreliable_id(1, "apply_spd_scaling_player", spd_scale)
