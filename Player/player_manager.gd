extends Node

@export var player: PackedScene = preload("res://Player/player.tscn")

signal terminated_server
signal rejection_from_active_lobby

# Store player info
var players = {}
var upnp
var port = 1234
var ip = "127.0.0.1"


# Have we connected to the server/hosted the server?
var connected = false

# User actors info
var user_colour = [1.0, 1.0, 1.0]
var user_name = "Player"

var rng = RandomNumberGenerator.new()

# Incept close request to make sure that any port mappings are closed
# Multiplayer makes use of hole punching so not closing these is sometimes unsafe
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		close_game()

func close_game():
	# Close ports for hole punched host
	if multiplayer.is_server() and upnp != null:
		upnp.delete_port_mapping(port, "UDP")
		upnp.delete_port_mapping(port, "TCP")
	get_tree().quit()

# Number of players connected to server
func player_count():
	return len(players)

# Connect multiplayer signals
func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Log player connected
func _on_player_connected(id):
	print("Player connected " + str(id))

# Log player disconnected and remove them from player data/the game
func _on_player_disconnected(id):
	print("Player disconnected " + str(id))
	players.erase(id)

# Send player info to the server
func _on_connected_ok():
	print("Connected")
	send_player_information.rpc_id(1, user_name, multiplayer.get_unique_id(), user_colour)

# Couldn't connect to server
func _on_connected_fail():
	print("Connection failed")
	#error_message_label.text = "Connection failed..."

# Reset for server close
func _on_server_disconnected():
	print("Server Disconnected")
	players.clear()
	terminated_server.emit()
	#error_message_label.text = "Server terminated..."

# Send self player information to all users
@rpc("any_peer")
func send_player_information(player_name, id, new_color):
	if !PlayerManager.players.has(id):
		PlayerManager.players[id] = {
			"name": player_name,
			"id": id,
			"colour": new_color,
			"it": multiplayer.is_server()
		}
	# Resend player info to other users
	if multiplayer.is_server():
		for i in PlayerManager.players:
			send_player_information.rpc(PlayerManager.players[i]["name"], i, PlayerManager.players[i]["colour"])

func _on_quit_pressed():
	PlayerManager.close_game()

@rpc("any_peer","call_local")
func change_scene(scene):
	get_tree().change_scene_to_packed(load(scene))

@rpc("any_peer")
func reject():
	print("Cannot join an already active game")
	multiplayer.multiplayer_peer.disconnect_peer(multiplayer.get_unique_id())
	rejection_from_active_lobby.emit()

# Attempt to host server
# Uses universal plug and play - hole punching
# Requires it to be enabled on the router
func host():
	PlayerManager.upnp = UPNP.new()
	var discover_result = PlayerManager.upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if PlayerManager.upnp.get_gateway() and PlayerManager.upnp.get_gateway().is_valid_gateway():
			
			var map_result_udp = PlayerManager.upnp.add_port_mapping(PlayerManager.port, 0, "TagGame", "UDP", 0)
			var map_result_tcp = PlayerManager.upnp.add_port_mapping(PlayerManager.port, 0, "TagGame", "TCP", 0)
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				PlayerManager.upnp.add_port_mapping(PlayerManager.port, 0, "", "UDP", 0)
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				PlayerManager.upnp.add_port_mapping(PlayerManager.port, 0, "", "TCP", 0)

	
	# Create server.
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PlayerManager.port, 32)
	if result != OK:
		return result
	
	multiplayer.multiplayer_peer = peer
	PlayerManager.send_player_information(PlayerManager.user_name, multiplayer.get_unique_id(), PlayerManager.user_colour)
	
	connected = true
	return "Server started..."

# On join game
func join():
	players.clear()
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	if result != OK:
		return result
	
	multiplayer.multiplayer_peer = peer
	PlayerManager.send_player_information.rpc_id(1, PlayerManager.user_name, multiplayer.get_unique_id(), PlayerManager.user_colour)
	
	connected = true
	return "Connected"
