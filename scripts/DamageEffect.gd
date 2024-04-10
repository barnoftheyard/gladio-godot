#goes on a ColorRect node that is the child of a CanvasLayer node
#be sure to set the bottom and right anchor to 1 so it covers the whole scene
extends ColorRect

@export var grain_bounce = 20
@export var frame_switch_time = 0.01 #how often to randomize the film grain
var cur_time = 0

func _process(delta):
	cur_time += delta
	if cur_time > frame_switch_time:
		cur_time = 0
		material.set_shader_parameter("randx", randf() * grain_bounce)
		material.set_shader_parameter("randy", randf() * grain_bounce)
