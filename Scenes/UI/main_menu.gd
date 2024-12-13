extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var settings: bool = false
var Matchsettings: bool = false

func _ready() -> void:
	pass

func _on_play_pressed() -> void:
	GameManager.host_mode = true
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_join_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_match_settings_pressed() -> void:
	settings = false
	if Matchsettings:
		anim_player.play_backwards("Match_open")
		Matchsettings = false
	else:
		anim_player.play("Match_open")
		Matchsettings = true

func _on_settings_pressed() -> void:
	Matchsettings = false
	if settings:
		anim_player.play_backwards("Settings_open")
		settings = false
	else:
		anim_player.play("Settings_open")
		settings = true
