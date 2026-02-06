@tool
extends EditorPlugin

var import_plugin = preload("res://addons/smplscript/import.gd").new()


func _enter_tree():
	add_custom_type("SmplscriptInterpreter", "Node3D", 
	preload("res://addons/smplscript/interpreter.gd"), preload("res://addons/smplscript/icon.png"))
	add_import_plugin(import_plugin)

func _exit_tree():
	remove_custom_type("SmplscriptInterpreter")
	remove_import_plugin(import_plugin)
