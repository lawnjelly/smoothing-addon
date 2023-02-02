extends Node3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("ui_select"):
		$Example3D/Target.position = Vector3(0, 0, 0)
		$Example3D/Target/Smoothing.teleport()
		
		$Example2D/Target2D.position = Vector2(300, 300)
		$Example2D/Target2D/Smoothing2D.teleport()
