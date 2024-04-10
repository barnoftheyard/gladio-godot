extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func _on_host_pressed():
	$Title.hide()
	
	peer.create_server(4764)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player(multiplayer.get_unique_id())
	
func _add_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	$test_world.call_deferred("add_child", player)

func _on_join_pressed():
	$Title.hide()
	
	peer.create_client("localhost", 4764)
	multiplayer.multiplayer_peer = peer
