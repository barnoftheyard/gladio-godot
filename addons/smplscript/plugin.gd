@tool
extends EditorPlugin

var loader = null
var settings = null

const text_file_extensions = "txt,md,cfg,ini,log,json,yml,yaml,toml,xml"

func _enter_tree():
	add_custom_type("SmplscriptInterpreter", "Node3D", 
	preload("res://addons/smplscript/interpreter.gd"), preload("res://addons/smplscript/icon.png"))
	
	#loader = preload("res://addons/smplscript/loader.gd").new()
	#ResourceLoader.add_resource_format_loader(loader)
	
	settings = EditorInterface.get_editor_settings()
	
	settings.set_setting("docks/filesystem/textfile_extensions", text_file_extensions + ",smpl")

func _exit_tree():
	remove_custom_type("SmplscriptInterpreter")
	#ResourceLoader.remove_resource_format_loader(loader)
	
	settings.set_setting("docks/filesystem/textfile_extensions", text_file_extensions)
	
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
