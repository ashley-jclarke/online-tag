extends AudioStreamPlayer

var enabled = false

# Loop audio
func _process(delta):
	if !playing and enabled:
		play()
	elif !enabled:
		stop()
