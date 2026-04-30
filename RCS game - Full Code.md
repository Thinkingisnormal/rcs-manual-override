## PlayerController.gd (game/Player)
```gdscript
extends RigidBody2D
#This script is a child of the Player model. It controls all 8 inputs of the player, and handles sequencing, selecting, and iterating through a list of collision reports. 

#initialized all sprites (hull and thrusters) Right now, thruster sprites are placeholders to visualize where they would add impulse to the player.
@onready var upper_left_t = $"thrusters/upper left thruster"
@onready var lower_left_t = $"thrusters/lower left thruster"
@onready var bottom_right_t = $"thrusters/bottom right thruster"
@onready var bottom_left_t = $"thrusters/bottom left thruster"
@onready var top_right_t = $"thrusters/top right thruster"
@onready var top_left_t = $"thrusters/top left thruster"
@onready var upper_right_t = $"thrusters/upper right thruster"
@onready var lower_right_t = $"thrusters/lower right thruster"
@onready var hull_sprite: Sprite2D = $Sprite2D

#UI nodes, holding gameplay and death ui
@onready var game_play_ui: Control = %"GamePlay UI"
@onready var after_action_ui: Control = %"After Action UI"

#exporting allows me to change these veriables within the GODOT editor
@export var MAX_THRUST = 10000;
@export_range(0,100,1) var HEALTH : int = 100

@export var isDead = false;
#a label that is used whenever i want to have a debug be "visual" and not in the console.
@onready var debug = $"../GamePlay UI/Label"

# giving the player seconds of invinicbility so they don't get obliterated by the constant impulse of a collision.
@onready var collisionTimer = $collisionTimer
var invincible = false;
@export var invincibleDuration : int = 3

# this is the dictionary used to store all detected collisions, data is inputted by `distribute_Damage` function and parsed through with the `game_report` function.
var unfilteredCollisionReport = {
# collisions will go here with the format:
# ID: {CollisionType: int, angularVelocity: int, linearVelocity: int, impulse: int }
}

#ideas to parse data for:
 #- total "near misses" (done)
 #- impulse/force "equivelant to a ____" (NOT IMPLEMENTED YET)
 #- random part mentioned that broke in collision (done)

# `@onready` is like putting those commands into here.
func _ready() -> void:
	pass

#called every physics frame. can be ran on a seperate thread
func _integrate_forces(state):
	#inputting all controls
	inputInit(state)
	
	if HEALTH < 0:
		HEALTH = 0;
	elif HEALTH == 0:
		Player_Death()
	
	#print(get_angular_velocity())
	
	# a way to recieve the impulse of a rigidbody colliding with the player. got this from a reddit post that i cannot seem to find again. i feel like there is a better way to caclulate the actual magnitude of a collision as this gives inconsistent numbers.
	var contact_count = state.get_contact_count()
	var total_impulse := Vector2.ZERO
	for i in range (contact_count):
		var impulse = state.get_contact_impulse(i)
		total_impulse += impulse
		print(impulse, invincible)
		var impulse_length := total_impulse.length() # this will be the total amount of impact (in any direction) applied this physics frame
	
	#to make the game less harsh, there will be a max damage, 
	#allowing the player to have the opporurtunity to come back from a collision
		distribute_Damage(impulse_length)


#function handles the input of the player, with the parameter asking for `state,` which is from `integrate_forces`. The buttons are as follows: Q,A,O,L,E,I,D,K
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



# distributing damage and gathering data into a dictionary, each collision becomes its own list with an id.
func distribute_Damage(dealtImpulse: int):
	# lets say damage above 10000 is big damage
	var maxDamage = 10000
	if !invincible: 
		
		if dealtImpulse > maxDamage: # BIG
			HEALTH -= 25
			collisionTimer.start(invincibleDuration)
			make_invincible(true)
			input_Collision_Report({"Damage Type":"big", "impulse dealt": dealtImpulse, "linear velocity": get_linear_velocity().length(), "Angular Velocity": get_angular_velocity()})
		elif dealtImpulse < maxDamage && dealtImpulse > 5000: # MED
			HEALTH -= 15
			make_invincible(true)
			collisionTimer.start(invincibleDuration)
			input_Collision_Report({"Damage Type":"med", "impulse dealt":dealtImpulse, "linear velocity":get_linear_velocity().length(), "Angular Velocity":get_angular_velocity()})
		elif dealtImpulse < 5000 && dealtImpulse > 100: # SMALL
			HEALTH -= 10
			make_invincible(true)
			collisionTimer.start(invincibleDuration)
			input_Collision_Report({"Damage Type": "small", "impulse dealt": dealtImpulse, "linear velocity": get_linear_velocity().length(), "Angular Velocity": get_angular_velocity()})
		elif dealtImpulse <= 100 && dealtImpulse >= 0: # NEAR MISS
			input_Collision_Report({"Damage Type":"miss", "impulse dealt": dealtImpulse, "linear velocity":get_linear_velocity().length(), "Angular Velocity": get_angular_velocity()})


# Fills in the unfiltered dictionary to be picked apart later
var IDcounter = 0
func input_Collision_Report(damageRow: Dictionary):
	IDcounter += 1
	var IDdict = {IDcounter: damageRow}
	print(IDdict)
	unfilteredCollisionReport.merge(IDdict) #merges the `ID: int` key value pair into the rows and adds them into the list
	

#A future addition could add different reports based on how the player died. It would be stored here.
func Player_Death():
	# if statement is so function only runs once without introducing another variable.
	if !isDead: 
		get_parent().find_child("SpawnTimer").stop()
		filter_report_and_send(unfilteredCollisionReport)
		isDead = true;



#the lists of possible things to try to make each row unique.
var waysToSayRock = ["an asteroid","a small moon","a celestial object","a pebble","a rock","a space rock","a sedimentary sattilite","a potential eridian home","a planetoid"]
var bigLoss = ["cracking a window","losing a whole thruster","breaking On-Board Navigation","tearing the thermal insulation","breaking the communications antenna","puncturing the 02 tanks"]
var medLoss = ["knocking off an external camera","crushing the EVA suits","destroying nonessential cargo","tearing off access covers","breaking power cells","cracking the LIDAR"]
var smallLoss = ["chipping external paint","losing a screw","knocking a screw","causing abrasion of window surface","scratching external paint","kissing the hull","knocking unsecured items around.","tearing the access latch"]
var concludingSentence = ["Our next budget is so cooked...","this is what happens when our budget is halved...","innocent lives are lost... Taco Bell 2nite?","To be fair, Houston told them to not head into the astroid field...","4 hours until we release this to the media, get yourself sorted.","Take a breather and report back for next launch.","wow, we are just going through our people today!","this is NOT like the movies...","yikes...","They did better than the last four!","poopfart mk.5 ready for launch.","glad i wasn't those people, phew!","i think we should add more boosters...","duly noted...","wow!","I am audibly sighing right now.", "tsk tsk tsk...","bro","they signed the new contract right?","This is a sad sight, exclaimation mark report back to husky, no, husky, NO, backspace backspace backspace, NO DELETE, DARN this text to speech dot dot dot"]
const SUMMARY_ROW_UI = preload("uid://ccp4q3b2vw47v") # preload the single row ui so i can instantiate copys 

# filters the UnfilteredCollisionReport list into a summary that is shown to the player after game over. 
func filter_report_and_send(reportDict: Dictionary):
	var missCounter:int = 0;
	
	for id in unfilteredCollisionReport:
		var collisionRow = unfilteredCollisionReport[id] #pmo fiure it out
		var newRow = SUMMARY_ROW_UI.instantiate()
		match collisionRow["Damage Type"]:
			"small":
				newRow.find_child("Main Text").text = "scraped " + waysToSayRock.pick_random() +", " + smallLoss.pick_random()
				newRow.find_child("Health Text").text = "(-10)"
				after_action_ui.find_child("Paper").find_child("BodyContainer").find_child("BodyVbox").add_child(newRow)
			"med":
				newRow.find_child("Main Text").text = "hit " + waysToSayRock.pick_random() +", " + medLoss.pick_random()
				newRow.find_child("Health Text").text = "(-15)"
				after_action_ui.find_child("Paper").find_child("BodyContainer").find_child("BodyVbox").add_child(newRow)
			"big":
				newRow.find_child("Main Text").text = "crashed into " + waysToSayRock.pick_random() +", " + bigLoss.pick_random()
				newRow.find_child("Health Text").text = "(-25)"
				after_action_ui.find_child("Paper").find_child("BodyContainer").find_child("BodyVbox").add_child(newRow)
			"miss":
				missCounter+=1;
	
	after_action_ui.find_child("Paper").find_child("endingSentence").text = concludingSentence.pick_random()
	after_action_ui.find_child("Paper").find_child("nearMiss").text = str(missCounter) + " near misses!"
	after_action_ui.set_visible(true)


# function handling animation and mechanics of invincible var and making player not take damage 
func make_invincible(b:bool):
	if b:
		invincible = true
		var t = hull_sprite.create_tween().set_loops(invincibleDuration) #creates a tween animation to loop every second for the duration of invinicble
		t.tween_property(hull_sprite,"modulate", Color(0.251, 0.251, 0.251, 1.0), 0.25)
		t.tween_property(hull_sprite,"modulate", Color.WHITE, 0.25)
		
		
	elif !b:
		invincible = false
func _on_collision_timer_timeout() -> void:
	make_invincible(false)

```
## gameManager.gd (game/)
```gdscript
extends Node2D
#This script runs on the base node of the scene. It creates a variables that hold the player's viewport size for other nodes to use. it also handles the killing of the player when it leaves the play area.

#grabs the viewport x size when the game gets initialized - doesn't change during gameplay.
@export var window_size : Vector2

#to create copys of the "debris" or the astroid.
var debris = preload("res://debris.tscn") 

@onready var spawntimer = $SpawnTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window_size = get_viewport().get_visible_rect().size + Vector2(-577,324) ## offset to center of scene

#handles spawning astroids based on another node which is the spawn timer. there is no code for the spawn timer as it is built into the editor.
func _on_spawn_timer_timeout() -> void:
	var d = debris.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	add_child(d)
	
	





func _on_play_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("debris"):
		body.queue_free() #destroys the astroid object
	elif body.is_in_group("player"):
		body.HEALTH = 0
		print("player left play area, killed")

```
## PlayArea.gd (game/playArea)
```gdscript
extends Area2D
## this is a child of a 2Darea node. It takes the viewport variable from the game manager and resizes the potential x range for astroids to spawn in. it 
var window_size : Vector2

@onready var collisionshape = $CollisionShape2D ##the 2darea's collisionshape (a square)


# creating size of play area, debris that exits will be disposed (and prolly the player dies immediately)
func _ready() -> void:
	window_size = get_viewport().get_visible_rect().size
	var playshape = RectangleShape2D.new()
	playshape.set_size( window_size * Vector2(2,2)) 
	print(playshape.get_size())
	collisionshape.set_shape(playshape)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

```
## GamplayUI.gd (game/GameplayUI)
```gdscript
extends Control
#handles the gamplay GUI script. changes the healthbar based on players health. and initializes the bottom right subviewport to draw the same world as the main viewport.
@onready var ship_camera : Camera2D = $PanelContainer/SubViewportContainer/SubViewport/shipCamera

@export var player : Node2D

@onready var subview = $PanelContainer/SubViewportContainer/SubViewport

@onready var health_bar: ProgressBar = %healthBar

@onready var reg_camera = $"../mainCamera"

@onready var after_action_ui: Control = $"After Action UI"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	subview.world_2d = get_viewport().world_2d # allows the subviewport (bottom right square of screen) to render the same 2d world as the main viewport

func _process(delta: float) -> void:
	ship_camera.global_position = player.global_position #just making ship camera a child of the player seemed to break stuff so i just did this
	health_bar.value = player.HEALTH
	

```
## Debris.gd (initialized into game/)
```gdscript
extends RigidBody2D
#handles all the logic of an astroid. 
@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@export var impulse = 200 #the impulse that it starts with. Since its in space, it does not need a constant force, so an impulse will do.

var reset_state = false
var moveVector: Vector2



func _ready() -> void:
	#randomizes the scale and orientation of the astroid when it is spawned in.
	var Rscale = Vector2(randf_range(.5,2),randf_range(.5,2))
	var Rrotation = randf_range(-180,180)
	#applys changes to sprite and its collision shape
	sprite.apply_scale(Rscale)
	collision.apply_scale(Rscale)
	sprite.rotate(Rrotation)
	collision.rotate(Rrotation)
	#calls move_body to "teleport" it to the a random x value based on the players viewport size
	move_body(
		Vector2(
		randf_range(1,get_parent().window_size.x) ,
		-(get_parent().window_size.y + 300)
		))
	
	apply_torque_impulse(randi_range(-50,50)) # to make it spin
	
	apply_central_impulse(Vector2(0,impulse)) # to make it move




func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#since physics in GODOT is running seperately from the rest of the logic, if you set a rigidbody objects position, the physics process will not recognize the change and will bring it back to where it was supposed to be, so you would have to sort of freeze its phycics process in order to move it. This solution was not written by me. I found it on a reddit post.
	if reset_state:
		state.transform = Transform2D(0.0, moveVector)
		reset_state = false

func move_body(targetpos: Vector2):
	moveVector = targetpos
	reset_state = true

```