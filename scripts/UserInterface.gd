extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ColorRect/VSplitContainer/MenuButton.get_popup().connect("id_pressed", _on_id_pressed)
	$ColorRect/VSplitContainer/QuitButton.get_popup().connect("id_pressed", _on_id_pressed2)

func _on_id_pressed(id):
	if id == 0:
		get_tree().change_scene_to_file("res://scenes/Root.tscn")
	
func _on_id_pressed2(id):
	if id == 0: get_tree().quit()
