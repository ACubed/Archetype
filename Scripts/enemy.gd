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
var hit_points = 10
var offset = 40
var archer_x = 420
var attacking = false
var dead = false

func init(d: int, s: float, min_word_length: int, max_word_length: int ) -> void:
	randomize()
	speed = s
	speed *= d
	min_len = min_word_length
	max_len = max_word_length

func _ready():
	set_random_word()

func set_random_word():
	prompt_text = get_word()
	prompt.parse_bbcode(set_center_tags(prompt_text))

func _physics_process(delta: float) -> void:
	if not abs(global_position.x - archer_x) <= offset:
		global_position.x += speed

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
	if regex.search(word[0]):
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
	
func attack():
	if dead:
		return
	attacking = true
	sprite.play("Attack")
	yield(sprite, "animation_finished")
	attacking = false

func die():
	if attacking:
		return
	dead = true
	speed = -0.22
	prompt.parse_bbcode("")
	sprite.play("Death")
	yield(sprite, "animation_finished")
	queue_free()
	
