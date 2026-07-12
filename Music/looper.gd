extends AudioStreamPlayer

var enabled = false

func _process(delta):
	if !playing and enabled:
		play()
	elif !enabled:
		stop()
