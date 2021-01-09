extends Node2D

export (float) var speed = 0.1
export (int) var direction = 1
export (int) var target_length = 3

# get the text
onready var sprite = $enemy_sprite as AnimatedSprite
onready var prompt = $target as RichTextLabel
onready var prompt_text = prompt.text

onready var file_manager = preload("file_manager.gd").new()
onready var words_dict = file_manager.dict

func init(d: int, word_length: int) -> void:
	randomize()
	target_length = word_length
	speed *= d

func _ready():
	set_random_word(target_length)

func set_random_word(length):
	prompt_text = get_word(target_length)
	prompt.parse_bbcode(set_center_tags(prompt_text))

func _physics_process(delta: float) -> void:
	global_position.x += speed

func get_prompt() -> String:
	return prompt_text

func get_word(length: int) -> String:
	var index = randi() % words_dict[length].size()
	return words_dict[length][index].to_lower()

func set_center_tags(string: String):
	return "[center]" + string + "[/center]"
