extends Node2D

var archer_moving = true
var powerup = true
		
# Mode when the player has stopped moving in this direction.
func archer_stopped():
	archer_moving = false
	
# Mode when the player is moving toward this enemy.
func archer_running():
	archer_moving = true

func get_prompt():
	return $label.text

func die():
	queue_free()
