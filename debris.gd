extends RigidBody2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@export var impulse = 200

var reset_state = false
var moveVector: Vector2



func _ready() -> void:
	var Rscale = Vector2(randf_range(.5,2),randf_range(.5,2))
	var Rrotation = randf_range(-180,180)
	
	sprite.apply_scale(Rscale)
	collision.apply_scale(Rscale)
	sprite.rotate(Rrotation)
	collision.rotate(Rrotation)

	move_body(
		Vector2(
		randf_range(1,get_parent().window_size.x) ,
		-(get_parent().window_size.y + 300)
		))
	
	apply_torque_impulse(randi_range(-50,50)) # to make it spin
	
	apply_central_impulse(Vector2(0,impulse)) # to make it move




func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if reset_state:
		state.transform = Transform2D(0.0, moveVector)
		reset_state = false

func move_body(targetpos: Vector2):
	moveVector = targetpos
	reset_state = true
