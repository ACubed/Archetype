extends Node2D

var health = 100

var x_position = 420

func _ready():
	pass
	
func take_hit(hit_points: int):
		health -= hit_points

