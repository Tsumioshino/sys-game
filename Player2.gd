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
onready var btimer = get_node("/root/PlayerRoot/Player/Node/BuffTimer")
onready var dtimer = get_node("/root/PlayerRoot/Player/Node/DebuffTimer")
	
onready var animation_tree = get_node("%AnimationTree")
onready var animationState = animation_tree.get("parameters/playback")

var isLocalPlayer = !is_network_master()

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.set_animation_player(player_class[class_count]) 
	player.scale.x *= -1 if look_at == Direction.LEFT else 1
	animation_tree.set("parameters/conditions/not_movement", true)
	animation_tree.active = true
	
func _process(delta):
	if Input.is_action_pressed("attack"):
		animation_tree.set("parameters/conditions/attack", true)
	else:
		animation_tree.set("parameters/conditions/attack", false)
		
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
	if body.is_in_group("hurtbox"):
		print("where dmg")
		body.take_damage(atk)    
		
# Should be another Scene, probably
# Effects shouldn't stack
var has_speed_buff = false
var has_speed_debuff = false

func apply_effect_speed_positive(_player):
	if not has_speed_buff:
		speed_scaling += 2
		has_speed_buff = true
		btimer.start()
		
func apply_effect_speed_negative(_player):
	if not has_speed_debuff:
		speed_scaling -= 2
		has_speed_debuff = true
		dtimer.start()


func _on_BuffTimer_timeout():
	speed_scaling -= 2
	has_speed_buff = false # Replace with function body.

func _on_DebuffTimer_timeout():
	speed_scaling += 2
	has_speed_debuff = false # Replace with function body.
