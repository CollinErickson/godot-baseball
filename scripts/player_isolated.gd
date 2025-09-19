extends Node3D

var player:Player

var this_is_root:bool = false
var is_active:bool = false

func _ready() -> void:
	
	if get_tree().root == get_parent():
		this_is_root = true
		printt('In player_isolated: THIS IS ROOT')
		#$Camera3D.position.y
		var team:Team = Team.new()
		team.create_random()
		player = team.roster[0]
		set_active(true)
		setup_player(player, team, true)
		set_animation('running')

func setup_player(player_:Player, team:Team, is_home_team:bool=true) -> void:
	player = player_
	
	$Char3D.set_color_from_team(player, team, is_home_team)
	#$Char3D.set_glove_visible(throws)

func set_animation(new_anim) -> void:
	$Char3D.start_animation(new_anim, false, player.throws=='R')

func set_active(tf:bool) -> void:
	is_active = tf
	if is_active:
		pass
	else:
		#$Char3D.st
		pass
