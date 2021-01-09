extends AnimatedSprite

onready var prompt = $target
# get the text from the target
onready var prompt_text = prompt.text

func get_prompt() -> String:
	return prompt_text
