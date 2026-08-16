extends PanelContainer

#TODO: fix this slow method of updating player info every frame!
func _process(delta):
	
	var current_player_list = get_node_or_null("/root/Root").players
	
	for child in $PlayerList.get_children():
		child.queue_free()
	
	for player in current_player_list.keys():
		var label = Label.new()
		var x = current_player_list[player]
			
		label.text = "(" + x["name"] + ")" + "\t Kills: " + str(x["kills"]) + "\t Deaths: " + str(x["deaths"])
		
		if player == get_multiplayer_authority():
			label.text += " (You)"
			
		if player == 1:
			label.text += " (Host)"
			
		$PlayerList.add_child(label)
