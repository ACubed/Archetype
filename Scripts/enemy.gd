extends AnimatedSprite

export (float) var speed = 0.1
export (int) var direction = 1

onready var player = get_node("/root/Scenes/World/archer")
# get the text
onready var prompt = $target
onready var prompt_text = prompt.text

func init(d: int) -> void:
	speed *= d
	
func _physics_process(delta) -> void:
	global_position.x += speed

func get_prompt() -> String:
	return prompt_text
