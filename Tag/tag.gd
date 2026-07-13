extends Node2D

# Players object which contains all the players
@onready var players = $Players
# Spawn points of not-it players
@onready var normal_spawn = $Spawns/NSpawn
# Spawn point of it
@onready var infected_spawn = $Spawns/ISpawn
# Camera
@onready var cam = $PlayerTracker
# Main label for the game
@onready var info = $CanvasLayer/Label
# The timer that tracks how long is left of an active round
@onready var game_timer = $Timer
# The timer that tracks the delay between rounds
@onready var game_cooldown_timer = $Timer
# The multiplayer synchronizer (obv)
@onready var syncer = $MultiplayerSynchronizer

# Checks if an active game is running
var in_game = false
# Stores the name of the most recent loser (loses like hot potato)
var loser = ""
# How long a round lasts and how long the time is between rounds
const ROUND_LENGTH = 90
const ROUND_COOLDOWN = 15

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect multiplayer signals
	PlayerManager.terminated_server.connect(server_terminated)
	multiplayer.peer_connected.connect(_on_player_connected)

	# Create and place player instances at the spawn locations
	for p in PlayerManager.players:
		create_player(PlayerManager.players[p]["name"], p, PlayerManager.players[p]["colour"], false, normal_spawn.global_position)

	# Game starts on cooldown
	game_timer.start(ROUND_COOLDOWN)
	in_game = false

	# Sets the controller of other player objects to be the host
	syncer.set_multiplayer_authority(1)

func _on_player_connected(id):
	# Do not allow players to join whilst in a game
	PlayerManager.reject.rpc_id(id)
	multiplayer.multiplayer_peer.disconnect_peer(id)

func server_terminated():
	# If the server closes return to the lobby
	var lobby = load("res://Lobby/lobby.tscn")
	get_tree().change_scene_to_packed(lobby)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Make sure all players are accounted for
	# Removes players that have left the game
	if PlayerManager.player_count() != players.get_child_count():
		for player in players.get_children():
			# Remove players that should not be there
			if !PlayerManager.players.has(str(player.name).to_int()):
				player.queue_free()
		for player in PlayerManager.players:
			# Confirm that this player has been added
			var loaded = false
			# Linear search to check
			for loaded_player in players.get_children():
				if str(loaded_player.name).to_int() == player:
					loaded = true
			# If not then add the player
			if !loaded:
				create_player(PlayerManager.players[player]["name"],player,PlayerManager.players[player]["colour"], true, infected_spawn.global_position)

	### Calculate the position of the camera ###
	var min_pos = Vector2(cam.global_position.x,cam.global_position.y)
	var max_pos = Vector2(cam.global_position.x,cam.global_position.y)
	
	for p in players.get_children():
		if p.global_position.x < min_pos.x: min_pos.x = p.global_position.x
		if p.global_position.x > max_pos.x: max_pos.x = p.global_position.x
		if p.global_position.y < min_pos.y: min_pos.y = p.global_position.y
		if p.global_position.y > max_pos.y: max_pos.y = p.global_position.y
	
	min_pos += Vector2(-100, -150)
	max_pos += Vector2( 100,  100)
	
	cam.global_position.x = (min_pos.x + max_pos.x) / 2
	cam.global_position.y = (min_pos.y + max_pos.y) / 2
	
	var new_size = Vector2(max_pos.x - min_pos.x, max_pos.y - min_pos.y)
	
	var zoom = min(1.4, get_viewport_rect().size.x / new_size.x, get_viewport_rect().size.y / new_size.y)
	cam.zoom = cam.zoom.move_toward(Vector2(zoom, zoom), delta*0.45)

	
	# The host controls the timer and the rounds
	if multiplayer.is_server():
		if in_game:
			info.text = str(round(game_timer.time_left)) + "s left"
			loser = ""
			for player in players.get_children():
				if player.it:
					loser = PlayerManager.players[str(player.name).to_int()]["name"]
					break
		else:
			if loser != "":
				info.text = "Loser: " + loser + "\nNew round in" + str(round(game_timer.time_left)) + "s"
			else:info.text = "New round in" + str(round(game_timer.time_left)) + "s"
	

func create_player(Player_name, id, colour, it, pos):
	# Creates a player instance
	var current_player = PlayerManager.player.instantiate()
	current_player.player_number = Player_name
	current_player.name = str(id)
	current_player.color = colour
	current_player.it = it
	current_player.global_position = pos
	current_player.tag = true
	players.add_child(current_player)

@rpc("any_peer")
func end_game():
	pass

@rpc("any_peer")
func clear_infection():
	# Removes it
	for player in players.get_children():
		player.it = false

func new_infection(id):
	# Make a player it
	for player in players.get_children():
		if str(player.name) == str(id):
			player.it = true

@rpc("any_peer")
func infect_player(id):
	## Call to sync the new it
	# Happens at the start of a round and when it is passed on to another player
	new_infection(id)

func _on_timer_timeout():
	# End round if in round
	# Start round if in cooldown
	if in_game:
		in_game = false
		game_cooldown_timer.start(ROUND_COOLDOWN)
		if multiplayer.is_server():
			clear_infection()
			clear_infection.rpc()
	else:
		in_game = true
		game_timer.start(ROUND_LENGTH)
		
		if multiplayer.is_server():
			# Randomly assign it
			var new_it = str(players.get_child(PlayerManager.rng.randi_range(0, players.get_child_count()-1)).name).to_int()
			clear_infection()
			infect_player(new_it)
			infect_player.rpc(new_it)
