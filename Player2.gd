extends KinematicBody2D


# Declare member variables here. Examples:
enum States { IDLE, MOVEMENT, GLIDING }
var state : int = States.IDLE


export var direction = Vector2.ZERO

enum Direction { LEFT, RIGHT, UP, DOWN }
var look_at = Direction.RIGHT

enum Class { WARRIOR, THIEF }
var player_class = ["%WARRIOR", "%THIEF"] # idealmente usar lista circular/duplamente encadeada
var class_count = 0
var atk = 1
var health = 5

var velocity = 0
var speed_scaling = 3
var speed = 100 * speed_scaling

onready var player = get_node("%Player")
onready var btimer = get_node("%Player/Effect/BuffTimer")
onready var dtimer = get_node("%Player/Effect/DebuffTimer")
	
onready var animation_tree = get_node("%AnimationTree")
onready var animationState = animation_tree.get("parameters/playback")

var isLocalPlayer = !is_network_master()
var timeratk = Timer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.set_animation_player(player_class[class_count]) 
	player.scale.x *= -1 if look_at == Direction.LEFT else 1
	animation_tree.set("parameters/conditions/not_movement", true)
	animation_tree.active = true
	add_child(timeratk)
	add_child(timerdash)
var consecutiveKeyPresses = 0
var desiredKeyPresses = 2

func _process(delta):
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

					
var timerdash = Timer.new()
var consecutiveKeyPresses2 = 0
var desiredKeyPresses2 = 2	
var last_input_direction = Vector2(0, 0)  # Variable to track the last input direction

func was_any_input_action_just_pressed(actions):
	for action in actions:
		if Input.is_action_just_pressed(action):
			return true
	return false
	
var dash_press = false
var gambiarra_actions = ["left2", "right2", "up2", "down2"]
func _physics_process(delta):
	if isLocalPlayer:
		if Input.is_action_just_pressed("change_class"):
			apply_effect_speed_positive(player)
			class_count+=1 
			if class_count > 1: # gambiarra por n usar lista dupla
				class_count = 0
			animation_tree.set_animation_player(player_class[class_count]) 
		if (animation_tree.get("parameters/conditions/death")):
			return
		var input_direction = Input.get_vector("left2", "right2", "up2", "down2")
		if input_direction:
			animation_tree.set("parameters/conditions/not_movement", false)
			animation_tree.set("parameters/conditions/movement", true)
			if was_any_input_action_just_pressed(gambiarra_actions):
				if !animation_tree.get("parameters/conditions/dash"):
					if timerdash.is_stopped():
						animation_tree.set("parameters/conditions/dash", false)
						consecutiveKeyPresses2 = 0
						timerdash.start(0.4)
						timerdash.set_one_shot(true)
					if (input_direction == last_input_direction) and (timerdash.get_time_left() > 0):
						consecutiveKeyPresses2 +=  1
					else:
						animation_tree.set("parameters/conditions/dash", false)
						consecutiveKeyPresses2 = 0
					if consecutiveKeyPresses2 >= desiredKeyPresses2:
						print(direction)
						var dash_direction = direction
						var dash_distance = 200  # Adjust as needed
						var dash_duration = 0.6  # Adjust as needed
						var dash_target_position = global_position + dash_direction * dash_distance
						get_node("%Tween").interpolate_property(
						self,
						"global_position",
						global_position,
						dash_target_position,
						dash_duration,
						Tween.TRANS_LINEAR,
						Tween.EASE_IN_OUT
						)
						get_node("%Tween").start()
						animation_tree.set("parameters/conditions/dash", true)
					last_input_direction = input_direction
				else:
					animation_tree.set("parameters/conditions/dash", false)
			if direction.x != input_direction.x:
				if input_direction.x > 0:
					if look_at != Direction.RIGHT:
						get_node("%Player").scale.x *= -1
						look_at = Direction.RIGHT
				elif input_direction.x < 0:
					if look_at != Direction.LEFT:
						get_node("%Player").scale.x *= -1
						look_at = Direction.LEFT
			if direction.y != input_direction.y:
				if input_direction.y > 0:
					pass
				elif input_direction.y < 0:
					pass		
			direction = input_direction 	
		else:
			animation_tree.set("parameters/conditions/not_movement", true)
			animation_tree.set("parameters/conditions/movement", false)
			

			if animation_tree.get("parameters/conditions/dash"):
				# should have some custom logic
				print(direction)
				var dash_direction = direction
				var dash_distance = 200  # Adjust as needed
				var dash_duration = 0.5  # Adjust as needed
				var dash_target_position = global_position + dash_direction * dash_distance
				get_node("%Tween").interpolate_property(
				self,
				"global_position",
				global_position,
				dash_target_position,
				dash_duration
				)
				get_node("%Tween").interpolate_property(
				self,
				"velocity",
				velocity,
				0,
				dash_duration
				)
				get_node("%Tween").start()
				animation_tree.set("parameters/conditions/dash", false)

		speed = 100 * speed_scaling # this is danger but effects work with this here but thsi is danger
		velocity = input_direction * speed
		#print(input_direction)
		move_and_slide(velocity)
	
func take_damage(atk):
	health -= 1
	if health <= 0:
		animation_tree.set("parameters/conditions/death", true)
		

func _on_AtaqueHit_body_entered(body):
	print("hi at least")
	if body.is_in_group("hurtbox") and body != self:
		print("where dmg")
		body.take_damage(atk)    
		
func _on_AtaqueHit2_body_entered(body):
	print("hi at least2")
	if body.is_in_group("hurtbox") and body != self:
		print("hey")
		body.apply_effect_speed_negative(body)    
		
# Should be another Scene, probably
# Effects shouldn't stack
var has_speed_buff = false
var has_speed_debuff = false

func apply_effect_speed_positive(_player):
	if not has_speed_buff:
		speed_scaling += 2
		has_speed_buff = true
		btimer.start()
		get_node("%Tween").interpolate_property(get_node("%Player/SpritesAnimacao"), "self_modulate", Color(0xBBFF8CFF), Color(0xFFFFFFFF), btimer.get_wait_time())
		get_node("%Tween").start()
			
func apply_effect_speed_negative(_player):
	if not has_speed_debuff:
		speed_scaling -= 2
		has_speed_debuff = true
		dtimer.start()
		get_node("%Tween").interpolate_property(get_node("%Player/SpritesAnimacao"), "self_modulate", Color(0xFF7777FF), Color(0xFFFFFFFF), dtimer.get_wait_time())
		get_node("%Tween").start()


func _on_BuffTimer_timeout():
	speed_scaling -= 2
	has_speed_buff = false # Replace with function body.
	#get_node("%Player/Sprite sAnimacao").self_modulate = Color(0xFFFFFFFF)

func _on_DebuffTimer_timeout():
	speed_scaling += 2
	has_speed_debuff = false # Replace with function body.
