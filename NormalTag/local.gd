extends Node2D

@onready var player_manager = $player_manager
@onready var map1 = $Map1
@onready var map2 = $Map2
@onready var map3 = $Map3
@onready var map4 = $Map4
@onready var cam = $Player_Tracker
@onready var timer_label = $CanvasLayer/Label
@onready var game_timer = $CanvasLayer/GameTimer

@onready var start_box_ice = $StartBoxIce
@onready var ice_label = $StartBoxIce/Label4
@onready var start_box_soil = $StartBoxEarth
@onready var soil_label = $StartBoxEarth/Label4
@onready var start_box_lava = $StartBoxLava
@onready var lava_label = $StartBoxLava/Label4
@onready var start_box_sugar = $StartBoxSugar
@onready var sugar_label = $StartBoxSugar/Label4

var total_votes = 0
var ice_votes = 0
var lava_votes = 0
var soil_votes = 0
var sugar_votes = 0

var ice_text = ""
var lava_text = ""
var soil_text = ""
var sugar_text = ""

var players = []

var in_game = false
var map = map1

func choose_map():
	if soil_votes > max(ice_votes, lava_votes, sugar_votes):
		map = map1
	elif lava_votes > max(ice_votes, soil_votes, sugar_votes):
		map = map2
	elif sugar_votes > max(soil_votes, lava_votes, ice_votes):
		map = map3
	elif ice_votes > max(soil_votes, lava_votes, sugar_votes):
		map = map4
	else: return # votes tied


func begin_game():
	
	player_manager.begin_game()
	
	for player in players:
		player.global_position = map.global_position
	game_timer.start(2*60)
	in_game = true

func _process(delta):
	
	$Map1/StaticBody2D/CollisionShape2D.disabled = not $"Map1/Pressure Plate".pressed
	$Map1/StaticBody2D.visible = $"Map1/Pressure Plate".pressed
	
	
	if ice_text == "":
		ice_text = ice_label.text
		lava_text = lava_label.text
		soil_text = soil_label.text
		sugar_text = sugar_label.text
		
	timer_label.visible = in_game
	cam.enabled = in_game
	$LobbyCamera.enabled = !in_game
	timer_label.text = str(int(round(game_timer.time_left))) + "s Remaining!"
	
	players = []
	for i in range(player_manager.get_child_count() -1):
		players.append(player_manager.get_child(i+1))
		
	if not in_game and total_votes == len(players) and len(players) > 0:
		for player in players:
			player.global_position = $GameModePicker.global_position
		choose_map()
		if map != null: 
			begin_game()
			

	if in_game:
		track_players(delta)
		
	if ice_votes != total_votes:
		ice_label.text = ice_text + "\n" + str(ice_votes) + "/" + str(max(lava_votes, soil_votes, sugar_votes)+1)
	else:
		ice_label.text = ice_text + "\n" + str(ice_votes) + "/" + str(len(players))
	if lava_votes != total_votes:
		lava_label.text = lava_text + "\n" + str(lava_votes) + "/" + str(max(ice_votes, soil_votes, sugar_votes)+1)
	else:
		lava_label.text = lava_text + "\n" + str(lava_votes) + "/" + str(len(players))
	if soil_votes != total_votes:
		soil_label.text = soil_text + "\n" + str(soil_votes) + "/" + str(max(lava_votes, ice_votes, sugar_votes)+1)
	else:
		soil_label.text = soil_text + "\n" + str(soil_votes) + "/" + str(len(players))
	if sugar_votes != total_votes:
		sugar_label.text = sugar_text + "\n" + str(sugar_votes) + "/" + str(max(lava_votes, soil_votes, ice_votes)+1)
	else:
		sugar_label.text = sugar_text + "\n" + str(sugar_votes) + "/" + str(len(players))


func _on_start_box_body_entered(body):
	if body.is_in_group("Player"):
		total_votes += 1

func _on_start_box_body_exited(body):
	if body.is_in_group("Player"):
		total_votes -= 1

func track_players(delta):
	var num_of_players = len(players)
	if num_of_players == 0:
		return
	

	var min_pos = Vector2(cam.global_position.x,cam.global_position.y)
	var max_pos = Vector2(cam.global_position.x,cam.global_position.y)
	
	for p in players:
		if p.global_position.x < min_pos.x: min_pos.x = p.global_position.x
		if p.global_position.x > max_pos.x: max_pos.x = p.global_position.x
		if p.global_position.y < min_pos.y: min_pos.y = p.global_position.y
		if p.global_position.y > max_pos.y: max_pos.y = p.global_position.y
	
	min_pos += Vector2(-100, -100)
	max_pos += Vector2( 100,  100)
	
	cam.global_position.x = (min_pos.x + max_pos.x) / 2
	cam.global_position.y = (min_pos.y + max_pos.y) / 2
	
	var new_size = Vector2(max_pos.x - min_pos.x, max_pos.y - min_pos.y)
	
	var zoom = min(1.4, get_viewport_rect().size.x / new_size.x, get_viewport_rect().size.y / new_size.y)
	cam.zoom = cam.zoom.move_toward(Vector2(zoom, zoom), delta*0.45)


func _on_game_timer_timeout():
	in_game = false
	for player in players:
		player.global_position = player_manager.global_position
		if player.it:
			$Loser.text = player.player_number + " lost the last round\n:("
	player_manager.enabled = true


func _on_start_box_earth_body_entered(body):
	if body.is_in_group("Player"):
		soil_votes += 1

func _on_start_box_ice_body_entered(body):
	if body.is_in_group("Player"):
		ice_votes += 1

func _on_start_box_lava_body_entered(body):
	if body.is_in_group("Player"):
		lava_votes += 1

func _on_start_box_sugar_body_entered(body):
	if body.is_in_group("Player"):
		sugar_votes += 1

func _on_start_box_earth_body_exited(body):
	if body.is_in_group("Player"):
		soil_votes -= 1

func _on_start_box_ice_body_exited(body):
	if body.is_in_group("Player"):
		ice_votes -= 1

func _on_start_box_lava_body_exited(body):
	if body.is_in_group("Player"):
		lava_votes -= 1

func _on_start_box_sugar_body_exited(body):
	if body.is_in_group("Player"):
		sugar_votes -= 1


func _on_tag_body_entered(_body):
	for player in players:
		player.state = player.STATE.TAG
	begin_game()

func _on_infection_body_entered(_body):
	for player in players:
		player.state = player.STATE.INFECTION
	begin_game()
