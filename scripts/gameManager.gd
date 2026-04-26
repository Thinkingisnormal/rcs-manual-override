extends Node2D


#grabs the viewport x size when the game gets initialized - doesn't change during gameplay.
@export var window_size : Vector2

var debris = preload("res://debris.tscn")
@onready var spawntimer = $SpawnTimer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window_size = get_viewport().get_visible_rect().size + Vector2(-577,324) ## offset to center of scene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	var d = debris.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	add_child(d)
	
	





func _on_play_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("debris"):
		body.queue_free()
	elif body.is_in_group("player"):
		body.HEALTH = -1
		print("player left play area, killed")
