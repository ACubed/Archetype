extends Node2D

# constants
const MAX_LENGTH = 8
const FULL_HP = 100
const HIGH_HP = 91
const MEDIUM_HP = 65
const LOW_HP = 25
const ENEMY_RANGE = 100
const MAX_VOLUME = -7.0
const MIN_VOLUME = -40.0
const DIMINISHED_VOLUME = -10.0

# preload scripts
var Enemy = preload("res://Scenes/enemy.tscn")
var archer_obj = preload("archer.gd").new()
var green_health = preload("res://Images/barHorizontal_green.png")
var yellow_health = preload("res://Images/barHorizontal_yellow.png")
var red_health = preload("res://Images/barHorizontal_red.png")

# onready variables
onready var archer_container = $archer
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
onready var spawn_timer = $spawn_timer
onready var buffer_label = $buffer as RichTextLabel
onready var sprite = $archer/archer_sprite as AnimatedSprite
onready var health_bar = $hp_bar
onready var archer = $archer as Node2D
onready var scrolling_bg = $scrolling_background
onready var enemy_floor = $scrolling_background/enemy_floor
onready var wave_counter = $wave_label
onready var start_label = $start
onready var game_over_label = $game_over
onready var wave_complete_label = $wave_complete
onready var sfx_controller = $sfx_node

# other global variables
var exempt_moving_bgs = [] # the backgrounds that are exempt from stopping. (clouds, etc)
var sliding_audio_tracks = []
var archer_position = 420
var audio_tense_hp_1 = false
var audio_tense_hp_2 = false
var last_index_spawned = -1
var typed_buffer = ""
var active_words = []
var alpha_regex = RegEx.new()
var current_wave_size = 5
var current_wave_spawned_count = 0
var min_word_length = 3
var max_word_length = 5 # has to be at LEAST min_word_length + 1
var enemy_speed = 1.1
var total_enemies_killed = 0
var enemies_killed = 0
var spawn_rate_min = 1.5
var spawn_rate_max = 4.0
var game_over = false
var started = false
var prev_enemy = null
var archer_running = false
var music_off = false

# export variables
export (int) var current_wave = 1

# called on ready
func _ready() -> void:
	randomize()
	alpha_regex.compile("[a-z]")
	stop_running()

# when "start" is typed, initializes the game
func start_game():
	started = true
	game_over = false
	start_label.visible = false
	wave_complete_label.visible = false
	archer_container.add_child(archer_obj)
	get_node("archer/archer_sprite").playing = true
	initialize_music()
	start_running()
	exempt_moving_bgs = [$scrolling_background/bg_layer_3, $scrolling_background/bg_layer_4]
	typed_buffer = ""
	buffer_label.text = ""
	start_wave()

# when the game ends
func stop_world():
	spawn_timer.stop()
	
	# kill all enemies
	for enemy in enemy_floor.get_children():
		if enemy == null:
			continue
		enemy.die()

	# play death animation
	sprite.play("Death")
	play_gameover_music()
	
	# clear exempt moving bgs since everything stops moving now
	exempt_moving_bgs = []
	stop_running()
	
	# wait till death anim is done to end the game
	yield(sprite, "animation_finished")
	stop_game()

func stop_game():
	game_over = true
	game_over_label.visible = true

############################
# CORE GAME PROCESSES
############################

# called every frame, checks enemy attacking
func _process(delta):
	process_sliding_audio()
	if started and not game_over:
		for enemy in enemy_floor.get_children():
			if enemy == null or enemy.dead:
				continue
			if abs(enemy.global_position.x - archer_position + ENEMY_RANGE) <= enemy.offset:
				if not enemy.attacking and not enemy.dead:
					enemy.attack()
					yield(enemy.sprite, "animation_finished")
					if (enemy.successfully_attacked && !enemy.dying && !enemy.dead):
						archer_obj.take_hit(enemy.damage)
						current_wave_spawned_count -= 1 # spawn one more this round
						check_health()

# called on input events, keeps track of player typing
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var type_event = event as InputEventKey
		if type_event.scancode == KEY_SPACE or type_event.scancode == KEY_ENTER:
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

# checks the player input against the enemies on the field
func check_words():
	if not started:
		if typed_buffer == "start":
			start_game()
	elif game_over:
		if typed_buffer == "restart":
			get_tree().reload_current_scene()
	else:
		for enemy in enemy_floor.get_children():
			if enemy == null or enemy.dead or enemy.dying:
				continue
			var prompt = enemy.get_prompt()
			if prompt == typed_buffer:
				# clear buffer
				typed_buffer = ""
				buffer_label.text = typed_buffer
				stop_running()
				kill_enemy(enemy)
				yield(sprite, "animation_finished")

				# actually kill the enemy now
				if prev_enemy != null || enemy != null:
					sfx_controller.play_enemy_death_sound()
				
				if prev_enemy != null:
					prev_enemy.die()
				if enemy != null:
					enemy.die()

				start_running()

				if enemies_killed >= current_wave_size:
					total_enemies_killed += enemies_killed
					enemies_killed = 0
					stop_wave()
				break

# check players health to determine when he dies
func check_health():
	if archer_obj == null:
		return
	if archer_obj.health <= 0:
		stop_world()
	health_bar.value = archer_obj.health
	if health_bar.value < LOW_HP:
		health_bar.set_progress_texture(red_health)
	elif health_bar.value < MEDIUM_HP:
		health_bar.set_progress_texture(yellow_health)
	else:
		health_bar.set_progress_texture(green_health)
	$hp_bar/health_label.parse_bbcode(
		str("[center]", health_bar.value, "/" + str(FULL_HP) + "[/center]")
	)
	check_health_for_audio(archer_obj.health)

############################
# WAVES & DIFFICULTY
############################
func start_wave():
	wave_complete_label.visible = false
	current_wave_spawned_count = 0
	spawn_timer.wait_time = 1
	spawn_timer.start()
	wave_counter.parse_bbcode("WAVE %d" % current_wave)
	audio_on_wave_start()

func stop_wave():
	wave_complete_label.visible = true
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
	if current_wave == 2:
		current_wave_size += 2
	
	if current_wave % 2 == 0:
		current_wave_size += 1
		
	if current_wave % 3 == 0:
		enemy_speed += 0.15
		if spawn_rate_max > 2.0 :
			spawn_rate_max -= .5
		if max_word_length < MAX_LENGTH + 1:
			max_word_length += 1

	if current_wave % 6 == 0:
		if min_word_length < max_word_length - 1:
			min_word_length += 1
		if spawn_rate_min > 0.75:
			spawn_rate_min -= 0.25

func gain_kill_bounty():
	if archer_obj != null && archer_obj.health < FULL_HP:
		archer_obj.health += 1
		check_health()

############################
# SCROLLING BACKGROUND
############################
# the player starts running, so the background can begin moving again
func start_running():
	archer_running = true
	for bg in scrolling_bg.get_children():
		if bg in exempt_moving_bgs:
			bg.move_fast()
		else:
			bg.start_scrolling()

	for enemy in enemy_floor.get_children():
		if enemy == null or enemy.dead or enemy.attacking:
			continue
		enemy.archer_running()

	sprite.play("Run")

# the player stops running, so the background can slows/stops.
func stop_running():
	archer_running = false
	for bg in scrolling_bg.get_children():
		if bg in exempt_moving_bgs:
			# The clouds continue moving (slower than usual) when archer stops
			bg.move_slow()
		else:
			bg.halt_scrolling()
	for enemy in enemy_floor.get_children():
		if enemy == null:
			continue
		enemy.archer_stopped()

############################
# ENEMY SPAWNING AND DEATH
############################

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	spawn_timer.stop()
	spawn_timer.wait_time = rand_range(spawn_rate_min, spawn_rate_max)
	spawn_timer.start()

func spawn_enemy():
	# Don't spawn any more enemies if the max have been spawned this wave.
	if current_wave_spawned_count >= current_wave_size:
		return
	current_wave_spawned_count += 1
	
	var enemy_instance = Enemy.instance()
	var randInt = randi()
	var spawns = r_spawn_points.get_children()
	var direction = -1
	var index = randInt % spawns.size()
	if index != last_index_spawned:
		index = (randInt + 1) % spawns.size()

	enemy_instance.init(direction, enemy_speed, min_word_length, max_word_length)
	enemy_floor.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position

func kill_enemy(enemy):
	enemies_killed += 1

	if sprite.animation == "Attack":
		sprite.set_frame(0)
		if prev_enemy != null:
			prev_enemy.die()

	sfx_controller.play_archer_attack_sound()
	sprite.play("Attack")
	prev_enemy = enemy
	
	gain_kill_bounty()
	
	if enemies_killed == 1:
		audio_on_enemy_first_killed()

############################
# ANIMATION
############################
func _on_archer_sprite_animation_finished():
	pass

############################
# AUDIO
############################
func initialize_music():
	for audio_node in get_node("audio_node").get_children():
		audio_node.volume_db = MIN_VOLUME
		audio_node.play()
	audio_enable("audio_bass_1")
	audio_enable("audio_percussion_1")

func get_audio_position():
	var pos = get_node("audio_node/audio_bass_1").get_playback_position()
	return pos

func audio_enable(layer_name):
	if get_node("audio_node/" + layer_name) != null:
		get_node("audio_node/" + layer_name).volume_db = MAX_VOLUME

func play_frozen_1():
	if !audio_tense_hp_1:
		fade_in_audio("audio_string_frozen_1")
		audio_tense_hp_1 = true

func play_frozen_2():
	if !audio_tense_hp_2:
		fade_in_audio("audio_string_frozen_2")
		audio_tense_hp_2 = true

func fadeout_frozen_1():
	if current_wave > 8:
		return
	if audio_tense_hp_1:
		fade_out_audio("audio_string_frozen_1")
		audio_tense_hp_1 = false
		
func fadeout_frozen_2():
	if current_wave > 8:
		return
	if audio_tense_hp_2:
		fade_out_audio("audio_string_frozen_2")
		audio_tense_hp_2 = false

func check_health_for_audio(health_num):
	if (!audio_tense_hp_1 && health_num < MEDIUM_HP):
		play_frozen_1()
	elif audio_tense_hp_1 && health_num >= MEDIUM_HP:
		fadeout_frozen_1()
		
	if (!audio_tense_hp_2 && health_num < HIGH_HP):
		play_frozen_2()
	elif audio_tense_hp_2 && health_num >= HIGH_HP:
		fadeout_frozen_2()

func audio_on_enemy_first_killed():
	fade_in_audio("audio_string_beat_1", 180)

func audio_on_wave_start():
	if current_wave == 2:
		fade_in_audio("audio_bass_2")
	if current_wave == 3:
		fade_in_audio("audio_string_long_2")
	if current_wave == 4:
		fade_in_audio("audio_piano_1")
		fade_in_audio("audio_violin_1")
	if current_wave == 5:
		fade_in_audio("audio_piano_2")
		fade_in_audio("audio_percussion_2")
	if current_wave == 6:
		fade_in_audio("audio_string_beat_2")
		play_frozen_2()
	if current_wave == 7:
		play_frozen_1()
	if current_wave == 8:
		fade_in_audio("audio_choir_1")
	if current_wave == 10:
		fade_in_audio("audio_percussion_3", 180)
		fade_in_audio("audio_percussion_4", 180)

func fade_in_audio(audio_name, duration = 120):
	add_slide_audio(audio_name, MAX_VOLUME, duration)
	
func fade_out_audio(audio_name, duration = 120):
	add_slide_audio(audio_name, MIN_VOLUME, duration)

func play_gameover_music():
	for audio_node in get_node("audio_node").get_children():
		audio_node.volume_db = MIN_VOLUME
	var stream = get_node("audio_node/game_over_music")
	stream.volume_db = MAX_VOLUME
	stream.play()

# Slide the volume of a specified track layer over the given duration.
func add_slide_audio(audio_name, dest_volume, duration = 120):
	var stream = get_node("audio_node/" + audio_name)
	
	if dest_volume > MAX_VOLUME:
		dest_volume = MAX_VOLUME
	if dest_volume < MIN_VOLUME:
		dest_volume = MIN_VOLUME
		
	# Don't add to the sliding list if the volume already matches.
	if int(round(dest_volume)) == int(round(stream.volume_db)):
		return
		
	var diff = dest_volume - stream.volume_db
	var step_change = diff / duration
	
	var params = {
		"stream": stream, 
		"dest_volume": dest_volume,
		"duration": duration, 
		"step_change": step_change,
	}
	sliding_audio_tracks.append(params)
	
func process_sliding_audio():
	for a in sliding_audio_tracks:
		var stream = a["stream"]
		if int(round(stream.volume_db)) == int(round(a["dest_volume"])) or a["duration"] <= 0:
			stream.volume_db = a["dest_volume"]
			sliding_audio_tracks.erase(a)
		else:
			stream.volume_db += a["step_change"]
			a["duration"] -= 1

func _on_mute_music_button_up():
	music_off = !music_off
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_off)

func _on_mute_sfx_button_up():
		sfx_controller.toggle_sound_fx()
