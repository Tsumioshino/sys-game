extends Node

var SERVER_IP = 'localhost'
var SERVER_PORT = 10000
var MAX_PLAYERS = 4

var server_info = { lobby_id = 1, match_time = 300 }
var player_info
var players_info = {}
var connected_players = []
var cs: Button = null;
var cc: Button = null;
var sg: Button = null;

remote func _ready():
	cs = get_node("/root/Main/UILogic/HBoxContainer/VBoxContainer/CS")
	cs.connect("pressed", self, "_create_server")
	sg = get_node("/root/Main/UILogic/HBoxContainer/VBoxContainer/SG")
	sg.connect("pressed", self, "_close_new_connection")
	cc = get_node("/root/Main/UILogic/HBoxContainer/VBoxContainer/CC")
	sg.set_disabled(true);
	get_tree().connect("network_peer_connected", self, "_client_connection")
		
# Criação do Servidor
func _create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	cc.set_disabled(true);
	sg.set_disabled(false);
	print(peer)
	
func _client_connection(id):
	rpc_id(id, "register_player")

remotesync func register_info(p_info):
	var sender_id = get_tree().get_rpc_sender_id()
	for p in connected_players:
		if (p == sender_id):
			players_info[sender_id] = p_info
	
remote func register_player():
	connected_players.append(get_tree().get_rpc_sender_id())

# Server-specifics
# Inicializa o Jogo (apenas Servidor)
func _close_new_connection():
	var peerId = get_tree().get_network_unique_id()
	if (peerId != 1):
		return;
	rpc("_initialize_world")
	print("rpc was sent")
	get_tree().set_refuse_new_network_connections(true)

remotesync func send_info():
	print("wicked sick")
	rpc_id(1, "register_info", player_info)
	
# This function is called on clients via an RPC to create the same world
remotesync func _initialize_world():
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
		players_info[p_id] = player
		#rpc("send_info")
	#get_tree().set_pause(true)
	print("????")

	rpc_id(1, "world_created")
	
var players_done = []
remotesync func world_created():
	print("hello")
	var who = get_tree().get_rpc_sender_id()
	assert(who in connected_players) # Exists
	assert(not who in players_done) # Was not added yet
	players_done.append(who)
	print(players_done)
	print(players_done.size())
	if players_done.size() == connected_players.size():
		print("game start!")
		rpc("start_game")

func start_game():
	get_tree().set_pause(false)
	
func configure_player(player_id):
	var player = preload("res://player/Player.tscn").instance()
	connect_signals(player)
	player.set_name(str(player_id))
	player.set_network_master(player_id)
	return player
	
func connect_signals(player):
	player.connect("direction_changed", self, "_on_direction_changed")
	player.connect("position_changed", self, "_on_position_changed") #!!!!
	player.connect("apply_spd_negative", self, "_on_debuff_apply") #!!!!
	player.connect("spd_scaling_changed", self, "_on_spd_scaling_changed") #!!!!
	player.connect("state_changed", self, "_on_state_changed") #!!!!
	player.connect("revive", self, "_on_revive") #!!!!
# Atributos 
## Direcao
remotesync func update_player_dir(id, old_dir, new_dir):
	print("okish")
	players_info[id]._on_Player_direction_changed(old_dir, new_dir)

remotesync func change_player_dir(old_pos, new_pos):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "update_player_dir", sender_id, old_pos, new_pos)

func _on_direction_changed(old_pos, new_pos):
	print("huh")
	rpc_unreliable_id(1, "change_player_dir", old_pos, new_pos)
	
## Posicao
remotesync func update_player_pos(id, pos):
	players_info[id].position = pos
	
remotesync func change_player_pos(new_pos):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "update_player_pos", sender_id, new_pos)
			
func _on_position_changed(new_pos):
	rpc_unreliable_id(1, "change_player_pos", new_pos)
	
## Debuffs
remotesync func update_player_debuff(id):
	print("hiiiiiii")
	players_info[id].apply_effect_speed_negative()

remotesync func apply_debuff_player(id):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			print("Step 2")
			rpc_unreliable_id(player_id, "update_player_debuff", id)
	
func _on_debuff_apply(id):
	print("Step 1")
	rpc_unreliable_id(1, "apply_debuff_player", id)

## Debuffs
remotesync func update_player_spd_scale(id, spd_scale):
	print("hiiiiiii")
	players_info[id].spd_scaling = spd_scale

remotesync func apply_spd_scaling_player(spd_scale):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			print("Step 2")
			rpc_unreliable_id(player_id, "update_player_spd_scale", sender_id, spd_scale)
	
func _on_spd_scaling_changed(spd_scale):
	print("Step 1")
	rpc_unreliable_id(1, "apply_spd_scaling_player", spd_scale)

## Estados
remotesync func update_player_state(id, state, truthy_value):
	var format_state = "parameters/conditions/%s"
	var actual_state = format_state % state
	players_info[id].animation_tree.set(actual_state, truthy_value)

remotesync func apply_state_player(state, truthy_value):
	var sender_id = get_tree().get_rpc_sender_id()
	for player_id in connected_players:
		if player_id != sender_id:
			rpc_unreliable_id(player_id, "update_player_state", sender_id, state, truthy_value)
	
func _on_state_changed(state, truthy_value):
	rpc_unreliable_id(1, "apply_state_player", state, truthy_value)
	
remotesync func update_player_revive(id, pos):
	print("welp")
	players_info[id].position = pos
	players_info[id].animation_tree.set_active(false)
	players_info[id].animation_tree.set_active(true)
	players_info[id]._on_Player_revive()
	
remotesync func apply_revive_player():
	var sender_id = get_tree().get_rpc_sender_id()
	var counter = players_done.find(sender_id) + 1
	var position = get_node("/root/Main/GameLogic/World/Spawn/%d" % counter).position
	for player_id in connected_players:
		rpc_id(player_id, "update_player_revive", sender_id, position)
	
func _on_revive():
	print("????")
	rpc_id(1, "apply_revive_player")
	
