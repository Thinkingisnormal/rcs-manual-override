extends RigidBody2D



#initialized all sprites (hull and thrusters)
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


@export var MAX_THRUST = 10000;
@export_range(0,100,1) var HEALTH : int = 100

@export var isDead = false;
@onready var debug = $"../GamePlay UI/Label"

# giving the player seconds of invinicbility so they don't get obliterated by the constant impulse of a collision.
@onready var collisionTimer = $collisionTimer
var invincible = false;
@export var invincibleDuration : int = 3

# this is the dictionary used to store all detected collisions, data is inputted by `distribute_Damage` function and parsed through with the `game_report` function
var unfilteredCollisionReport = {
# collisions will go here with the format:
# ID: {CollisionType: int, angularVelocity: int, linearVelocity: int, impulse: int }
}

#ideas to parse data for:
 #- total "near misses"
 #- impulse/force "equivelant to a ____"
 #- random part mentioned that broke in collision


func _ready() -> void:
	pass

func _integrate_forces(state):
	#inputting all controls
	inputInit(state)
	
	if HEALTH < 0:
		HEALTH = 0;
	elif HEALTH == 0:
		Player_Death()
	
	#print(get_angular_velocity())
	# a way to recieve the impulse of a rigidbody colliding iwth the player.
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



# distributing damage and gathering data into a list
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
	unfilteredCollisionReport.merge(IDdict)
	

func Player_Death():
	if !isDead: # so func only plays once
		get_parent().find_child("SpawnTimer").stop()
		filter_report_and_send(unfilteredCollisionReport)
		isDead = true;



#the lists of possible things to try to make each row unique.
var waysToSayRock = ["an asteroid","a small moon","a celestial object","a pebble","a rock","a space rock","a sedimentary sattilite","a potential eridian home","a planetoid"]
var bigLoss = ["cracking a window","losing a whole thruster","breaking On-Board Navigation","tearing the thermal insulation","breaking the communications antenna","puncturing the 02 tanks"]
var medLoss = ["knocking off an external camera","crushing the EVA suits","destroying nonessential cargo","tearing off access covers","breaking power cells","cracking the LIDAR"]
var smallLoss = ["chipping external paint","losing a screw","knocking a screw","causing abrasion of window surface","scratching external paint","kissing the hull","knocking unsecured items around.","tearing the access latch"]
var concludingSentence = ["Our next budget is so cooked...","this is what happens when our budget is halved...","innocent lives are lost... Taco Bell 2nite?","To be fair, Houston told them to not head into the astroid field...","4 hours until we release this to the media, get yourself sorted.","Take a breather and report back for next launch.","wow, we are just going through our people today!","this is NOT like the movies...","yikes...","They did better than the last four!","Mark poopfart mk.5 ready for launch.","glad i wasn't those people, phew!","i think we should add more boosters...","duly noted...","wow!","I am audibly sighing right now.", "tsk tsk tsk...","bro","they signed the new contract right?","This is a sad sight, exclaimation mark report back to husky, no, husky, NO, backspace backspace backspace, NO DELETE, DARN this text to speech dot dot dot"]
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
