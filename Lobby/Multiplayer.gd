extends CheckButton

@onready var multiplayer_options = $Node/Control
@onready var INPUT_IP = $Node/Control/VBoxContainer/TabContainer/Host/VBoxContainer/HBoxContainer/IP
@onready var INPUT_PORT = $Node/Control/VBoxContainer/TabContainer/Host/VBoxContainer/HBoxContainer/PORT
@onready var INPUT_NAME = $Node/Control/VBoxContainer/Name
@onready var error_message_label = $ErrorMessage
@onready var player_count_label = $PlayerCount
@onready var colour_picker = $Node/Control/VBoxContainer/ColorPicker

@onready var gamecodemenu = $Node/Control/VBoxContainer/TabContainer/Host/VBoxContainer/GameCode
@onready var gamecodelabel = $Node/Control/VBoxContainer/TabContainer/Host/VBoxContainer/GameCode/Label
@onready var gamecodecopy = $Node/Control/VBoxContainer/TabContainer/Join/VBoxContainer/Button

@onready var pastelabel = $Node/Control/VBoxContainer/TabContainer/Join/VBoxContainer/HBoxContainer/Code
@onready var pastedcode = $Node/Control/VBoxContainer/TabContainer/Join/VBoxContainer/HBoxContainer/Button


func _ready():
	gamecodemenu.visible = false
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

func _on_player_connected(_id):
	error_message_label.text = "Player Joined"
func _on_player_disconnected(_id):
	error_message_label.text = "Player Left"
func _on_connected_ok():
	error_message_label.text = "Joined!"

func _on_connected_fail():
	error_message_label.text = "Failed to connect"
func _on_server_disconnected():
	error_message_label.text = "Connection Failed"


func handle_input_data() -> bool:
	# Validate port
	for i in INPUT_PORT.text:
		if i not in "0123456789":
			error_message_label.text = "Port must be a number"
			return false
	if len(INPUT_PORT.text) != 4:
		error_message_label.text = "Port must be 4 digits"
		return false
	# Prevent an invisible name
	if INPUT_NAME.text.strip_edges() == "":
		error_message_label.text = "Type a name"
		return false
		
	# Set data
	PlayerManager.ip = INPUT_IP.text
	PlayerManager.port = int(INPUT_PORT.text)
	PlayerManager.user_name = INPUT_NAME.text
	PlayerManager.user_colour = [colour_picker.color.r, colour_picker.color.g, colour_picker.color.b]
	
	return true


func _on_host_pressed():
	if !handle_input_data():
		return
	
	error_message_label.text = str(PlayerManager.host())

	var ip = PlayerManager.upnp.query_external_address()
	
	INPUT_IP.text = ip
	var octets = ip.split(".")
	print(octets)
	var serializedcode = 0
	for i in range(4):
		serializedcode += int(octets[i]) << (8*i)
	
	serializedcode += PlayerManager.port << (8*4)

	gamecodemenu.visible = true
	gamecodelabel.text = str(serializedcode)




func _process(_delta):
	multiplayer_options.visible = button_pressed
	$F1.modulate = colour_picker.color
	$PlayerCount.text = str(len(PlayerManager.players))

# Attempt to connect to game
func _on_join_pressed():	
	error_message_label.text = str(PlayerManager.join())



func _on_infection_pressed():
	if !button_pressed:
		var scene = load("res://NormalTag/local.tscn")
		get_tree().change_scene_to_packed(scene)
		return
	if !handle_input_data():
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
		var scene = load("res://NormalTag/local.tscn")
		get_tree().change_scene_to_packed(scene)
		return
	if !handle_input_data():
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


func _on_copycode_pressed() -> void:
	# Set the contents of the clipboard
	DisplayServer.clipboard_set(gamecodelabel.text)


func _on_paste_pressed() -> void:
	var strtext = DisplayServer.clipboard_get()
	print(strtext)
	var code = int(strtext)
	pastelabel.text = str(strtext)


	var port = (code & (0b11111111111111111111111111111111 << (8*4))) >> 8*4
	PlayerManager.port = port
	print(port)

	var octet0 = code & 255
	var octet1 = (code & (255 << 8)) >> 8
	var octet2 = (code & (255 << (8*2))) >> 8*2
	var octet3 = (code & (255 << (8*3))) >> 8*3

	var ip = str(octet0) + "." + str(octet1) + "." +  str(octet2) + "." +  str(octet3)

	PlayerManager.ip = ip
