extends Node3D

@export var sway = 3
@export var create_deformation = false

@onready var viewmodel = get_node("SubViewportContainer/SubViewport/" + current_weapon)
@onready var initial_position = viewmodel.position
@onready var immobile = get_parent().get_parent().immobile 

var timer = 0
var mouse_accel = Vector3.ZERO

#dictionary of weapons
var weapons = {
	"smg": {"max_mag": 30, "max_ammo": 240, "mag": 30, "ammo": 30, "damage": 15,
	"rate": 0.1, "initial_position": Vector3(0.25, -0.5, -1)},
	
	"pistol": {"max_mag": 12, "max_ammo": 144, "mag": 12, "ammo": 60, "damage": 25,
	"rate": 0.2, "initial_position": Vector3(0.235, -0.755, -0.712)},
	
	"saw": {"max_mag": 999, "max_ammo": 0, "mag": 999, "ammo": 0, "damage": 999,
	"rate": 1.0, "initial_position": Vector3(0, -0.658, -1.529)}
}

@export var current_weapon = "smg"
var current_weapon_index = 0
var current_weapon_mag = weapons[current_weapon]["mag"]
var current_weapon_ammo = weapons[current_weapon]["ammo"]

#function that recursively finds any meshes inside a scene and sets their layer mask
func set_all_meshes_layer_mask(node, value, boolean):
	for n in node.get_children():
		if n.get_child_count() > 0:
			set_all_meshes_layer_mask(n, value, boolean)
		if n is MeshInstance3D:
			n.set_layer_mask_value(value, boolean)
			
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and is_multiplayer_authority() and !immobile:
		mouse_accel.x = -event.relative.x * 0.0075
		mouse_accel.y = -event.relative.y * 0.0075
	
	#weapon switching logic
	if event is InputEventMouseButton and event.is_pressed() and is_multiplayer_authority() and !immobile:
		viewmodel.hide()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_weapon_index += 1
			current_weapon_index = clamp(current_weapon_index, 0, weapons.size()-1)
			
			current_weapon = weapons.keys()[current_weapon_index]
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_weapon_index -= 1
			current_weapon_index = clamp(current_weapon_index, 0, weapons.size()-1)
			
			current_weapon = weapons.keys()[current_weapon_index]
			
		#update our variables
		viewmodel = get_node("SubViewportContainer/SubViewport/" + current_weapon)
		viewmodel.show()
		#initial_position = viewmodel.position
		
		current_weapon_mag = weapons[current_weapon]["mag"]
		current_weapon_ammo = weapons[current_weapon]["ammo"]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#if not our player remove viewmodels
	if !is_multiplayer_authority():
		$SubViewportContainer.queue_free()
	else:
		for x in $SubViewportContainer/SubViewport.get_children():
			#skip WeaponViewmodel
			if x is not Camera3D:
				#turn off seeing layer 1 (the world geometry layer) and turn on layer 2 (the viewmodel layer)
				set_all_meshes_layer_mask(x, 1, false)
				set_all_meshes_layer_mask(x, 2, true)
				#connect the animation players of the viewmodel models with animation finished so that
				#reloading works
				x.get_node("AnimationPlayer").connect("animation_finished", _on_animation_finished)
				
		
		#set_all_meshes_layer_mask(viewmodel.get_node("arms"), 1, false)
		#set_all_meshes_layer_mask(viewmodel.get_node("arms"), 2, true)
		

#creates the decals for bullet holes
func create_bullet_decal(object, decal_position, time):
	var decal = Decal.new()
	decal.size = Vector3(0.2, 0.2, 0.2)
	
	decal.texture_albedo = load("res://textures/editor/bullseye.png")
	
	object.add_child(decal)
	decal.global_position = decal_position
	
	await get_tree().create_timer(time).timeout
	decal.queue_free()
		
func shoot_weapon(collision):
	
	if weapons[current_weapon]["mag"] > 0:
		weapons[current_weapon]["mag"] -= 1
		
		#stop the animation first so we can play it again
		viewmodel.get_node("AnimationPlayer").stop()
		viewmodel.get_node("AnimationPlayer").play("fire")
		
		if current_weapon == "saw":
			$SawSound.play()
			$FireParticle.emitting = true
			get_parent().get_parent().velocity += global_transform.basis.z * 10
		else:
			$WeaponSound.play()
		
		timer = weapons[current_weapon]["rate"]
		
		if collision is RigidBody3D:
			#apply a force onto a physics object to make it get knocked back
			collision.apply_impulse(-global_transform.basis.z * clamp(weapons[current_weapon
			]["damage"] / collision.mass, 1, 10), $WeaponRay.get_collision_point())	#apply push force
			
			#create a bullet hole decal
			create_bullet_decal(collision, $WeaponRay.get_collision_point(), 5)
			
			if collision.find_child("CSGCombiner3D") != null:
				#if collision.get_node("CSGCombiner3D").find_child("Timer") == null:
					#var _timer = Timer.new()
					#_timer.wait_time = 0.2
					#_timer.one_shot = true
					#collision.get_node("CSGCombiner3D").add_child(_timer)
				
				#create some CSG deformation
				if collision.get_node("CSGCombiner3D").get_child_count() < 20 and create_deformation:
						
					
					var sphere = CSGSphere3D.new()
					sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
					sphere.radius = 0.25
					sphere.radial_segments = 4
					sphere.rings = 4
					sphere.snap = 0.01
					
					collision.get_node("CSGCombiner3D").add_child(sphere)
					sphere.global_position = $WeaponRay.get_collision_point()
					
					#collision.get_node("CSGCombiner3D").get_node("Timer").start()
					
		elif collision is StaticBody3D or collision is CSGShape3D:
			create_bullet_decal(collision, $WeaponRay.get_collision_point(), 5)
			
		elif collision is CharacterBody3D:
			#print(collision.name)
			collision.damage.rpc(weapons[current_weapon]["damage"], get_multiplayer_authority())
			
	#if we run out of bullets in our mag
	elif weapons[current_weapon]["mag"] <= 0:
		reload_weapon()
	
	#update our variables
	current_weapon_mag = weapons[current_weapon]["mag"]
	current_weapon_ammo = weapons[current_weapon]["ammo"]
	
func reload_weapon():	
	#if our weapons magazine is not at full capacity and we have reserve ammo, play
	#the reload animation
	if (weapons[current_weapon]["mag"] < weapons[current_weapon]["max_mag"] 
	and weapons[current_weapon]["ammo"] > 0):
		viewmodel.get_node("AnimationPlayer").play("reload")
		

func _physics_process(delta):
	immobile = get_parent().get_parent().immobile
	
	if is_multiplayer_authority() and !immobile:
		
		if timer <= 0:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				if Input.is_action_pressed("fire"):
					shoot_weapon($WeaponRay.get_collider())
					
				if (Input.is_action_just_pressed("reload") and 
				not viewmodel.get_node("AnimationPlayer").is_playing()):
					reload_weapon()
		else:
			timer -= delta
		
		#transitional sway
		viewmodel.position = viewmodel.position.lerp(mouse_accel + weapons[current_weapon]["initial_position"], sway * delta)
		
		#rotational sway
		viewmodel.rotation.y = lerp_angle(viewmodel.rotation.y, mouse_accel.x, sway * delta)
		viewmodel.rotation.x = lerp_angle(viewmodel.rotation.x, mouse_accel.y, sway * delta)
		
		#breathing-esque effect on the weapon
		viewmodel.position.y += cos(delta * 2) * 0.0005
		
		#var arms_bone = viewmodel.get_node("arms/Sketchfab_model/PSX_First_Person_Arms_fbx/Object_2/RootNode/arms_armature/Object_5/Skeleton3D/BoneAttachment3D")
		#arms_bone.global_position = viewmodel.get_node("Armature/Bone").global_position
		#arms_bone.global_rotation = viewmodel.get_node("Armature/Bone").rotation - ARM_ANIM_ROTATION_OFFSET
		

#this function actually reloads our gun
func _on_animation_finished(anim_name):
	if anim_name == "reload":
		#add a full magazine minus the number of bullets from our current mag into our current magazine
		var remaining_in_mag = weapons[current_weapon]["max_mag"] - weapons[current_weapon]["mag"]
		
		weapons[current_weapon]["mag"] += remaining_in_mag
		#take them away from our ammo cache
		weapons[current_weapon]["ammo"] -= remaining_in_mag
		
		#if we somehow overflow our ammo, add the negative value back to our magazine to make
		#the value correct
		if weapons[current_weapon]["ammo"] < 0:
			weapons[current_weapon]["mag"] += weapons[current_weapon]["ammo"]
			#set the ammo count to zero
			weapons[current_weapon]["ammo"] = 0
		
		#update our variables
		current_weapon_mag = weapons[current_weapon]["mag"]
		current_weapon_ammo = weapons[current_weapon]["ammo"]
