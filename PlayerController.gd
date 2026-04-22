extends RigidBody2D

#initialized all thruster sprites
@onready var upper_left_t = $"thrusters/upper left thruster"
@onready var lower_left_t = $"thrusters/lower left thruster"
@onready var bottom_right_t = $"thrusters/bottom right thruster"
@onready var bottom_left_t = $"thrusters/bottom left thruster"
@onready var top_right_t = $"thrusters/top right thruster"
@onready var top_left_t = $"thrusters/top left thruster"
@onready var upper_right_t = $"thrusters/upper right thruster"
@onready var lower_right_t = $"thrusters/lower right thruster"

@export var MAX_THRUST = 10000;
@export var HEALTH = 100;

@export var isDead = false;

# giving the player seconds of invinicbility so they don't get obliterated by the constant impulse of a collision.
@onready var collisionTimer = $collisionTimer
var invincible = false;
@export var invincibleDuration : int = 3



func _ready() -> void:
	collisionTimer.autostart = false



func _integrate_forces(state):
	#inputting all controls
	inputInit(state)
	
	if HEALTH < 0:
		isDead = true;
		HEALTH = 0;
	elif HEALTH == 0:
		isDead = true
	
	
	# a way to recieve the impulse of a rigidbody colliding iwth the player.
	var contact_count = state.get_contact_count()
	var total_impulse := Vector2.ZERO
	for i in range (contact_count):
		var impulse = state.get_contact_impulse(i)
		total_impulse += impulse
		var impulse_length := total_impulse.length()
		distribute_Damage(impulse_length)
	# this will be the total amount of impact (in any direction) applied this physics frame

	
	#to make the game less harsh, there will be a max damage, 
	#allowing the player to come back from a collision
	
	
	


func inputInit(state):
	if !isDead:
		#THRUSTERS ON THE LEFT SIDE
		if Input.is_physical_key_pressed(KEY_Q):
			state.apply_force(Vector2(MAX_THRUST,0).rotated(rotation), upper_left_t.position.rotated(rotation))
		if Input.is_physical_key_pressed(KEY_A):
			state.apply_force(Vector2(MAX_THRUST,0).rotated(rotation), lower_left_t.position.rotated(rotation))
		#THRUSTERS ON THE RIGHT SIDE
		if Input.is_physical_key_pressed(KEY_O):
			state.apply_force(Vector2(-MAX_THRUST,0).rotated(rotation), upper_right_t.position.rotated(rotation))
		if Input.is_physical_key_pressed(KEY_L):
			state.apply_force(Vector2(-MAX_THRUST,0).rotated(rotation), lower_right_t.position.rotated(rotation))
		#THRUSTERS ON THE TOP SIDE
		if Input.is_physical_key_pressed(KEY_E):
			state.apply_force(Vector2(0,MAX_THRUST).rotated(rotation), top_left_t.position.rotated(rotation))
		if Input.is_physical_key_pressed(KEY_I):
			state.apply_force(Vector2(0,MAX_THRUST).rotated(rotation), top_right_t.position.rotated(rotation))
		#THRUSTERS ON THE BOTTOM SIDE
		if Input.is_physical_key_pressed(KEY_D):
			state.apply_force(Vector2(0,-MAX_THRUST).rotated(rotation), bottom_left_t.position.rotated(rotation))
		if Input.is_physical_key_pressed(KEY_K):
			state.apply_force(Vector2(0,-MAX_THRUST).rotated(rotation), bottom_right_t.position.rotated(rotation))




func distribute_Damage(dealtImpulse: int):
	# lets say damage above 10000 is big damage
	var maxDamage = 10000
	printt("impulse dealt:", dealtImpulse)
	if !invincible:
		if dealtImpulse > maxDamage:
			print("max d dealt")
			HEALTH -= 25
			invincible = true
			collisionTimer.start(invincibleDuration)
			
		elif dealtImpulse < maxDamage && dealtImpulse > 5000:
			HEALTH -= 15
			print("2nd d dealt")
			invincible = true
			collisionTimer.start(invincibleDuration)
			
		elif dealtImpulse < 5000 && dealtImpulse > 100:
			HEALTH -= 10
			print("least d dealt")
			invincible = true
			collisionTimer.start(invincibleDuration)
			
		elif dealtImpulse <= 100 && dealtImpulse > 0:
			print("near miss!")
	


func _on_collision_timer_timeout() -> void:
	invincible = false
