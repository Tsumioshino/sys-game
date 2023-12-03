extends KinematicBody2D

# Atributos base
var atk = 3
var max_health = 10
var current_health = 10
var defense = 2
signal health_depleted
# Physics related
export var direction = Vector2.ZERO
var velocity = 0
var spd_scaling = 3
var spd = 300 # Velocity * spd_scaling



# importantes pro rpc da vida
signal position_changed(new_pos)
signal apply_spd_negative
signal spd_scaling_changed(new_spd)
signal state_changed(new_state)

func _on_Player_spd_scaling_changed(new_spd):
	spd = 100 * new_spd	if new_spd > 0 else 0


# Bonus
enum Direction { LEFT, RIGHT, UP, DOWN }
var look_at = Direction.RIGHT

onready var animation_tree = get_node("%AnimationTree")

var timeratk = Timer.new()

func _ready():
	connect("spd_scaling_changed", self, "_on_Player_spd_scaling_changed")
	connect("health_depleted", self, "_on_Player_health_depleted")
	connect("direction_changed", self, "_on_Player_direction_changed")
		
	animation_tree.set_animation_player(player_class[class_count]) 
	scale.x *= -1 if look_at == Direction.LEFT else 1
	animation_tree.set("parameters/conditions/not_movement", true)
	animation_tree.active = true
	add_child(timeratk)
	add_child(timerdash)
	
# Efeitos
signal inventory_buff_added(buff)
var player_buffs = []
var player_debuffs = []

# Classes
enum Class { WARRIOR, THIEF }
var player_class = ["%WARRIOR", "%THIEF"]
var class_count = 0

func _class_swap_mechanic_handler():
	if Input.is_action_just_pressed("change_class"):
		apply_effect_speed_positive(self)
		class_count += 1 
		if class_count > player_class.size() - 1:
			class_count = 0
		animation_tree.set_animation_player(player_class[class_count]) 

var consecutiveKeyPresses = 0
var desiredKeyPresses = 2	

func _attack_mechanic_handler():
	if Input.is_action_pressed("attack"):
		if Input.is_action_just_pressed("attack"):
			if timeratk.is_stopped():
				animation_tree.set("parameters/conditions/consecutive_atk", false)
				emit_signal("state_changed", "consecutive_atk", false)
				consecutiveKeyPresses = 0
				timeratk.start(0.4)
				timeratk.set_one_shot(true)
			if (timeratk.get_time_left() > 0):
				consecutiveKeyPresses += 1
			else:
				consecutiveKeyPresses = 0
		animation_tree.set("parameters/conditions/attack", true)
		emit_signal("state_changed", "attack", true)
		if consecutiveKeyPresses >= desiredKeyPresses:
			animation_tree.set("parameters/conditions/consecutive_atk", true)
			emit_signal("state_changed", "consecutive_atk", true)
	else:
		animation_tree.set("parameters/conditions/attack", false)
		animation_tree.set("parameters/conditions/consecutive_atk", false)
		emit_signal("state_changed", "attack", false)
		emit_signal("state_changed", "consecutive_atk", false)
	

var timerdash = Timer.new()
var consecutiveKeyPresses2 = 0
var desiredKeyPresses2 = 2	
var dash_press = false
var movement_actions = ["left", "right", "up", "down"]

func activate_dash():
	var dash_direction = direction
	var dash_distance = 200
	var dash_duration = 0.5
	var dash_target_position = global_position + dash_direction * dash_distance
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position, 0)
	tween.tween_property(self, "global_position", dash_target_position, dash_duration)
	# TODO: revisar que eu esqueci algumas propriedades
	tween.tween_property(self, "velocity", velocity, 0)
	tween.tween_property(self, "velocity", 0, dash_duration)
	animation_tree.set("parameters/conditions/dash", true)
	emit_signal("state_changed", "dash", true)
	
	
func _dodge_handler():
	if Input.is_action_just_pressed("dodge") and $DodgeTimer.get_time_left() <= 0:
		$DodgeTimer.start(5)
		animation_tree.set("parameters/conditions/dodge", true)
		emit_signal("state_changed", "dodge", true)
	else:
		animation_tree.set("parameters/conditions/dodge", false)
		emit_signal("state_changed", "dodge", false)

func _defense_handler():
	if Input.is_action_pressed("defend"):
		animation_tree.set("parameters/conditions/defense", true)
		emit_signal("state_changed", "defense", true)
	else:
		animation_tree.set("parameters/conditions/defense", false)
		emit_signal("state_changed", "defense", false)


func _dash_handler(input_direction):
	if was_any_input_action_just_pressed(movement_actions):
		if !animation_tree.get("parameters/conditions/dash"):
			if timerdash.is_stopped():
				animation_tree.set("parameters/conditions/dash", false)
				emit_signal("state_changed", "dash", false)
				consecutiveKeyPresses2 = 0
				timerdash.start(0.4)
				timerdash.set_one_shot(true)
			if (input_direction == direction) and (timerdash.get_time_left() > 0):
				consecutiveKeyPresses2 +=  1
			else:
				animation_tree.set("parameters/conditions/dash", false)
				emit_signal("state_changed", "dash", false)
				consecutiveKeyPresses2 = 0
			if consecutiveKeyPresses2 >= desiredKeyPresses2:
				activate_dash()
	else:
		animation_tree.set("parameters/conditions/dash", false)
		emit_signal("state_changed", "dash", false)
		
signal direction_changed(old_value, new_value)

remote func _on_Player_direction_changed(old_direction, new_direction):
	print("hi")
	if new_direction.x > 0:
		if look_at != Direction.RIGHT:
			scale.x *= -1
			look_at = Direction.RIGHT
	elif new_direction.x < 0:
		if look_at != Direction.LEFT:
			scale.x *= -1
			look_at = Direction.LEFT
		
func _movement_mechanic_handler():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction:
		_dash_handler(input_direction)
		if direction.x != input_direction.x:
			emit_signal("direction_changed", direction, input_direction)
		direction = input_direction 
		
		animation_tree.set("parameters/conditions/not_movement", false)
		emit_signal("state_changed", "not_movement", false)
		animation_tree.set("parameters/conditions/movement", true)
		emit_signal("state_changed", "movement", true)
	else:
		animation_tree.set("parameters/conditions/not_movement", true)
		emit_signal("state_changed", "not_movement", true)
		animation_tree.set("parameters/conditions/movement", false)
		emit_signal("state_changed", "movement", false)

		if animation_tree.get("parameters/conditions/dash"):
			activate_dash()
	return input_direction	

func _input(_event):
	if is_network_master():
		_class_swap_mechanic_handler()
		_attack_mechanic_handler()
		_defense_handler()
		_defense_handler()
		_dodge_handler()
		check_health()

func was_any_input_action_just_pressed(actions):
	for action in actions:
		if Input.is_action_just_pressed(action):
			return true
	return false

func _physics_process(_delta):
	if is_network_master():
		var input_direction = _movement_mechanic_handler()
		velocity = input_direction * spd
		emit_signal("position_changed", global_position)
		move_and_slide(velocity)

	
func take_damage(dmg):
	print("this hurts")
	current_health -= dmg
	print(current_health)
	if current_health <= 0:
		emit_signal("health_depleted")
		
signal player_dodged

func _on_Player_player_dodged():
	$DodgeTimer.start(0.1) # Replace with function body.
	print($DodgeTimer.get_time_left())
	
# TODO: ESSA E A AREA DA ESPADA NAO DO CORPO DO JOGADOR ICANT
func _on_AtaqueHit_body_entered(body):
	var body_state = body.animation_tree.get("parameters/playback").get_current_node()
	print(body_state)	
#	print(body)	
	if body.is_in_group("hurtbox") and body != self:
		if body_state == "dodge":
			print("hey i dodged man")
			body.emit_signal("player_dodged")
			return
		elif body_state == "defense":
			body.take_damage(atk - defense)
			return
			
		print("where dmg")
		body.take_damage(atk)    

func _on_AtaqueHit2_body_entered(body):
	var dodge_state = body.animation_tree.get("parameters/playback").get_current_node()
	if body.is_in_group("hurtbox") and body != self:
		if dodge_state == "dodge":
			body.emit_signal("player_dodged")
			return
		body.apply_effect_speed_negative() 
		print(body.get_name())
		emit_signal("apply_spd_negative", body.get_name().to_int())
		
func apply_effect_speed_positive(_player):
	var buff_instance = load("res://player/Effect.tscn").instance()
	var spd_buff = buff_instance.get_node("Buff/SPD_BUFF").duplicate()
	$Effects.add_child(spd_buff)

remote func apply_effect_speed_negative():
	var debuff_instance = load("res://player/Effect.tscn").instance()
	var spd_debuff = debuff_instance.get_node("Debuff/SPD_DEBUFF").duplicate()
	$Effects.add_child(spd_debuff)
	player_debuffs.append(spd_debuff)

signal revive
func _on_Player_health_depleted():
	if is_network_master():
		set_process_input(false)
		animation_tree.set("parameters/conditions/death", true)
		emit_signal("state_changed", "death", true)
		set_physics_process(false)
		$RespawnTimer.start()


func _on_RespawnTimer_timeout():
	if is_network_master():
		set_process_input(true)
		set_physics_process(true)
#		animation_tree.set_active(false)
#		animation_tree.set_active(true)
		animation_tree.set("parameters/conditions/death", false)
		emit_signal("state_changed", "death", false)
		emit_signal("revive")


mastersync func _on_Player_revive():
	current_health = max_health
# A habilidade 'Sangue de Guerreiro' 
# deve ser uma habilidade única da classe Guerreiro
# classificada como passiva, self-target, 
# e deve afetar apenas o jogador em questão, 
# que aumenta status do jogador proporcional à perda dos pontos de vida e, 
# quando os pontos de vida estão abaixos de certo limiar,
# ativa um efeito ativo de cura passiva que 
# para somente quando o jogador morre 
# ou quando os pontos de vida alcançam 100
func check_health():
	if current_health <= (max_health * 0.1) and animation_tree.get_animation_player() == "%WARRIOR" and not sangueGuerreiroActivated:
		emit_signal("sangue_de_guerreiro")
		
signal sangue_de_guerreiro
signal health_recovered
var sangueGuerreiroActivated = false

func recover_health():
	while current_health < max_health:
		current_health += 1
		print("my current_health is")
		print(current_health)
		yield(get_tree().create_timer(4.0), "timeout")

func apply_bonus_effects():
	atk += 10
	print("ur atk is come")
	
func remove_bonus_effects():
	atk -= 10
	print("ur atk is gone")
	
func _on_Player_sangue_de_guerreiro():
	assert(animation_tree.get_animation_player() == "%WARRIOR")
	assert(not sangueGuerreiroActivated)
	apply_bonus_effects()
	yield(recover_health(), "completed")
	remove_bonus_effects()
	
# A habilidade 'Mordida!'
# deve ser uma habilidade única da classe Gatuno
# classificada como ativa, single-target, e deve afetar ambos os jogadores, 
# infligindo certa quantidade de dano à ambos jogadores, 
# e infligindo efeito negativo no oponente que, 
# conforme mais instâncias da habilidade 'Mordida!' são utilizadas, 
# o dano causado à quem possui o debuff aumenta.
var cooldown = 3 # segundos

signal mordida
# var sangueGuerreiroActivated = false

#func _on_Player_mordida():
#	assert(animation_tree.get_animation_player() == "%THIEF") # Replace with function body.
#	apply_mordida(self, body)
