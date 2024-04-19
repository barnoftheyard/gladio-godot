extends RigidBody3D

const IS_PHYSBRUSH = true

var targets = []
var last_body = null

var metal_sounds = []

func _on_body_entered(body):			#get all bodies (that are kine or rigid) that are in area
	#make sure that the object we get isn't one that we got before last time
	if (body is CharacterBody3D or body is RigidBody3D or body is StaticBody3D or 
	body.has_method("IS_PHYSBRUSH") and last_body != body):
		targets.append(body)
		last_body = body
	
func _ready():
	#get all wav files in folder
	pass
		
func _physics_process(delta):
	if targets.size() > 0:
		for x in targets:
			pass
			#Global.play_rand($impact, metal_sounds)
		#reset target list
		targets = []
		last_body = null
		
#func bullet_hit(damage, _from, bullet_hit_pos, force_multiplier):			#handles how bullets push the prop
	#var direction_vect = global_transform.origin - bullet_hit_pos
	#direction_vect = direction_vect.normalized()
	#apply_impulse(bullet_hit_pos, direction_vect * (mass / (damage * force_multiplier)))
#
	##Global.play_rand($impact, metal_sounds)
