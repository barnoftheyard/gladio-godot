extends Node3D

@onready var viewmodel = $SubViewportContainer/SubViewport/smg
var timer = 0

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

# Called when the node enters the scene tree for the first time.
func _ready():
	#if not host remove viewmodels
	if !is_multiplayer_authority():
		$SubViewportContainer.queue_free()
	else:
		#turn off seeing layer 1 (the world geometry layer) and turn on layer 2 (the viewmodel layer)
		set_all_meshes_layer_mask(viewmodel, 1, false)
		set_all_meshes_layer_mask(viewmodel, 2, true)
		
	#connect the reload animation finishing to this script
	viewmodel.get_node("AnimationPlayer").connect("animation_finished", _on_animation_finished)
		
func shoot_weapon(collision):
	if weapons[current_weapon]["mag"] > 0:
		weapons[current_weapon]["mag"] -= 1
		
		#stop the animation first so we can play it again
		viewmodel.get_node("AnimationPlayer").stop()
		viewmodel.get_node("AnimationPlayer").play("fire")
		
		$WeaponSound.play()
		timer = weapons[current_weapon]["rate"]
		
		if collision is RigidBody3D:
			#apply a force onto a physics object to make it get knocked back
			collision.apply_impulse(-$WeaponRay.get_collision_normal() * clamp(weapons[current_weapon
			]["damage"] / collision.mass, 1, 10), $WeaponRay.get_collision_point())	#apply push force
		elif collision != null:
			print(collision.name)
			
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
			if Input.is_action_pressed("fire"):
				shoot_weapon($WeaponRay.get_collider())
				
			if (Input.is_action_just_pressed("reload") and 
			!viewmodel.get_node("AnimationPlayer").is_playing()):
				reload_weapon()
		else:
			timer -= delta

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
