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
	#set the multiplayer_peer to null if we had the peer previous set to something
	#I.E if we disconnected from a server previously
	multiplayer.multiplayer_peer = null
	
	
var toggle = false
#global input for keypresses
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

#hosts the a game for the server host. Updating player variables over the network is handled by
#the multiplayerSpawner
func _on_host_pressed():
	$Title.hide()
	
	peer.create_server(int(host_port_entry.text))
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	print("Hosting server on port " + host_port_entry.text)
	
	_add_player(multiplayer.get_unique_id())
	
	if $Title/PanelContainer/VBoxContainer/CheckBox.button_pressed:
		upnp_setup()

#the function for the signal that adds the player
func _add_player(id):
	var player = player_scene.instantiate()
	#player nodes are named by their multiplayer ID
	player.name = str(id)
	$test_world.call_deferred("add_child", player)
	
	print("Player " + str(id) + " has connected.")

#the function for the signal that removes the player
func remove_player(id):
	var player = $test_world.get_node_or_null(str(id))
	if player:
		player.queue_free()
		
	print("Player " + str(id) + " has disconnected.")

#the function that joins a hosted game
func _on_join_pressed():
	$Title.hide()
	
	peer.create_client(join_ip_entry.text, int(join_port_entry.text))
	multiplayer.multiplayer_peer = peer
	
	print("Joining server " + join_ip_entry.text + ": " + join_port_entry.text)
	
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover failed. %s" % discover_result)
	
	var gateway = upnp.get_gateway()
	assert(gateway and gateway.is_valid_gateway(), "UPNP Discover failed. %s" % discover_result)
	
	print("UPNP success. Host join address is " + upnp.query_external_address())


func _on_settings_button_pressed():
	$Title/Settings.show()


func _on_popup_menu_popup_hide():
	pass # Replace with function body.
