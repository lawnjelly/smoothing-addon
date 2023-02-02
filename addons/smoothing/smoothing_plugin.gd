@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
	add_custom_type("Smoothing", "Node3D", preload("smoothing.gd"), preload("smoothing.png"))
	add_custom_type("Smoothing2D", "Node2D", preload("smoothing_2d.gd"), preload("smoothing_2d.png"))
	pass


func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove_at it from the engine when deactivated
	remove_custom_type("Smoothing")
	remove_custom_type("Smoothing2D")
