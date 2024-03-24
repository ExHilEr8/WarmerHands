extends CharacterBody2D

@export var move_speed: float = float(250.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func get_user_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * move_speed

func _physics_process(_delta):
	get_user_input()
	move_and_slide()
