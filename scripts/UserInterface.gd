extends Control


func _process(_delta):
	#misc nop-player character input
	if Input.is_action_just_pressed(get_parent().PAUSE) and is_multiplayer_authority() \
	and !$Info.visible:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$AnimationPlayer.play("fade")
			$ColorRect.show()
			get_parent().immobile = true
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$ColorRect.hide()
			get_parent().immobile = false
			
	if Input.is_action_just_pressed("info") and is_multiplayer_authority() and \
	!$ColorRect.visible:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			#$AnimationPlayer.play("fade")
			$Info.show()
			get_parent().immobile = true
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$Info.hide()
			get_parent().immobile = false
			
	if Input.is_action_just_pressed("debug") and is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$AnimationPlayer.play("console")
			$DebugPanel.show()
			get_parent().immobile = true
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$DebugPanel.hide()
			get_parent().immobile = false
			
	if Input.is_action_just_pressed("chat") and !$ChatPanel/VBoxContainer/HBoxContainer.is_visible_in_tree() \
	and is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$ChatPanel.show()
		$ChatPanel/Timer.stop()
		$ChatPanel/VBoxContainer/HBoxContainer.show()
		$ChatPanel/VBoxContainer/HBoxContainer/LineEdit.grab_focus()
		get_parent().immobile = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$ColorRect/VSplitContainer/MenuButton.get_popup().connect("id_pressed", _on_id_pressed)
	$ColorRect/VSplitContainer/QuitButton.get_popup().connect("id_pressed", _on_id_pressed2)

func _on_id_pressed(id):
	if id == 0:
		get_tree().change_scene_to_file("res://scenes/Root.tscn")
	
func _on_id_pressed2(id):
	if id == 0: get_tree().quit()

@rpc("any_peer", "call_local", "reliable") 
func send_msg(new_text):
	$ChatPanel/VBoxContainer/Label.text += get_parent().name + ": " + new_text + "\n"
	print(get_parent().name + ": " + new_text)

func _on_line_edit_text_submitted(new_text):
	send_msg(new_text)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$ChatPanel/VBoxContainer/HBoxContainer.hide()
	get_parent().immobile = false
	
	$ChatPanel/VBoxContainer/HBoxContainer/LineEdit.text = ""
	
	$ChatPanel/Timer.start(3)


func _on_timer_timeout():
	$ChatPanel.hide()


func _on_timer_2_timeout():
	var systolic = clamp(get_parent().health + 20, 60, 140)  + randi_range(0, 10)
	var dystolic = clamp(get_parent().health - 20, 40, 120) + randi_range(0, 10)
	
	var heartrate = clamp(get_parent().health, 50, 160) + randi_range(0, 10)
	
	$Info/VBoxContainer/HBoxContainer/bp.text = str(systolic) + "\n" + str(dystolic)
	$Info/VBoxContainer/HBoxContainer2/hr.text = str(heartrate)
