extends Node
class_name MultiplayerLobby

@export var level_scene: PackedScene
@onready var level_container: Node = $Level
@onready var ip_line_edit: LineEdit = $Multiplayer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/IPLineEdit
@onready var lobby_ui: CanvasLayer = $Multiplayer
@onready var background_container: Control = $Background_container

func _ready() -> void:
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	if GameManager.host_mode:
		_host()
	
func _host() -> void:
	background_container.queue_free()
	Lobby.create_game()
	hide_menu.rpc()
	change_level(level_scene)

func _on_connect_pressed() -> void:
	Lobby.join_game(ip_line_edit.text)
	background_container.queue_free()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Main Menu.tscn")


func change_level(scene):
	for c in level_container.get_children():
		level_container.remove_child(c)
		c.queue_free()
	level_container.add_child(scene.instantiate())

func _on_connection_failed():
	$Multiplayer/ErrorPrompt.visible = true

func _on_connected_to_server():
	hide_menu.rpc()
	change_level(level_scene)
	
func _on_player_connected(id):
	Lobby._update_globals.rpc_id(id,GameManager.skill_Cooldown,GameManager.skill1_radius,GameManager.player_Speed, GameManager.player_jump,GameManager.hitscan)

func _on_player_disconnected(id):
	Lobby._on_player_disconnected(id)
	
func _on_server_disconnected():
	Lobby._on_server_disconnected()

@rpc("any_peer", "call_local", "reliable")
func hide_menu():
	lobby_ui.hide()
