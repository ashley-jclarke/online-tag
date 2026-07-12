extends StaticBody2D

@onready var coll = $CollisionShape2D

func _on_pressure_plate_pressure_plate_pressed():
	coll.disabled = false
	visible = true



func _on_pressure_plate_pressure_plate_unpressed():
	coll.disabled = true
	visible = false
