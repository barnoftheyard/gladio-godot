@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("SmplscriptInterpreter", "Node3D", 
	preload("res://addons/smplscript/interpreter.gd"), preload("res://addons/smplscript/logic_auto.png"))

func _exit_tree():
	remove_custom_type("SmplscriptInterpreter")
