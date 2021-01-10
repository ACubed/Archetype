extends Node

const MAX_ENEMY_DEATH_SFX_INDEX = 4
const MAX_ARCHER_ATTACK_SFX_INDEX = 2

const RAND_MIN_PITCH = 0.92
const RAND_MAX_PITCH = 1.11

onready var current_enemy_death_index = 0
onready var current_archer_attack_index = 0

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
	
func run_stream(stream):
	stream.stop()
	randomize()
	stream.pitch_scale = rand_range(RAND_MIN_PITCH, RAND_MAX_PITCH)
	stream.play()
