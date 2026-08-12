extends Node3D

const INIT_HEAD_DEG = 65.8

func _physics_process(delta: float) -> void:
	
	$Root/Skeleton3D/NeckBone.rotation_degrees.x = get_parent().get_node("Head").rotation_degrees.x + INIT_HEAD_DEG
		
	$Root/Skeleton3D/NeckBone.rotation_degrees.x = clamp(
		$Root/Skeleton3D/NeckBone.rotation_degrees.x, -60 + INIT_HEAD_DEG, 60 + INIT_HEAD_DEG)
	
	var interpolate = func(parameters : String, to, time):
		get_node("AnimationTree")[parameters] = lerp(
			get_node("AnimationTree")[parameters], to, time)
	
	#grab the velocity from a character node
	var horizontal_movement = Vector3(get_parent().velocity.x, 0, get_parent().velocity.z).length()
	var vertical_movement = get_parent().velocity.y
	
	if horizontal_movement > 0.0:
		interpolate.call("parameters/Blend2/blend_amount", 1.0, delta * 5)
		
	else:
		interpolate.call("parameters/Blend2/blend_amount", 0.0, delta * 5)
		#interpolate.call("parameters/speed/scale", 0.0, delta * 5)
		
	if vertical_movement > 0.0:
		interpolate.call("parameters/Blend2 2/blend_amount", 1.0, delta * 5)
	else:
		interpolate.call("parameters/Blend2 2/blend_amount", 0.0, delta * 5)
