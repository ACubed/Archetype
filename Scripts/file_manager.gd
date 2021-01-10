extends Node

var three_file = 'res://Words/three.txt'
var four_file = 'res://Words/four.txt'
var five_file = 'res://Words/five.txt'
var six_file = 'res://Words/six.txt'
var seven_file = 'res://Words/seven.txt'
var eight_file = 'res://Words/eight.txt'

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
