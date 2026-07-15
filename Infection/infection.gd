extends Node2D

@onready var players = $Players
@onready var normal_spawn = $Spawns/NSpawn
@onready var infected_spawn = $Spawns/ISpawn
@onready var cam = $PlayerTracker
@onready var info = $CanvasLayer/Label
@onready var game_timer = $Timer
@onready var game_cooldown_timer = $Timer
@onready var syncer = $MultiplayerSynchronizer

var in_game = false
var survivor_count = 0
const ROUND_LENGTH = 90
const ROUND_COOLDOWN = 15

# Called when the node enters the scene tree for the first time.
func _ready():
	PlayerManager.terminated_server.connect(server_terminated)
	multiplayer.peer_connected.connect(_on_player_connected)
	for p in PlayerManager.players:
		create_player(PlayerManager.players[p]["name"], p, PlayerManager.players[p]["colour"], false, normal_spawn.global_position)
	game_timer.start(ROUND_COOLDOWN)
	in_game = false
	syncer.set_multiplayer_authority(1)

func _on_player_connected(id):
	PlayerManager.reject.rpc_id(id)
	multiplayer.multiplayer_peer.disconnect_peer(id)

func server_terminated():
	var lobby = load("res://Lobby/lobby.tscn")
	get_tree().change_scene_to_packed(lobby)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	
	if multiplayer.is_server():
		if in_game:
			survivor_count = 0
			for player in players.get_children():
				if !player.it:
					survivor_count += 1
			if survivor_count == 0:
				_on_timer_timeout()
			info.text = "Survivors: " + str(survivor_count) + "\n" + str(int(round(game_timer.time_left))) + "s left"
		else:
			if survivor_count > 0:
				info.text = "Survivors: " + str(survivor_count) + "\n"
			else: info.text = ""
			info.text += "New round in " + str(int(round(game_timer.time_left))) + "s"

	if PlayerManager.player_count() != players.get_child_count():
		for player in players.get_children():
			if !PlayerManager.players.has(str(player.name).to_int()):
				player.queue_free()
		for player in PlayerManager.players:
			var loaded = false
			for loaded_player in players.get_children():
				if str(loaded_player.name).to_int() == player:
					loaded = true
			if !loaded:
				create_player(PlayerManager.players[player]["name"],player,PlayerManager.players[player]["colour"], true, infected_spawn.global_position)

func create_player(Player_name, id, colour, it, pos):
	var current_player = PlayerManager.player.instantiate()
	current_player.player_number = Player_name
	current_player.name = str(id)
	current_player.color = colour
	current_player.it = it
	current_player.global_position = pos
	current_player.infection = true
	players.add_child(current_player)

@rpc("any_peer")
func end_game():
	pass

@rpc("any_peer")
func clear_infection():
	for player in players.get_children():
		player.it = false

func new_infection(id):
	for player in players.get_children():
		if str(player.name) == str(id):
			player.it = true

@rpc("any_peer")
func infect_player(id):
	new_infection(id)

func _on_timer_timeout():
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
			var new_it = str(players.get_child(PlayerManager.rng.randi_range(0, players.get_child_count()-1)).name).to_int()
			clear_infection()
			infect_player(new_it)
