extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

@onready var host_port_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/PortLineEdit
@onready var join_port_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/PortLineEdit
@onready var join_ip_entry = $Title/PanelContainer/VBoxContainer/VBoxContainer2/HBoxContainer/IPLineEdit

@export var port = 6745
@export var ip = "localhost"
@export var tick_rate = 60.0

@export var players = {}
var player_info = {
	"name": "Player", 
	"kills": 0, 
	"deaths": 0
}

@export var chat_text = ""

func _ready():
	print("Welcome to Project Gladio!")
	
	#connect the signals
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	host_port_entry.text = str(port)
	join_port_entry.text = str(port)
	join_ip_entry.text = str(ip)
	#set the multiplayer_peer to null if we had the peer previous set to something
	#I.E if we disconnected from a server previously
	multiplayer.multiplayer_peer = null
	
	
var toggle = false
#global input for keypresses
func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed() and !toggle:
			match event.keycode:
				#fullscreen toggle
				KEY_F11:
					toggle = true
					if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
					else:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				#screenshot
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
	
	var return_code = peer.create_server(int(host_port_entry.text))
	#if unable to create server, then exit out of function
	if return_code != OK:
		print("Server creation error!")
		return
		
	$Title.hide()
	
	multiplayer.multiplayer_peer = peer
	
	print("Hosting server on port " + host_port_entry.text)
	
	_add_player(1)
	players[1] = player_info
	
	if $Title/PanelContainer/VBoxContainer/CheckBox.button_pressed:
		upnp_setup()
		
#the function that joins a hosted game
func _on_join_pressed():
	$Title.hide()
	
	peer.create_client(join_ip_entry.text, int(join_port_entry.text))
	multiplayer.multiplayer_peer = peer
	
	print("Joining server " + join_ip_entry.text + ": " + join_port_entry.text)


#the function for the signal that adds the player
@rpc("any_peer", "call_local", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	
	print(players[new_player_id]["name"] + " (ID: " + str(new_player_id) + ")" + " has connected.")
	#player_connected.emit(new_player_id, new_player_info)
	
func _add_player(id):
	
	_register_player.rpc_id(id, player_info)
	
	#if we're not the server then gtfo
	if not multiplayer.is_server():
		return
		
	var player = player_scene.instantiate()
	player.set_multiplayer_authority(id)
	#player nodes are named by their multiplayer ID
	player.name = str(id)
	player.position += Vector3(randi_range(-3, 3), 0, randi_range(-3, 3))
	$test_world.call_deferred("add_child", player, true)
	
func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info

#the function for the signal that removes the player
func _remove_player(id):
	var player = $test_world.get_node_or_null(str(id))
	if player != null:
		player.queue_free()
		
	players.erase(id)
	print("Player " + str(id) + " has disconnected.")
	
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover failed. %s" % discover_result)
	
	var gateway = upnp.get_gateway()
	assert(gateway and gateway.is_valid_gateway(), "UPNP Discover failed. %s" % discover_result)
	
	print("UPNP success. Host join address is " + upnp.query_external_address())


func _on_settings_button_pressed():
	$Title/Settings.show()

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	get_tree().change_scene_to_file("res://scenes/Root.tscn")
	
func _on_connected_fail():
	print("Failed connection!")
	remove_multiplayer_peer()
	
func _on_server_disconnected():
	print("Host server disconnected!")
	remove_multiplayer_peer()

#please keep this
func _on_name_line_edit_text_changed(new_text: String) -> void:
	player_info["name"] = new_text
