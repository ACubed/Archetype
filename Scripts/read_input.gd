extends Node2D

var Enemy = preload("res://Scenes/enemy.tscn")

onready var enemies = $enemies
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
onready var spawn_timer = $spawn_timer
onready var buffer_label = $buffer as RichTextLabel

var typed_buffer = ""
var active_words = []

func _ready() -> void:
	randomize()
	spawn_enemy()
	spawn_timer.start()
	
func checkWords():
	for enemy in enemies.get_children():
		var prompt = enemy.get_prompt()
		if prompt == typed_buffer:
			enemy.queue_free()
			typed_buffer = ""
			buffer_label.text = typed_buffer
			
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var type_event = event as InputEventKey
		if type_event.scancode == KEY_BACKSPACE:
			typed_buffer = typed_buffer.substr(0, typed_buffer.length() - 1)
			buffer_label.text = typed_buffer
		else:
			typed_buffer += char(type_event.scancode).to_lower()
			buffer_label.text = typed_buffer
			checkWords()

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

	enemy_instance.init(direction, 3)
	enemies.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position
