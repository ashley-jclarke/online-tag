extends StaticBody2D

@onready var timer: Timer = $Timer
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    visible = false
    collision.disabled = true


func _on_pressure_plate_pressure_plate_pressed() -> void:
    visible = true
    collision.disabled = false
    timer.start(15)


func _on_timer_timeout() -> void:
    visible = false
    collision.disabled = true