extends AnimatedSprite

export (float) var speed = 0.1

# get the text
onready var prompt = $target
onready var prompt_text = prompt.text

func _physics_process(delta):
	global_position.x -= speed

func get_prompt() -> String:
	return prompt_text
