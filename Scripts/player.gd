extends CharacterBody3D

@export var player_id := 1
@export var health = 1
@export var _hitscan: bool

@onready var camera: Camera3D = $Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = $Camera3D/MuzzleFlash
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var bodyInvert: MeshInstance3D = $Player_Body2
@onready var bowViewmodel: Node3D = $Camera3D/bow_viewmodel
@onready var bow: Node3D = $Camera3D/bow
@onready var hud: Control = $CanvasLayer/HUD
@onready var pause: Control = $CanvasLayer/Pause

#bullet marker and trail component
@onready var marker: Marker3D = $Camera3D/Marker3D
@onready var bullet_trail_comp: Node3D = $BulletTrailComp
@onready var bow_audio: AudioStreamPlayer3D = $Camera3D/Bow_audio

#skill1 marker and component
@onready var skill1: Control = $CanvasLayer/HUD/Skill
@onready var skill1_marker: Marker3D = $Camera3D/Skill1Marker
@onready var skill1_comp: Node3D = $Skill1Comp
@onready var skill_audio: AudioStreamPlayer3D = $Camera3D/Skill1Marker/Skill_audio

@onready var killFeed: Control = $CanvasLayer/KillFeed
@onready var foot_audio: AudioStreamPlayer3D = $Foot_audio

var sens:float = GameManager.sensitivity
var owner_id = 1
var self_name:String
var shooting:bool = false
var SPEED = 5.0
var JUMP_VELOCITY = 5

func _enter_tree() -> void:
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)

func _ready() -> void:
	if owner_id == multiplayer.get_unique_id():
		camera.make_current()
		bowViewmodel.visible = true
		bow.visible = false
		bodyInvert.visible = false
		hud.visible = true
		SPEED = GameManager.player_Speed
		JUMP_VELOCITY = GameManager.player_jump
		_hitscan = GameManager.hitscan
		self_name = Lobby.players[owner_id].name
	else:
		camera.current = false
		
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if owner_id != multiplayer.get_unique_id(): 
		return
	if event is InputEventMouseMotion and health >= 1:
		rotate_y(-event.relative.x * sens)
		camera.rotate_x(-event.relative.y * sens)
		camera.rotation.x = clamp(camera.rotation.x,-PI/2, PI/2)

func _input(event: InputEvent) -> void:
	if owner_id != multiplayer.get_unique_id(): 
		return
	if event.is_action_pressed("Skill1") and not GameManager.paused:
		if skill1.used_skill():
			skill_audio.play()
			play_skill1_effects.rpc()
	elif event.is_action_pressed("shoot") and anim_player.current_animation != "shoot" and not shooting and not GameManager.paused:
		play_shoot_effects.rpc()
		bow_audio.play()
		if raycast.is_colliding() and _hitscan:
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
			LineDrawer.DrawLine(marker.global_position,hit_player.global_position,Color(1,0,0),0.5)
		shooting = true
	elif event.is_action_pressed("quit") and not GameManager.paused:
		pause.pause(owner_id)
	elif event.is_action_pressed("test"):
		pass

func _physics_process(delta: float) -> void:
	if owner_id != multiplayer.get_unique_id(): 
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and health >= 1 and not GameManager.paused:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and health >= 1 and not GameManager.paused:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	elif health >= 1 and not GameManager.paused:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if anim_player.current_animation == "shoot":
		pass
	elif anim_player.current_animation == "death":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor() and not GameManager.paused:
		anim_player.play("move")
	else:
		anim_player.play("idle")
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	if not _hitscan:
		bullet_trail_comp.bulletFire(camera,marker,owner_id)
	
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("call_local")
func play_skill1_effects():
	skill1_comp.skill1_throw(camera,skill1_marker)

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 1
		var sender_id = multiplayer.get_remote_sender_id()
		var killer = Lobby.players[sender_id].name
		if _hitscan:
			killFeed.send_message(killer,Lobby.players[owner_id].name)
		respawn_self()
		#anim_player.play("death")
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		shooting = false
		anim_player.play("idle")
	elif  anim_name == "death":
		health = 1
		respawn_self.rpc()

@rpc("any_peer")
func respawn_self():
	var spawnPOS = GameManager.spawn_point_rng()
	if spawnPOS.SpawnActive:
		position = spawnPOS.SpawnPOS
	else:
		spawnPOS = GameManager.spawn_point_rng()
