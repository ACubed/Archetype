extends Node

const MAX_ENEMY_DEATH_SFX_INDEX = 4
const MAX_ARCHER_ATTACK_SFX_INDEX = 2
const MAX_CLACK_SFX_INDEX = 3
const MAX_ENEMY_ATTACK_SFX_INDEX = 1

const RAND_MIN_PITCH = 0.92
const RAND_MAX_PITCH = 1.11
const SFX_VOLUME_DB = -7.0
const SFX_SYSTEM_SOUNDS = 1

onready var current_enemy_death_index = 0
onready var current_archer_attack_index = 0
onready var current_clack_index = 0
onready var current_hammer_index = 0
onready var current_stab_index = 0
onready var current_lift_index = 0

var soundfx_off = false
var clack_down = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func play_enemy_death_sound():
	var stream = get_node("enemy_die_" + str(current_enemy_death_index))
	run_stream(stream)
	current_enemy_death_index += 1
	if current_enemy_death_index > MAX_ENEMY_DEATH_SFX_INDEX:
		current_enemy_death_index = 0

func play_archer_attack_sound():
	var stream = get_node("archer_attack_" + str(current_archer_attack_index))
	run_stream(stream)
	current_archer_attack_index += 1
	if current_archer_attack_index > MAX_ARCHER_ATTACK_SFX_INDEX:
		current_archer_attack_index = 0
	
func play_key_sound():
	var type = "up"
	if clack_down:
		type = "down"
	clack_down = !clack_down
	
	var stream = get_node("clack_" + type + "_" + str(current_clack_index))
	run_stream(stream, rand_volume(-10.0, SFX_VOLUME_DB + 2))
	current_clack_index += 1
	if current_clack_index > MAX_CLACK_SFX_INDEX:
		current_clack_index = 0

func play_enemy_attack_sound(anim_index):
	var stream = null
	if anim_index == 0:
		stream = get_node("enemy_attack_stab_" + str(current_stab_index))
		current_stab_index += 1
		if current_stab_index > MAX_ENEMY_ATTACK_SFX_INDEX:
			current_stab_index = 0
	if anim_index == 1:
		stream = get_node("enemy_attack_hammer_" + str(current_hammer_index))
		current_hammer_index += 1
		if current_hammer_index > MAX_ENEMY_ATTACK_SFX_INDEX:
			current_hammer_index = 0
	if anim_index == 2:
		stream = get_node("enemy_attack_lift_" + str(current_lift_index))
		current_lift_index += 1
		if current_lift_index > MAX_ENEMY_ATTACK_SFX_INDEX:
			current_lift_index = 0
		
	if stream != null:
		run_stream(stream)
		
	
func play_chime():
	run_stream_constant_pitch(get_node("chime_ok"))	

func play_wave_start():
	run_stream_constant_pitch(get_node("bells_wave_start"))
	
func play_wave_end():
	run_stream_constant_pitch(get_node("bells_wave_end"))
	
func play_magic_heal():
	run_stream_constant_pitch(get_node("bells_magic_heal"))
	
func play_powerup_get():
	run_stream_constant_pitch(get_node("bells_powerup_get"))
	
func rand_volume(range_start, range_end):
	randomize()
	return rand_range(range_start, range_end)
	
func run_stream(stream, vol = SFX_VOLUME_DB):
	if stream == null:
		return
	stream.stop()
	randomize()
	stream.pitch_scale = rand_range(RAND_MIN_PITCH, RAND_MAX_PITCH)
	stream.volume_db = vol
	stream.play()

func run_stream_constant_pitch(stream, vol = SFX_SYSTEM_SOUNDS):
	if stream == null:
		return
	stream.stop()
	stream.volume_db = vol
	stream.play()

func toggle_sound_fx():
	soundfx_off = !soundfx_off
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound Effects"), soundfx_off)
