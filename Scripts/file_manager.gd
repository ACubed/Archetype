extends Node

onready var three_file = 'res://Words/three.txt'
onready var four_file = 'res://Words/four.txt'
onready var five_file = 'res://Words/five.txt'
onready var six_file = 'res://Words/six.txt'

var dict = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	dict[3] = load_file(three_file)
	dict[4] = load_file(four_file)
	dict[5] = load_file(five_file)
	dict[6] = load_file(six_file)

func load_file(file):
	var f = File.new()
	var words = []
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		words.append(line)
	f.close()
	return words
