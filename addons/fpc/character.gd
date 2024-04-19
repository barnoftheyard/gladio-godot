extends CharacterBody3D

# TODO: Add descriptions for each value

@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1
@export var controller_sensitivity: float = 3.0
@export var immobile : bool = false
@export_file var default_reticle

@export var initial_facing_direction : Vector3 = Vector3.ZERO

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var CHARATER_MODEL : Node3D
@export var COLLISION_MESH : CollisionShape3D
@export var RETICLE : Control

@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "jump"
@export var LEFT : String = "left"
@export var RIGHT : String = "right"
@export var FORWARD : String = "forward"
@export var BACKWARD : String = "backward"
@export var PAUSE : String = "escape"
@export var CROUCH : String = "crouch"
@export var SPRINT : String = "sprint"

# Uncomment if you want full controller support
#@export var LOOK_LEFT : String
#@export var LOOK_RIGHT : String
#@export var LOOK_UP : String
#@export var LOOK_DOWN : String

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
@export var jump_animation : bool = true
@export var health : int = 100

# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	RETICLE.character = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set the camera rotation to whatever initial_facing_direction is
	if initial_facing_direction:
		HEAD.set_rotation_degrees(initial_facing_direction) # I don't want to be calling this function if the vector is zero
	
	# Reset the camera position
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	
	speed = base_speed
	
	#ignore our player collision
	$Head/Weapon/WeaponRay.add_exception(self)
	
	#if we're not host remove the debug screen
	if is_multiplayer_authority():
		$Head/Camera.current = is_multiplayer_authority()
		
		$male.hide()
		
	else:
		$UserInterface.queue_free()

func _physics_process(delta):
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())
	
	if is_multiplayer_authority():
		update_ui()
	
	# Gravity
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # If the gravity changes during your game, uncomment this code
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	
	if !immobile and is_multiplayer_authority():
		input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
		
	handle_movement(delta, input_dir)
	
	low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	handle_state(input_dir)
	if dynamic_fov:
		update_camera_fov()
	
	if view_bobbing and is_multiplayer_authority():
		headbob_animation(input_dir)
		#translates the camera view bobbing to the Viewmodel transform
		$Head/Weapon/SubViewportContainer/SubViewport/WeaponViewmodel.transform = $Head/Camera.transform
	
	#code for the character animation
	#match player model rotation and also rotate
	$male.rotation_degrees.y = HEAD.rotation_degrees.y + 180
	$male.character_animation(input_dir, is_on_floor(), state, delta)
	$male/Armature/GeneralSkeleton/SpineOverride.rotation_degrees.x = -HEAD.rotation_degrees.x
	
	#do the footstep sounds
	footsteps(input_dir)
	
	#pushes physics objects
	for index in get_slide_collision_count():				#player collision detection
		var collision = get_slide_collision(index)	
		#this pushes physics objects
		if collision.get_collider() is RigidBody3D:
			collision.get_collider().apply_central_impulse(-collision.get_normal() * 
			collision.get_collider().mass)	#apply push force
	
	#jump animation handling
	if jump_animation:
		if !was_on_floor and is_on_floor(): # Just landed
			match randi() % 2:
				0:
					JUMP_ANIMATION.play("land_left")
				1:
					JUMP_ANIMATION.play("land_right")
		
		was_on_floor = is_on_floor() # This must always be at the end of physics_process


func handle_jumping():
	if jumping_enabled and is_multiplayer_authority():
		if continuous_jumping:
			if Input.is_action_pressed(JUMP) and is_on_floor() and !low_ceiling:
				if jump_animation:
					JUMP_ANIMATION.play("jump")
				velocity.y += jump_velocity
		else:
			if Input.is_action_just_pressed(JUMP) and is_on_floor() and !low_ceiling:
				if jump_animation:
					JUMP_ANIMATION.play("jump")
				velocity.y += jump_velocity


func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	move_and_slide()
	
	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed


func handle_state(moving):
	if sprint_enabled and is_multiplayer_authority():
		if sprint_mode == 0:
			if Input.is_action_pressed(SPRINT) and state != "crouching":
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				# If the player is holding sprint before moving, handle that cenerio
				if Input.is_action_pressed(SPRINT) and state == "normal":
					enter_sprint_state()
				if Input.is_action_just_pressed(SPRINT):
					match state:
						"normal":
							enter_sprint_state()
						"sprinting":
							enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
	
	if crouch_enabled and is_multiplayer_authority():
		if crouch_mode == 0:
			if Input.is_action_pressed(CROUCH) and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(CROUCH):
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()


# Any enter state function should only be called once when you want to enter that state, not every frame.

func enter_normal_state():
	#print("entering normal state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	#print("entering crouch state")
	var prev_state = state
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed


func update_camera_fov():
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)


func headbob_animation(moving):
	if moving and is_on_floor():
		var use_headbob_animation : String
		match state:
			"normal","crouching":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"
		
		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true
		
		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2)) # Randomize the initial headbob direction
			# Let me explain that piece of code because it looks like it does the opposite of what it actually does.
			# The headbob animation has two starting positions. One is at 0 and the other is at 1.
			# randi() % 2 returns either 0 or 1, and so the animation randomly starts at one of the starting positions.
			# This code is extremely performant but it makes no sense.
		
	else:
		HEADBOB_ANIMATION.play("RESET", 0.25)
		HEADBOB_ANIMATION.speed_scale = 1

func _process(delta):
	
	if Input.is_action_just_pressed(PAUSE) and is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#clamp camera rotation to 90 degrees
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	#controller support
	if is_multiplayer_authority():
		var controller_view_rotation = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		HEAD.rotation_degrees.y -= controller_view_rotation.x * controller_sensitivity
		HEAD.rotation_degrees.x -= controller_view_rotation.y * controller_sensitivity

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_multiplayer_authority():
		HEAD.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		HEAD.rotation_degrees.x -= event.relative.y * mouse_sensitivity

func footsteps(moving):
	if moving and is_on_floor() and $Footsteps/FootstepsTimer.is_stopped():
		$Footsteps/FootstepsTimer.start()
	#function has to the only floor variant to prevent bug
	elif !moving or !is_on_floor_only():
		$Footsteps/FootstepsTimer.stop()
		
func damage(amount):
	health -= amount
	
func update_ui():
	$UserInterface/DebugPanel.add_property("SPEED", str(snappedf(current_speed * 3, 0.001)) + " KPH")
	#$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
	#var cv : Vector3 = get_real_velocity()
	#var vd : Array[float] = [
		#snappedf(cv.x, 0.001),
		#snappedf(cv.y, 0.001),
		#snappedf(cv.z, 0.001)
	#]
	#var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	#$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)
	#
	#$UserInterface/DebugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	#var status : String = state
	#if !is_on_floor():
		#status += " in the air"
	$UserInterface/DebugPanel.add_property("STATE", state.to_upper())
	$UserInterface/DebugPanel.add_property("INTEGRITY", health)
	$UserInterface/DebugPanel.add_property("MAG", $Head/Weapon.current_weapon_mag)
	$UserInterface/DebugPanel.add_property("AMMO", $Head/Weapon.current_weapon_ammo)

func _on_footsteps_timer_timeout():
	#adjust the timing of the steps to our current player speed
	$Footsteps/FootstepsTimer.wait_time = (2 / current_speed)
	#get all sounds and play the sounds randomly
	var sounds = $Footsteps/FootstepsSounds.get_children()
	sounds[randi() % sounds.size()].play()
