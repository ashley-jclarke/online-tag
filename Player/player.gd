extends CharacterBody2D

# Players avatar
@onready var skin = $AnimatedSprite2D
# label that shows the players name
@onready var num: Label = $Label
@onready var timer = $DeleteTimer
@onready var immunity_timer = $ImmunityTimer
@onready var synchroniser = $MultiplayerSynchronizer

@onready var music_player = $AudioStreamPlayer
@onready var music_button = $Menu/Control/Music
@onready var leave_button = $Menu/Control/HBoxContainer/LeaveGame
@onready var menu = $Menu

const ACCELERATION = 25.0
const SPEED = 300.0
const IT_SPEED = SPEED * 1.2
const JUMP_VELOCITY = -450.0

# Default keybinds
# Can be rebound
# - This game started as being played multiplayer on a single keyboard so players could choose their keybinds before a round started
var player_number = "1"
var jump_button = "s"
var left_button = "a"
var right_button = "d"

enum STATE {
	MENU,
	TAG,
	INFECTION
}

# The location/game the player is in
var state = STATE.MENU
# Is this a remote actor or the user actor
var owned_by_user = false
# The game mode
var infection = false
var tag = false

var local_play = false


var sync_pos = Vector2.ZERO

var it = false
var single_it = false
var immune = false
var single_immune = false
var color = [1.0, 1.0, 1.0]
# Initial speed, differs to the const as it can change to sprinting
var speed = SPEED
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var elapsed_time = 0

func _ready():
	# Start with a mini jump and run
	velocity.y = JUMP_VELOCITY * 0.5
	velocity.x = SPEED
	
	set_controller(str(name).to_int())
	music_player.enabled = false

func set_controller(id):
	synchroniser.set_multiplayer_authority(int(id))
	
func  _process(delta):
	elapsed_time += delta

	# Update values as this scene is used in the lobby where they can be altered
	num.text = player_number
	skin.modulate.r = color[0]
	skin.modulate.g = color[1]
	skin.modulate.b = color[2]


	# Make the player slightly transparent to show they are in grace period
	if (immune and PlayerManager.connected) or (single_immune and PlayerManager.connected): modulate.a = 0.5
	else: modulate.a = 1.0

	# If the player is it then make their name red
	if (it and PlayerManager.connected) or (single_it and !PlayerManager.connected):
		num.modulate.r = 1.0
		num.modulate.g = 0.0
		num.modulate.b = 0.0
	else:
		num.modulate.r = 1.0
		num.modulate.g = 1.0
		num.modulate.b = 1.0

# Double jump vars
const MAX_JUMPS = 1
var jumps = MAX_JUMPS

func _physics_process(delta):
	# Update position if remote actor
	if synchroniser.get_multiplayer_authority() != multiplayer.get_unique_id() and PlayerManager.connected: 
		global_position = lerp(global_position, sync_pos, 0.5)
		return

	# Toggle visibility of menu. Menu not allowed in local play
	if Input.is_action_just_pressed("escape"):
		menu.visible = !menu.visible and !local_play

	# Make music enabled depend on if the button is toggled 
	music_player.enabled = music_button.button_pressed 
	
	sync_pos = global_position

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump/double jump.
	if ((Input.is_action_pressed("reset_control_group") and is_on_floor()) or Input.is_action_just_pressed("reset_control_group")) and jumps > 0:
		velocity.y = JUMP_VELOCITY
		jumps -= 1

	if is_on_floor():
		# Restore the players double jump
		jumps = MAX_JUMPS

	# Handle move and animation
	var direction = Input.get_axis(left_button, right_button)
	if direction:
		skin.flip_h = direction > 0
		skin.play("Walking")
		velocity.x = move_toward(velocity.x, speed*direction, ACCELERATION);
	else:
		skin.stop()
		velocity.x = move_toward(velocity.x, 0, ACCELERATION)

	move_and_slide()

	# Handle player speed
	# immune speed is faster so that players can get away during the grace period
	if immune:      speed = IT_SPEED * 3
	# it is faster than players so that the game isn't player looping it for 90 seconds
	elif it:        speed = IT_SPEED
	# Player is in normal mode
	else:           speed = SPEED

	# If in the menu, allow for player to remove themself from the game by holding left and right for 3 seconds
	if state == STATE.MENU:
		
		if Input.is_action_pressed(left_button) and Input.is_action_pressed(right_button):
			if timer.is_stopped():
				timer.start(3)
		else:
			timer.stop()

func _on_delete_timer_timeout():
	# If in the menu, allow for player to remove themself from the game by holding left and right for 3 seconds
	if Input.is_action_pressed(left_button) and Input.is_action_pressed(right_button):
		get_parent().release([left_button, right_button, jump_button])
		self.queue_free()

# Handle being tagged / tagging
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

# Remove immunity after grace period ends
func _on_immunity_timer_timeout():
	immune = false
	single_immune = false
	#it = false

# Change position of player, used for setting spawn position when loading into a game?
func update_position(pos):
	global_position = pos

# Leave the game
func _on_leave_game_pressed():
	multiplayer.multiplayer_peer.close()
