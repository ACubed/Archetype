extends Node2D

const SPAWN_POINTS = 5

var Enemy = preload("res://Scenes/enemy.tscn")

onready var enemies = $enemies
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
onready var spawn_timer = $spawn_timer

var curr_letter_index: int = -1
var active_enemy = null

func _ready() -> void:
	randomize()
	spawn_enemy()
	spawn_timer.start()
	
	
func find_new_enemy(typed_char: String):
	for enemy in enemies.get_children():
		var prompt = enemy.get_prompt()
		if prompt.substr(0, 1) == typed_char:
			active_enemy = enemy
			curr_letter_index = 1
			print("enemy targeted")
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var type_event = event as InputEventKey
		var key_typed = char(type_event.scancode).to_lower()
		if active_enemy == null:
			find_new_enemy(key_typed)
		else:
			var prompt = active_enemy.get_prompt()
			var next_char = prompt.substr(curr_letter_index, 1)
			if key_typed == next_char:
				curr_letter_index += 1
				if curr_letter_index == prompt.length():
					curr_letter_index = -1
					active_enemy.queue_free()
					active_enemy = null
					print("enemy killed")

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
