extends SubViewport


func _process(delta):
	$Control/Label.text = str($Control/GameTimer.time_left)
