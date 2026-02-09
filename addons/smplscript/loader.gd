extends ResourceFormatLoader

func _get_recognized_extensions():
	return ["smpl"]

func _get_resource_type(path):
	return "Script"

func _load(path, original_path, use_sub_threads, cache_mode):
	#var file = FileAccess.open(path, FileAccess.READ)
	#var content = file.get_as_text()
	#var res = SmplscriptResource.new()
	#res.text = content
	#return res
	
	pass
