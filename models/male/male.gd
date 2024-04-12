extends Node3D

func character_animation(moving, is_on_floor, state, delta):
	
	$Armature/Skeleton3D/SpineOverride.rotation_degrees.x = clamp(
		$Armature/Skeleton3D/SpineOverride.rotation_degrees.x, -60, 60)
	
	var interpolate = func(parameters : String, to, time):
		get_node("AnimationTree")[parameters] = lerp(
			get_node("AnimationTree")[parameters], to, time)
	
	if moving and is_on_floor:
		interpolate.call("parameters/speed/scale", 1.0, delta * 5)
		interpolate.call("parameters/Blend3/blend_amount",
		float(moving.length() if state == "sprinting" else moving.length() / 2), 
		delta * 5)
		
		if moving.x != 0:
			interpolate.call("parameters/strafe/add_amount",
			 float(clamp(moving.x, 0.0, 0.5)), delta * 5)
			
			if moving.x < 0:
				interpolate.call("parameters/strafe_dir/blend_amount", 2.0, delta * 5)
			else:
				interpolate.call("parameters/strafe_dir/blend_amount", 0.0, delta * 5)
		else:
			interpolate.call("parameters/strafe/add_amount", 0.0, delta * 5)
			interpolate.call("parameters/strafe_dir/blend_amount", 0.0, delta * 5)
		
	else:
		interpolate.call("parameters/Blend3/blend_amount", -1.0, delta * 5)
		interpolate.call("parameters/speed/scale", 0.0, delta * 5)
