extends Node2D

var controls = {
	"1":{"owned":false},
	"2":{"owned":false},
	"3":{"owned":false},
	"4":{"owned":false},
	"5":{"owned":false},
	"6":{"owned":false},
	"7":{"owned":false},
	"8":{"owned":false},
	"9":{"owned":false},
	"0":{"owned":false},
	"-":{"owned":false},
	"q":{"owned":false},
	"w":{"owned":false},
	"e":{"owned":false},
	"r":{"owned":false},
	"t":{"owned":false},
	"y":{"owned":false},
	"u":{"owned":false},
	"i":{"owned":false},
	"o":{"owned":false},
	"p":{"owned":false},
	"[":{"owned":false},
	"]":{"owned":false},
	"a":{"owned":false},
	"s":{"owned":false},
	"d":{"owned":false},
	"f":{"owned":false},
	"g":{"owned":false},
	"h":{"owned":false},
	"j":{"owned":false},
	"k":{"owned":false},
	"l":{"owned":false},
	";":{"owned":false},
	"'":{"owned":false},
	"z":{"owned":false},
	"x":{"owned":false},
	"c":{"owned":false},
	"v":{"owned":false},
	"b":{"owned":false},
	"n":{"owned":false},
	"m":{"owned":false},
	",":{"owned":false},
	"_":{"owned":false},
	"up":{"owned":false},
	"down":{"owned":false},
	"left":{"owned":false},
	"right":{"owned":false},
}

var new_player_controls = []
var enabled = true

var colours = [
	[1.0, 1.0, 0.0],
	[1.0, 0.0, 1.0],
	[0.0, 1.0, 1.0],
	[1.0, 1.0, 1.0],
	[0.0, 0.5, 0.5],
	[0.5, 0.0, 0.5],
	[0.5, 0.5, 0.0],
	[0.5, 0.5, 0.7],
]
var colour_index = 0

@onready var keyboard = $Keys
@export var player: PackedScene = load("res://player.tscn")

func _ready():
	for i in range(keyboard.get_child_count()-1):
		controls[keyboard.get_child(i).name]["index"] = i
		controls[keyboard.get_child(i).name]["colour"] = [0.3, 0.3, 0.3]

func create_new_player(up, left, right):
	var player_num = str(get_child_count())
	var new_player = player.instantiate()
	new_player.player_number = player_num
	new_player.jump_button = up
	new_player.left_button = left
	new_player.right_button = right
	new_player.color = colours[colour_index % len(colours)]
	controls[up]["colour"] = new_player.color
	controls[left]["colour"] = new_player.color
	controls[right]["colour"] = new_player.color
	colour_index += 1
	add_child(new_player)

func _process(delta):
	for num in range(get_child_count() -1):
		get_child(num + 1).player_number = str(num + 1)
	if not enabled:
		return
	for key in controls.keys():
		if Input.is_action_just_pressed(key) and controls[key]["owned"] == false:
			new_player_controls.append(key)
		if len(new_player_controls) >= 3:
			create_new_player(new_player_controls[0], new_player_controls[1], new_player_controls[2])
			controls[new_player_controls[0]]["owned"] = true
			controls[new_player_controls[1]]["owned"] = true
			controls[new_player_controls[2]]["owned"] = true
			new_player_controls = []
		if Input.is_action_just_pressed("reset_control_group"):
			new_player_controls = []
		
		if key in new_player_controls:
			keyboard.get_child(controls[key]["index"]).modulate.g = 0.0
		else:
			var c = controls[key]["colour"]
			keyboard.get_child(controls[key]["index"]).modulate.r = c[0]
			keyboard.get_child(controls[key]["index"]).modulate.g = c[1]
			keyboard.get_child(controls[key]["index"]).modulate.b = c[2]

func release(keys_to_free):
	for i in keys_to_free:
		controls[i]["owned"] = false
		controls[i]["colour"] = [0.3, 0.3, 0.3]

func begin_game():
	var index_of_first_it = get_child_count() - 1
	get_child(index_of_first_it).it = true
	for i in range(get_child_count()-1):
		get_child(i+1).state = get_child(i+1).STATE.TAG
	enabled = false


