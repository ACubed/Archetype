extends Node2D

var Enemy = preload("res://Scenes/enemy.tscn")
onready var enemies = $enemies
onready var spawn_points = $enemy_spawn_container
onready var spawn_timer = $spawn_timer

var curr_letter_index: int = -1

func _ready() -> void:
	randomize()
	spawn_enemy()
	spawn_timer.start()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var typed_event = event as InputEventKey
		var key_typed = PoolByteArray([typed_event.unicode]).get_string_from_utf8()

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy():
	var enemy_instance = Enemy.instance()
	var spawns = spawn_points.get_children()
	var index = randi() % spawns.size()
	enemies.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position
