extends Node3D

var m_Dir = 1
var m_Scale = Vector3(1, 1, 1)
var m_Angle = 0.0


func _physics_process(_delta):
	var tr = transform
	
	var x = tr.origin.x
	if x >= 5:
		m_Dir = -1
	if x <= -5:
		m_Dir = +1
	
	x += m_Dir * _delta
	tr.origin.x = x

	m_Angle += _delta
	if m_Angle > (PI*2):
		m_Angle -= PI*2
	
	var rotvec = Vector3(1, 0.5, 0.2)
	rotvec = rotvec.normalized()
	
	tr.basis = Basis(rotvec, m_Angle)

	m_Scale.x = rand_scale(m_Scale.x)
	m_Scale.y = rand_scale(m_Scale.y)
	m_Scale.z = rand_scale(m_Scale.z)

	#m_Scale = Vector3(0.5, 0.5, 0.5)
	#tr.basis = tr.basis.scaled(m_Scale)
	#scale_object_local(m_Scale)

	transform = tr
	
	pass

func rand_scale(v):
	v = v + (randf() - 0.5) * 0.2
	v = clamp(v, 0.3, 3.0)
	return v
