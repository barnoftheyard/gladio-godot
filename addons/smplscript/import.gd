@tool
extends EditorImportPlugin

func _get_importer_name():
	return "smplscript"

func _get_visible_name():
	return "Smplscript"

func _get_recognized_extensions():
	return ["smplscript", "smpl"]
	
func _get_resource_type():
	return "Script"

func _get_save_extension():
	return "smpl"

#func _get_import_options(path, preset_index):
	#return [{"name": "my_option", "default_value": false}]

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED

	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(file, filename)
