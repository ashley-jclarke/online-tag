extends CharacterBody2D

@onready var skin = $AnimatedSprite2D
@onready var num: Label = $Label
@onready var timer = $DeleteTimer
@onready var immunity_timer = $ImmunityTimer
@onready var synchroniser = $MultiplayerSynchronizer

const ACCELERATION = 25.0
const SPEED = 300.0
const IT_SPEED = SPEED * 1.2
const JUMP_VELOCITY = -450.0

var player_number = "1"
var jump_button = "s"
var left_button = "a"
var right_button = "d"

enum STATE {
	MENU,
	TAG,
	INFECTION
}

var state = STATE.MENU
var owned_by_user = false
var infection = false
var tag = false

var sync_pos = Vector2.ZERO

var it = false
var single_it = false
var immune = false
var single_immune = false
var color = [1.0, 1.0, 1.0]
var speed = SPEED
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var elapsed_time = 0

func _ready():
	velocity.y = JUMP_VELOCITY * 0.5
	velocity.x = SPEED
	set_controller(str(name).to_int())
	$AudioStreamPlayer.enabled = false

func set_controller(id):
	synchroniser.set_multiplayer_authority(int(id))
	
func  _process(delta):
	num.text = player_number
	skin.modulate.r = color[0]
	skin.modulate.g = color[1]
	skin.modulate.b = color[2]
	elapsed_time += delta
	if (immune and PlayerManager.connected) or (single_immune and PlayerManager.connected): modulate.a = 0.5
	else: modulate.a = 1.0
	
	if (it and PlayerManager.connected) or (single_it and !PlayerManager.connected):
		num.modulate.r = 1.0
		num.modulate.g = 0.0
		num.modulate.b = 0.0
	else:
		num.modulate.r = 1.0
		num.modulate.g = 1.0
		num.modulate.b = 1.0


const MAX_JUMPS = 1
var jumps = MAX_JUMPS

func _physics_process(delta):
	if synchroniser.get_multiplayer_authority() != multiplayer.get_unique_id() and PlayerManager.connected: 
		global_position = lerp(global_position, sync_pos, 0.5)
		return
	
	if Input.is_action_just_pressed("escape"):
		$CanvasLayer.visible = !$CanvasLayer.visible
	sync_pos = global_position
	$AudioStreamPlayer.enabled = $CanvasLayer/Control/HBoxContainer/VBoxContainer2/Music.button_pressed 
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if ((Input.is_action_pressed("reset_control_group") and is_on_floor()) or Input.is_action_just_pressed("reset_control_group")) and jumps > 0:
		velocity.y = JUMP_VELOCITY
		jumps -= 1
	
	if is_on_floor():
		jumps = MAX_JUMPS

	var direction = Input.get_axis(left_button, right_button)
	if direction:
		skin.flip_h = direction > 0
		skin.play("Walking")
		velocity.x = move_toward(velocity.x, speed*direction, ACCELERATION);
	else:
		skin.stop()
		velocity.x = move_toward(velocity.x, 0, ACCELERATION)

	move_and_slide()
	
	if immune:      speed = IT_SPEED * 3
	elif it:        speed = IT_SPEED
	else:           speed = SPEED
	
	if state == STATE.MENU:
		
		if Input.is_action_pressed(left_button) and Input.is_action_pressed(right_button):
			if timer.is_stopped():
				timer.start(3)
		else:
			timer.stop()

func _on_delete_timer_timeout():
	if Input.is_action_pressed(left_button) and Input.is_action_pressed(right_button):
		get_parent().release([left_button, right_button, jump_button])
		self.queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		if it and !body.immune and PlayerManager.connected:
			body.it = true
			if tag or !PlayerManager.connected: 
				immune = true
				immunity_timer.start(3)
				it = false
		else:
			if body.single_it and !single_immune:
				single_it = true
				body.single_it = false
				body.single_immune = true
				body.immunity_timer.start(3)
				print("Recieved the tag" + str(player_number))
		
	#if body.is_in_group("Player"):
		#if not body.immune:
			#it = false 

func _on_immunity_timer_timeout():
	immune = false
	single_immune = false
	#it = false

func update_position(pos):
	global_position = pos


func _on_leave_game_pressed():
	multiplayer.multiplayer_peer.close()

func _on_music_pressed():
	pass # Replace with function body.
