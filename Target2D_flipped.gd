extends Node2D

var _x = 0
var _right = true

func _ready():
	position = Vector2(200, 100)
	set_scale(Vector2(-1, 1))


func _physics_process(delta):

	if _right:
		_x += 100
		if _x >= 800:
			_right = false
			set_scale(Vector2(1, 1))
	else:
		_x -= 100
		if _x <= 200:
			_right = true
			set_scale(Vector2(-1, 1))

	position.x = _x
