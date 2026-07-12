extends StaticBody2D

var left = false
var right = false

func _on_pressure_plate_2_pressure_plate_pressed():
	left = true


func _on_pressure_plate_3_pressure_plate_pressed():
	right = true


func _on_pressure_plate_2_pressure_plate_unpressed():
	left = false


func _on_pressure_plate_3_pressure_plate_unpressed():
	right = false

func _process(delta):
	$CollisionShape2D.disabled = !(left and right)
	visible = left and right
