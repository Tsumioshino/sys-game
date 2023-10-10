extends KinematicBody2D

# Atributos base
export var atk = 1
export var health = 5

# Physics related
export var direction = Vector2.ZERO
var velocity = 0
var spd_scaling = 3
var spd = 300 # Velocity * spd_scaling

signal spd_scaling_changed

func _on_Player_spd_scaling_changed():
	spd = 100 * spd_scaling

# Bonus
enum Direction { LEFT, RIGHT, UP, DOWN }
var look_at = Direction.RIGHT

onready var animation_tree = get_node("%AnimationTree")

var timeratk = Timer.new()

func _ready():
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
				consecutiveKeyPresses = 0
				timeratk.start(0.4)
				timeratk.set_one_shot(true)
			if (timeratk.get_time_left() > 0):
				consecutiveKeyPresses += 1
			else:
				consecutiveKeyPresses = 0
		animation_tree.set("parameters/conditions/attack", true)
		if consecutiveKeyPresses >= desiredKeyPresses:
			animation_tree.set("parameters/conditions/consecutive_atk", true)

	else:
		animation_tree.set("parameters/conditions/attack", false)
		animation_tree.set("parameters/conditions/consecutive_atk", false)
	


func _death():
	return animation_tree.get("parameters/conditions/death")

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
	get_node("%Tween").interpolate_property(self, "global_position", global_position, dash_target_position, dash_duration)
	get_node("%Tween").interpolate_property(self, "velocity", velocity, 0, dash_duration)
	get_node("%Tween").start()
	animation_tree.set("parameters/conditions/dash", true)
	
	
func _dash_handler(input_direction):
	if was_any_input_action_just_pressed(movement_actions):
		if !animation_tree.get("parameters/conditions/dash"):
			if timerdash.is_stopped():
				animation_tree.set("parameters/conditions/dash", false)
				consecutiveKeyPresses2 = 0
				timerdash.start(0.4)
				timerdash.set_one_shot(true)
			if (input_direction == direction) and (timerdash.get_time_left() > 0):
				consecutiveKeyPresses2 +=  1
			else:
				animation_tree.set("parameters/conditions/dash", false)
				consecutiveKeyPresses2 = 0
			if consecutiveKeyPresses2 >= desiredKeyPresses2:
				activate_dash()
	else:
		animation_tree.set("parameters/conditions/dash", false)

signal direction_changed(old_value, new_value)

func _on_Player_direction_changed(old_direction, new_direction):
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
		animation_tree.set("parameters/conditions/movement", true)
	else:
		animation_tree.set("parameters/conditions/not_movement", true)
		animation_tree.set("parameters/conditions/movement", false)

		if animation_tree.get("parameters/conditions/dash"):
			activate_dash()
	return input_direction	

func _input(_event):
	_class_swap_mechanic_handler()
	_attack_mechanic_handler()

func was_any_input_action_just_pressed(actions):
	for action in actions:
		if Input.is_action_just_pressed(action):
			return true
	return false

func _physics_process(_delta):
	if _death():
		return
	var input_direction = _movement_mechanic_handler()
	velocity = input_direction * spd
	move_and_slide(velocity)
	
func take_damage(dmg):
	health -= dmg
	if health <= 0:
		animation_tree.set("parameters/conditions/death", true)
		emit_signal("health_depleted")
		

func _on_AtaqueHit_body_entered(body):
	if body.is_in_group("hurtbox") and body != self:
		print("where dmg")
		body.take_damage(atk)    
		
func _on_AtaqueHit2_body_entered(body):
	if body.is_in_group("hurtbox") and body != self:
		print("hey")
		body.apply_effect_speed_negative(body)    
		
func apply_effect_speed_positive(_player):
	var buff_instance = load("res://Effect.tscn").instance()
	var spd_buff = buff_instance.get_node("Buff/SPD_BUFF").duplicate()
	$Effects.add_child(spd_buff)

func apply_effect_speed_negative(_player):
	var debuff_instance = load("res://Effect.tscn").instance()
	var spd_debuff = debuff_instance.get_node("Debuff/SPD_DEBUFF").duplicate()
	$Effects.add_child(spd_debuff)
	player_debuffs.append(spd_debuff)
