class_name Skill1Comp extends Node

@export var _skill_prefab: PackedScene

@onready var skill_marker: Marker3D = $"../Camera3D/Skill1Marker"
@onready var skill_ui: Control = $"../CanvasLayer/HUD/Skill"

var Player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player = owner

@rpc("call_local")
func Use_skill():
	if skill_ui.used_skill():
		Player.audio_comp.Play_Throw_Skill()
		skill_throw()

func skill_throw() ->void:
	var skill = _skill_prefab.instantiate()
	var container = get_tree().get_first_node_in_group("SkillContainer")
	container.add_child(skill)
	skill.global_position = skill_marker.global_position
	
	var force = -10
	var updirection = 3.5
	var playerRotation = Player.camera.global_transform.basis.z.normalized()
	
	skill.apply_central_impulse(playerRotation * force + Vector3(0,updirection,0))
