extends Node2D

# max possible length of words is 6
const MAX_LENGTH = 8

var Enemy = preload("res://Scenes/enemy.tscn")

var archer_obj = preload("archer.gd").new()
var archer_position = 420

onready var enemies = $enemies
onready var archer_container = $archer
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
onready var spawn_timer = $spawn_timer
onready var hit_timer = $hit_timer
onready var buffer_label = $buffer as RichTextLabel
onready var sprite = $archer/archer_sprite as AnimatedSprite
onready var health_bar = $hp_bar
onready var archer = $archer as Node2D
onready var scrolling_bg = $scrolling_background
onready var round_counter = $round_label
onready var start_label = $start
onready var game_over_label = $game_over

onready var exempt_moving_bgs = [$scrolling_background/bg_layer_3, $scrolling_background/bg_layer_4]

# health textures
var green_health = preload("res://Images/barHorizontal_green.png")
var yellow_health = preload("res://Images/barHorizontal_yellow.png")
var red_health = preload("res://Images/barHorizontal_red.png")

var last_index_spawned = -1
var typed_buffer = ""
var active_words = []
var alpha_regex = RegEx.new()

export (int) var current_wave = 1
var current_wave_size = 10
var min_word_length = 3
var max_word_length = 5 # has to be at LEAST min_word_length + 1
var enemy_speed = .75
var total_enemies_killed = 0
var enemies_killed = 0
var spawn_rate_min = 1.25
var spawn_rate_max = 4.0 
var game_over = false
var started = false
var prev_enemy = null

func _ready() -> void:
	randomize()
	alpha_regex.compile("[a-z]")

func start_game():
	started = true
	game_over = false
	start_label.visible = false
	game_over_label.visible = false
	typed_buffer = ""
	buffer_label.text = ""
	spawn_enemy()
	start_wave()
	archer_obj.health = 100
	archer_container.add_child(archer_obj)
	get_node("archer/archer_sprite").playing = true
	initialize_music()


func stop_world():
	spawn_timer.stop()
	for enemy in enemies.get_children():
		enemy.queue_free()
	sprite.play("Death")
	yield(sprite, "animation_finished")
	stop_game()


func stop_game():
	game_over = true
	game_over_label.visible = true

func _process(delta):
	if started and not game_over:
		for enemy in enemies.get_children():
			if abs(enemy.position.x - archer_position) <= enemy.offset:
				if not enemy.attacking:
					enemy.attack()
					yield(enemy.sprite, "animation_finished")
					archer_obj.take_hit(enemy.hit_points)
					enemy.queue_free()
					if archer_obj.health <= 0:
						stop_world()
					health_bar.value = archer_obj.health
					if health_bar.value < 25:
						health_bar.set_progress_texture(red_health)
					elif health_bar.value < 65:
						health_bar.set_progress_texture(yellow_health)
					else:
						health_bar.set_progress_texture(green_health)
					$hp_bar/health_label.parse_bbcode(
						"[center]" + health_bar.value + "/100[/center]"
					)
	
func start_wave():
	print("Starting wave ", current_wave)
	spawn_timer.start()
	round_counter.parse_bbcode("ROUND %d" % current_wave)

func stop_wave():
	print("wave ", current_wave, " has been cleared!")
	spawn_timer.stop()
	
	# wait 5 seconds
	var t = Timer.new()
	t.set_wait_time(5)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	
	# increment current wave
	current_wave += 1
	
	# increase the difficulty for the next wave
	increase_difficulty()
	
	# start the next wave
	start_wave()

func increase_difficulty():
	if current_wave % 3 == 0:
		enemy_speed += 0.15
		if 1.5 < spawn_rate_max:
			spawn_rate_max -= .5
		if max_word_length < MAX_LENGTH + 1:
			max_word_length += 1
	
	if current_wave % 6 == 0: 
		if min_word_length < max_word_length - 1:
			min_word_length += 1
		if spawn_rate_min - 0.25 > 0.25:
			spawn_rate_min -= 0.25
	
	if current_wave % 10 == 0:
		current_wave_size += 15

func check_words():
	if not started:
		if typed_buffer == "start":
			start_game()
	elif game_over:
		if typed_buffer == "restart":
			start_game()
	else:
		for enemy in enemies.get_children():
			var prompt = enemy.get_prompt()
			if prompt == typed_buffer:
				# clear buffer
				typed_buffer = ""
				buffer_label.text = typed_buffer
				stop_running()
				kill_enemy(enemy)
				yield(sprite, "animation_finished")
				
				# actually kill the enemy now
				if prev_enemy != null:
					prev_enemy.queue_free()
				if enemy != null:
					enemy.queue_free()
				
				start_running()
				
				if enemies_killed >= current_wave_size:
					stop_wave()
					total_enemies_killed += enemies_killed
					enemies_killed = 0
				break

func start_running():
	enemy_speed -= .22
	for bg in scrolling_bg.get_children():
		if bg in exempt_moving_bgs:
			bg.move_fast()
		else:
			bg.start_archer()
	
	for enemy in enemies.get_children():
		enemy.set_speed(enemy.get_speed() - 0.22)
	
	sprite.play("Run")
	

func stop_running():
	enemy_speed += .22
	for bg in scrolling_bg.get_children():
		if bg in exempt_moving_bgs:
			bg.move_slow()
		else:
			bg.stop_archer()
	for enemy in enemies.get_children():
		enemy.set_speed(enemy.get_speed() + 0.22)

func kill_enemy(enemy):
	enemies_killed += 1
	
	if enemies_killed == 1:
		audio_enable("audio_bass_1")
	
	if sprite.animation == "Attack":
		sprite.set_frame(0)
		if prev_enemy != null:
			prev_enemy.queue_free()

	sprite.play("Attack")
	prev_enemy = enemy

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var type_event = event as InputEventKey
		if type_event.scancode == KEY_SPACE:
			typed_buffer = ""
			buffer_label.text = typed_buffer
		elif type_event.scancode == KEY_BACKSPACE:
			typed_buffer = typed_buffer.substr(0, typed_buffer.length() - 1)
			buffer_label.text = typed_buffer
		else:
			var typed_char = char(type_event.scancode).to_lower()
			if alpha_regex.search(typed_char):
				typed_buffer += typed_char
				buffer_label.text = typed_buffer
				check_words()
			

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	spawn_timer.wait_time = rand_range(spawn_rate_min, spawn_rate_max)

func spawn_enemy():
	var enemy_instance = Enemy.instance()
	var randInt = randi()
	var spawns = r_spawn_points.get_children()
	var direction = -1
	var index = randInt % spawns.size()
	if index != last_index_spawned:
		index = (randInt + 1) % spawns.size()

	enemy_instance.init(direction, enemy_speed, min_word_length, max_word_length)
	enemies.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position

func _on_archer_sprite_animation_finished():
	pass

func initialize_music():
	for audio_node in get_node("audio_node").get_children():
		audio_node.volume_db = -80
		audio_node.play()
	audio_enable("audio_percussion_1")
	audio_enable("audio_string_beat_1")
	
func audio_enable(layer_name):
	get_node("audio_node/" + layer_name).volume_db = 1
	
func audio_disable(layer_name):
	get_node("audio_node/" + layer_name).volume_db = -80
