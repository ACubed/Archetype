extends ParallaxLayer

export(float) var scroll_speed

var archer_moving = false
var move_slow = false
# Called when the node enters the scene tree for the first time.
func _ready():
	archer_moving = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if archer_moving:
		if move_slow:
			self.motion_offset.x -= scroll_speed/2
		else:
			self.motion_offset.x -= scroll_speed

func stop_archer():
	archer_moving = false

func start_archer():
	archer_moving = true

func move_slow():
	move_slow = true

func move_fast():
	move_slow = false
