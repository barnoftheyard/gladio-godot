extends PanelContainer

var player_list = {}

func _process(delta):
	
	var current_player_list = get_node_or_null("/root/Root")
	
	for child in $PlayerList.get_children():
		child.queue_free()
	
	
	for y in current_player_list.players.keys():
		var label = Label.new()
		var x = current_player_list.players[y]
		label.text = x["name"] + "\t K: " + str(x["kills"]) + "\t D: " + str(x["deaths"])
		$PlayerList.add_child(label)
