extends PopupMenu

const FULLSCREEN_ID = 1
const PLAYER_NAME_ID = 3
var player_name = "player"

func _ready():
	set_item_text(PLAYER_NAME_ID, "Player Name: \"" + player_name + "\"")

func _on_id_pressed(id):
	match id:
		FULLSCREEN_ID:
			if !is_item_checked(id):
				set_item_checked(id, true)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 
			else: 
				set_item_checked(id, false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		PLAYER_NAME_ID:
			$PlayerNamePopup.show()

func _on_line_edit_text_submitted(new_text):
	player_name = new_text
	set_item_text(PLAYER_NAME_ID, "Player Name: \"" + new_text + "\"")
	$PlayerNamePopup.hide()
