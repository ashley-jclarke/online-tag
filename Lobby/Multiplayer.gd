extends CheckButton

@onready var multiplayer_options = $Node/Control
@onready var INPUT_IP = $Node/Control/VBoxContainer/HBoxContainer/VBoxContainer/IP
@onready var INPUT_PORT = $Node/Control/VBoxContainer/HBoxContainer/VBoxContainer/PORT
@onready var INPUT_NAME = $Node/Control/VBoxContainer/Name
@onready var error_message_label = $Node/ErrorMessage
@onready var player_count_label = $PlayerCount
@onready var colour_picker = $Node/Control/VBoxContainer/ColorPicker

func _ready():
	$AudioStreamPlayer.enabled = true
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	PlayerManager.rejection_from_active_lobby.connect(rejection_from_active_lobby)
	$F1.play("Walking")


func rejection_from_active_lobby():
	error_message_label.text = "Already in game"
	PlayerManager.connected = false

func _on_player_connected(id):
	error_message_label.text = "Player Joined"
func _on_player_disconnected(id):
	error_message_label.text = "Player Left"
func _on_connected_ok():
	error_message_label.text = "Joined"

func _on_connected_fail():
	error_message_label.text = "Failed to connect"
func _on_server_disconnected():
	error_message_label.text = "Connection Failed"


func handle_input_data() -> bool:
	for i in INPUT_PORT.text:
		if i not in "0123456789":
			error_message_label.text = "Port incorrect"
			return false
	if INPUT_NAME.text.strip_edges() == "":
		error_message_label.text = "Type a name"
		return false
	PlayerManager.ip = INPUT_IP.text
	PlayerManager.port = int(INPUT_PORT.text)
	PlayerManager.user_name = INPUT_NAME.text
	PlayerManager.user_colour = [colour_picker.color.r, colour_picker.color.g, colour_picker.color.b]
	
	return true


func _on_host_pressed():
	if !handle_input_data():
		return
	
	error_message_label.text = str(PlayerManager.host())
	
	INPUT_IP.text = PlayerManager.upnp.query_external_address()

func _process(delta):
	multiplayer_options.visible = button_pressed
	$F1.modulate = colour_picker.color
	$PlayerCount.text = str(len(PlayerManager.players))


func _on_join_pressed():
	#if PlayerManager.connected:
		#error_message_label.text = "Already connected"
		#return
	
	
	if !handle_input_data():
		return
	
	error_message_label.text = str(PlayerManager.join())



func _on_infection_pressed():
	if !button_pressed:
		error_message_label.text = "One-Client Coming Soon!"
		#var scene = load("res://NormalTag/ice_map.tscn")
		#get_tree().change_scene_to_packed(scene)
		return
	if !multiplayer.is_server():
		error_message_label.text = "Only the host can start a game"
		return
	if PlayerManager.player_count() > 1:
		PlayerManager.change_scene.rpc("res://Infection/infection.tscn")
		return
	error_message_label.text = "Need more players"


func _on_tag_pressed():
	if !button_pressed:
		error_message_label.text = "One-Client Coming Soon!"
		#var scene = load("res://NormalTag/ice_map.tscn")
		#get_tree().change_scene_to_packed(scene)
		return
	if !multiplayer.is_server():
		error_message_label.text = "Only the host can start a game"
		return
	if PlayerManager.player_count() > 1:
		PlayerManager.change_scene.rpc("res://Tag/tag.tscn")
		return
	error_message_label.text = "Need more players"


func _on_quit_pressed():
	PlayerManager.close_game()
