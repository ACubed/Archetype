extends ParallaxLayer

export(float) var scroll_speed

var in_motion = false
var move_slow = false
# Called when the node enters the scene tree for the first time.
func _ready():
	in_motion = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if in_motion:
		if move_slow:
			self.motion_offset.x -= scroll_speed/2
		else:
			self.motion_offset.x -= scroll_speed
			
func show_offset(other):
	print([self.motion_offset.x, other])
			
func halt_scrolling():
	in_motion = false

func start_scrolling():
	in_motion = true

func move_slow():
	move_slow = true

func move_fast():
	move_slow = false
