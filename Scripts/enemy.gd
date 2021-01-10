extends Node2D

export (float) var speed = 0.2
export (int) var direction = 1

# get the text
onready var sprite = $enemy_sprite as AnimatedSprite
onready var prompt = $target as RichTextLabel
onready var prompt_text = prompt.text

onready var file_manager = preload("file_manager.gd").new()
onready var words_dict = file_manager.dict
var min_len = 3
var max_len = 4
var damage = 10
var offset = 70
var archer_x = 200
var successfully_attacked = false
var attacking = false
var dead = false
var dying = false
var taunting = false
var initial_speed = 0
var archer_moving = true
var sfx_controller = null

func init(d: int, s: float, min_word_length: int, max_word_length: int, sfx: Node) -> void:
	randomize()
	speed = s
	speed *= d
	initial_speed = speed
	min_len = min_word_length
	max_len = max_word_length
	sfx_controller = sfx

func _ready():
	set_random_word()
	sprite.play("Run")

func set_random_word():
	prompt_text = get_word()
	prompt.parse_bbcode(set_center_tags(prompt_text))

func _physics_process(delta: float) -> void:
	if attacking or dying or taunting:
		pass
	elif not abs(global_position.x - archer_x) <= offset:
		position.x += speed

func get_prompt() -> String:
	return prompt_text

func get_word() -> String:
	var length = get_length()
	randomize()
	var index = randi() % words_dict[length].size()
	var word = words_dict[length][index]
	var regex = RegEx.new()
	regex.compile("[^a-z]")
	
	# Capitalized words are probably not actual words. Pick a different word.
	if word.empty() or regex.search(word.left(1)):
		return get_word()
	
	var lower = word.to_lower()
	# Ensure that every character is a lowercase and alphabetical.
	if !regex.search(lower):
		return lower
	else:
		return get_word()

func set_center_tags(string: String):
	return "[center]" + string + "[/center]"

func get_length() -> int:
	randomize()
	var len_range = range(min_len, max_len)
	return len_range[randi() % len_range.size()]

func set_speed(new_speed):
	speed = new_speed
	
func get_speed():
	return speed

# Mode when the player has stopped moving in this direction.
func archer_stopped():
	archer_moving = false
	
# Mode when the player is moving toward this enemy.
func archer_running():
	archer_moving = true

func play_random_attack_animation():
	randomize()
	var rand_index = randi() % 3
	sprite.play("Attack" + str(rand_index))

func attack():
	if dying or dead:
		return
	attacking = true
	play_random_attack_animation()
	yield(sprite, "animation_finished")
	successfully_attacked = true
	attacking = false
	queue_free()

func die():
	if attacking:
		attacking = false
	if !dying:
		sfx_controller.play_enemy_death_sound()
	dying = true
	prompt.parse_bbcode("")
	sprite.play("DeathArrow")
	yield(sprite, "animation_finished")
	successfully_attacked = false
	dead = true
	dying = false
	queue_free()
	
func taunt():
	if attacking:
		attacking = false
	sprite.play("Taunt")
	taunting = true
