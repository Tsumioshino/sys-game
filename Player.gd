extends KinematicBody2D


# Declare member variables here. Examples:
export var direction = Vector2.ZERO

enum Direction { LEFT, RIGHT, UP, DOWN }
var look_at = Direction.RIGHT

var atk = 1
var health = 5

var velocity = 0
var speed = 400
	
onready var animation_tree = get_node("%AnimationTree")
onready var animationState = animation_tree.get("parameters/playback")


# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.scale.x *= -1 if look_at == Direction.LEFT else 1
	animation_tree.set("parameters/conditions/not_movement", true)
	animation_tree.active = true
	
func _process(delta):
	if Input.is_action_pressed("attack"):
		animation_tree.set("parameters/conditions/attack", true)
	else:
		animation_tree.set("parameters/conditions/attack", false)
		
func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction:
		animation_tree.set("parameters/conditions/not_movement", false)
		animation_tree.set("parameters/conditions/movement", true)
		if direction.x != input_direction.x:
			if input_direction.x > 0:
				if look_at != Direction.RIGHT:
					$Player.scale.x *= -1
					look_at = Direction.RIGHT
			elif input_direction.x < 0:
				if look_at != Direction.LEFT:
					$Player.scale.x *= -1
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
	velocity = input_direction * speed
	#print(input_direction)
	move_and_slide(velocity)
	
func take_damage(_atk):
	health -= _atk
	print("poor p1 hp")
	if health <= 0:
		animation_tree.set("parameters/conditions/death", true)
		queue_free() 

func _on_AtaqueHit_body_entered(body):
	if body.is_in_group("hurtbox"):
		print("this should do damage")
		body.take_damage(atk)    
