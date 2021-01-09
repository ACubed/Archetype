extends ParallaxLayer

export(float) var scroll_speed

var archer_moving = false
# Called when the node enters the scene tree for the first time.
func _ready():
	archer_moving = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if archer_moving:
		self.motion_offset.x -= scroll_speed

func stop_archer():
	archer_moving = false

func start_archer():
	archer_moving = true
