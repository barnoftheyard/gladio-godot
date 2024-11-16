extends Node3D

@export var sway = 3
@export var create_deformation = false
@onready var viewmodel = $SubViewportContainer/SubViewport/smg
@onready var initial_position = viewmodel.position

const ARM_ANIM_POSITION_OFFSET = Vector3(-0.234,-0.275, 1.267)
const ARM_ANIM_ROTATION_OFFSET = Vector3(-13.6, 11.1, 79.3)

var timer = 0
var mouse_accel = Vector3.ZERO

#dictionary of weapons
var weapons = {
	"smg": {"max_mag": 30, "max_ammo": 240, "mag": 30, "ammo": 30, "damage": 15,
	"rate": 0.1}
}

var current_weapon = "smg"
var current_weapon_mag = weapons[current_weapon]["mag"]
var current_weapon_ammo = weapons[current_weapon]["ammo"]

#function that recursives finds any meshes inside a scene and sets their layer mask
func set_all_meshes_layer_mask(node, value, boolean):
	for n in node.get_children():
		if n.get_child_count() > 0:
			set_all_meshes_layer_mask(n, value, boolean)
		if n is MeshInstance3D:
			n.set_layer_mask_value(value, boolean)
			
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_accel.x = -event.relative.x * 0.0075
		mouse_accel.y = -event.relative.y * 0.0075

# Called when the node enters the scene tree for the first time.
func _ready():
	#if not host remove viewmodels
	if !is_multiplayer_authority():
		$SubViewportContainer.queue_free()
	else:
		#turn off seeing layer 1 (the world geometry layer) and turn on layer 2 (the viewmodel layer)
		set_all_meshes_layer_mask(viewmodel, 1, false)
		set_all_meshes_layer_mask(viewmodel, 2, true)
		
		#set_all_meshes_layer_mask(viewmodel.get_node("arms"), 1, false)
		#set_all_meshes_layer_mask(viewmodel.get_node("arms"), 2, true)
		
	#connect the reload animation finishing to this script
	viewmodel.get_node("AnimationPlayer").connect("animation_finished", _on_animation_finished)

#creates the decals for bullet holes
func create_bullet_decal(object, decal_position, time):
	var decal = Decal.new()
	decal.size = Vector3(0.2, 0.2, 0.2)
	
	decal.texture_albedo = load("res://icon.svg")
	
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
		
		var thirdperson_gun = get_parent().get_parent().get_node_or_null("male/AnimationPlayer2")
		if thirdperson_gun != null:
			thirdperson_gun.play("shoot")
		
		$WeaponSound.play()
		timer = weapons[current_weapon]["rate"]
		
		if collision is RigidBody3D:
			#apply a force onto a physics object to make it get knocked back
			collision.apply_impulse(-$WeaponRay.get_collision_normal() * clamp(weapons[current_weapon
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
	if is_multiplayer_authority():
		
		if timer <= 0:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				if Input.is_action_pressed("fire"):
					shoot_weapon($WeaponRay.get_collider())
					
				if (Input.is_action_just_pressed("reload") and 
				!viewmodel.get_node("AnimationPlayer").is_playing()):
					reload_weapon()
		else:
			timer -= delta
			
		viewmodel.position = viewmodel.position.lerp(mouse_accel + initial_position, sway * delta)
		
		#rotational sway
		viewmodel.rotation.y = lerp_angle(viewmodel.rotation.y, mouse_accel.x, sway * delta)
		viewmodel.rotation.x = lerp_angle(viewmodel.rotation.x, mouse_accel.y, sway * delta)
		
		#breathing-esque effect on the weapon
		viewmodel.position.y += cos(delta * 2) * 0.0005
		
		var arms_bone = viewmodel.get_node("arms/Sketchfab_model/PSX_First_Person_Arms_fbx/Object_2/RootNode/arms_armature/Object_5/Skeleton3D/BoneAttachment3D")
		arms_bone.global_position = viewmodel.get_node("Armature/Bone").global_position
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
