extends Node2D

const MOVE_DIST = 100
var m_Dir = MOVE_DIST

func _physics_process(_delta):
	var x = get_position().x
	
	if x > 1000:
		m_Dir = -MOVE_DIST
	if x < 0:
		m_Dir = MOVE_DIST
		
	x += m_Dir
	
	position.x = x
	
	rotate(0.1)
	
	var sc = x / 1000.0
	
	set_scale(Vector2(sc * 3, (1.0 - sc) * 3))
	
	pass
