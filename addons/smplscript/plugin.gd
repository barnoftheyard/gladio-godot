@tool
extends EditorPlugin

#var loader = null
var settings = null

#the default text file extensions just as a fallback
var text_file_extensions = "txt,md,cfg,ini,log,json,yml,yaml,toml,xml"

func _enter_tree():
	#add out custom type
	add_custom_type("SmplscriptInterpreter", "Node3D", 
	preload("res://addons/smplscript/interpreter.gd"), preload("res://addons/smplscript/icon.png"))
	
	
	#the resource loader is unused at this current time, makes the script editor not open the .smpl files
	#loader = preload("res://addons/smplscript/loader.gd").new()
	#ResourceLoader.add_resource_format_loader(loader)
	
	settings = EditorInterface.get_editor_settings()
	
	#get our current extensions string
	text_file_extensions = settings.get_settings("docks/filesystem/textfile_extensions")
	
	#add our custom text file script extension
	settings.set_setting("docks/filesystem/textfile_extensions", (text_file_extensions + ",smpl"))


#cleans up plugin deactivation
func _exit_tree():
	remove_custom_type("SmplscriptInterpreter")
	#ResourceLoader.remove_resource_format_loader(loader)
	
	settings.set_setting("docks/filesystem/textfile_extensions", text_file_extensions)
	
	
#in case we need file system handling

#func _handles(object):
	#return object is ScriptResource
#
#func _edit(object):
	#if object != null:
		#var path = object.get_path()
		#if path != "" or path != "res://":
		#
			#var data = GDScript.new()
			#data.source_code = object.text		
			#EditorInterface.edit_resource(data)
			#EditorInterface.get_script_editor().get_current_editor().get_base_editor().text = object.text
