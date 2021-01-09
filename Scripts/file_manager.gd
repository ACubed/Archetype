extends Node

var three_file = 'res://Words/three.txt'
var four_file = 'res://Words/four.txt'
var five_file = 'res://Words/five.txt'
var six_file = 'res://Words/six.txt'

var dict = {
	3: load_file(three_file),
	4: load_file(four_file),
	5: load_file(five_file),
	6: load_file(six_file),
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
