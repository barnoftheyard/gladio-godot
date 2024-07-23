extends Control


@export_category("Reticle")
@export_group("Nodes")
@export var reticle_lines : Array[Line2D]
@export var character : CharacterBody3D

@export_group("Animate")
@export var animated_reticle : bool = true
@export var reticle_speed : float = 1
@export var reticle_spread : float = 4.0
@export var reticle_max : float = 25.0 #max velocity of character that will affect the spread

@export_group("Dot Settings")
@export var dot_size : int = 1
@export var dot_color : Color = Color.WHITE

@export_group("Line Settings")
@export var line_color : Color = Color.WHITE
@export var line_width : int = 2
@export var line_length : int = 10
@export var line_distance : int = 5
@export_enum("None", "Round") var cap_mode : int = 0

@onready var health = 0

func _physics_process(_delta):
	$dot.position = self.size / 2
	$SubViewportContainer/SubViewport/Compass.rotation.y = character.get_node("Head").rotation.y
	
	if visible: # If the reticle is disabled (not visible), don't bother updating it
		update_reticle_settings()
		if animated_reticle:
			animate_reticle_lines()


func animate_reticle_lines():
	var vel = character.get_real_velocity()
	var origin = Vector3(0,0,0)
	var pos = $dot.position
	var speed = clamp(origin.distance_to(vel), 0, reticle_max)
	var circle_speed = clamp(origin.distance_to(vel), 0.5, reticle_max / 25)
	
	reticle_lines[0].position = lerp(reticle_lines[0].position, pos + Vector2(0, -speed * reticle_spread), reticle_speed)
	reticle_lines[1].position = lerp(reticle_lines[1].position, pos + Vector2(-speed * reticle_spread, 0), reticle_speed)
	reticle_lines[2].position = lerp(reticle_lines[2].position, pos + Vector2(speed * reticle_spread, 0), reticle_speed)
	reticle_lines[3].position = lerp(reticle_lines[3].position, pos + Vector2(0, speed * reticle_spread), reticle_speed)
	
	$SubViewportContainer/SubViewport/CSGCombiner3D.scale = lerp($SubViewportContainer/SubViewport/CSGCombiner3D.scale, 
		Vector3(circle_speed, circle_speed, 1), reticle_speed / 10)


func update_reticle_settings():
	# Dot
	$dot.scale.x = dot_size
	$dot.scale.y = dot_size
	$dot.color = dot_color
	
	
	if health != character.health:
		$SubViewportContainer/SubViewport/CSGCombiner3D2/CSGBox3D.position.x = remap(character.health, 0, 100, 0.28, 0.72)
		health = character.health
		
	$HSplitContainer/mag.text = str(character.get_node("Head/Weapon").current_weapon_mag) + " "
	$HSplitContainer/ammo.text = " " + str(character.get_node("Head/Weapon").current_weapon_ammo)
	
	# Lines
	for line in reticle_lines:
		line.default_color = line_color
		line.width = line_width
		if cap_mode == 0:
			line.begin_cap_mode = Line2D.LINE_CAP_NONE
			line.end_cap_mode = Line2D.LINE_CAP_NONE
		elif cap_mode == 1:
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Please someone find a better way to do this
	reticle_lines[0].points[0].y = -line_distance
	reticle_lines[0].points[1].y = -line_length - line_distance
	reticle_lines[1].points[0].x = -line_distance
	reticle_lines[1].points[1].x = -line_length - line_distance
	reticle_lines[2].points[0].x = line_distance
	reticle_lines[2].points[1].x = line_length + line_distance
	reticle_lines[3].points[0].y = line_distance
	reticle_lines[3].points[1].y = line_length + line_distance
