extends Node3D

@onready var viewmodel = $SubViewportContainer/SubViewport/smg

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

func _physics_process(_delta):
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("fire"):
			viewmodel.get_node("AnimationPlayer").play("fire")
		if Input.is_action_just_pressed("reload"):
			viewmodel.get_node("AnimationPlayer").play("reload")
