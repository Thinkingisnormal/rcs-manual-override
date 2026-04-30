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
