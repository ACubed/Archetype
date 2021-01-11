extends Node

var three_file = 'user://Words/three.txt'
var four_file = 'user://Words/four.txt'
var five_file = 'user://Words/five.txt'
var six_file = 'user://Words/six.txt'
var seven_file = 'user://Words/seven.txt'
var eight_file = 'user://Words/eight.txt'

var dict = {
	3: load_file(three_file),
	4: load_file(four_file),
	5: load_file(five_file),
	6: load_file(six_file),
	7: load_file(seven_file),
	8: load_file(eight_file),
}

func load_file(file):
	var f = File.new()
	var words = []
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		words.append(line)
	f.close()
	return words
