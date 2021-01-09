extends Node2D

const SPAWN_POINTS = 5

var Enemy = preload("res://Scenes/enemy.tscn")

onready var enemies = $enemies
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
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
	var randInt = randi()
	var spawns = r_spawn_points.get_children()
	var direction = -1
	
	if randInt % 2 == 0:
		# insert into left
		spawns = l_spawn_points.get_children()
		direction = 1
		
	var index = randInt % spawns.size()

	enemy_instance.init(direction)
	enemies.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position
