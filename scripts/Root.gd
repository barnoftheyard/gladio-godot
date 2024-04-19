extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

@onready var host_port_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/PortLineEdit
@onready var join_port_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/PortLineEdit
@onready var join_ip_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer2/HBoxContainer/IPLineEdit

func _ready():
	print("Welcome to Project Gladio!")
	
	host_port_entry.text = str(4764)
	join_port_entry.text = str(4764)
	join_ip_entry.text = "localhost"
	
	
var toggle = false
#global input
func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed() and !toggle:
			match event.keycode:
				KEY_F11:
					toggle = true
					if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
					else:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				KEY_F12:
					toggle = true
					var _time = Time.get_datetime_string_from_system()
					var filename = "user://screenshots/Screenshot-{0}.png".format({"0":_time}).validate_filename()
					get_viewport().get_texture().get_image().save_png(filename)
					
		elif event.is_released():
			toggle = false

func _on_host_pressed():
	$Title.hide()
	
	peer.create_server(int(host_port_entry.text))
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	print("Hosting server on port " + host_port_entry.text)
	
	_add_player(multiplayer.get_unique_id())
	
func _add_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	$test_world.call_deferred("add_child", player)

func _on_join_pressed():
	$Title.hide()
	
	peer.create_client(join_ip_entry.text, int(join_port_entry.text))
	multiplayer.multiplayer_peer = peer
	
	print("Joining server " + join_ip_entry.text + ": " + join_port_entry.text)


func _on_settings_button_pressed():
	$Title/Settings.show()


func _on_popup_menu_popup_hide():
	pass # Replace with function body.
