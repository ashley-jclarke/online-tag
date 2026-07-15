extends Area2D

signal pressure_plate_pressed
signal pressure_plate_unpressed

var pressed = false

func _process(_delta):
	var player_in = false
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			player_in = true
	if pressed != player_in:
		if pressed: pressure_plate_unpressed.emit()
		else: pressure_plate_pressed.emit()
	pressed = player_in
	
	if  pressed: $AnimatedSprite2D.frame = 1
	if !pressed: $AnimatedSprite2D.frame = 0
