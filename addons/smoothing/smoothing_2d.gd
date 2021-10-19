#	Copyright (c) 2019 Lawnjelly
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

extends Node2D

export (NodePath) var target: NodePath setget set_target, get_target

var _m_Target: Node2D

var m_Pos_curr: Vector2 = Vector2()
var m_Pos_prev: Vector2 = Vector2()

var m_Angle_curr: float
var m_Angle_prev: float

var m_Scale_curr: Vector2 = Vector2()
var m_Scale_prev: Vector2 = Vector2()

const SF_ENABLED = 1 << 0
const SF_TRANSLATE = 1 << 1
const SF_ROTATE = 1 << 2
const SF_SCALE = 1 << 3
const SF_GLOBAL_IN = 1 << 4
const SF_GLOBAL_OUT = 1 << 5
const SF_INVISIBLE = 1 << 6

export (int, FLAGS, "enabled", "translate", "rotate", "scale", "global in", "global out") var flags: int = SF_ENABLED | SF_TRANSLATE setget _set_flags, _get_flags

##########################################################################################
# USER FUNCS


# call this on e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport():
	var temp_flags = flags
	_SetFlags(SF_TRANSLATE | SF_ROTATE | SF_SCALE)

	_RefreshTransform()
	m_Pos_prev = m_Pos_curr
	m_Angle_prev = m_Angle_curr
	m_Scale_prev = m_Scale_curr

	# call frame upate to make sure all components of the node are set
	_process(0)

	# get back the old flags
	flags = temp_flags


func set_enabled(bEnable: bool):
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()


func is_enabled():
	return _TestFlags(SF_ENABLED)


##########################################################################################


func _ready():
	m_Angle_curr = 0
	m_Angle_prev = 0
	set_process_priority(100)
	Engine.set_physics_jitter_fix(0.0)


func set_target(new_value):
	target = new_value
	if is_inside_tree():
		_FindTarget()


func get_target():
	return target


func _set_flags(new_value):
	flags = new_value
	# we may have enabled or disabled
	_SetProcessing()


func _get_flags():
	return flags


func _SetProcessing():
	var bEnable = _TestFlags(SF_ENABLED)
	if _TestFlags(SF_INVISIBLE):
		bEnable = false

	set_process(bEnable)
	set_physics_process(bEnable)


func _enter_tree():
	# might have been moved
	_FindTarget()


func _notification(what):
	match what:
		# invisible turns off processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()


func _RefreshTransform():

	if _HasTarget() == false:
		return

	if _TestFlags(SF_GLOBAL_IN):
		if _TestFlags(SF_TRANSLATE):
			m_Pos_prev = m_Pos_curr
			m_Pos_curr = _m_Target.get_global_position()

		if _TestFlags(SF_ROTATE):
			m_Angle_prev = m_Angle_curr
			m_Angle_curr = _m_Target.get_global_rotation()

		if _TestFlags(SF_SCALE):
			m_Scale_prev = m_Scale_curr
			m_Scale_curr = _m_Target.get_global_scale()
	else:
		if _TestFlags(SF_TRANSLATE):
			m_Pos_prev = m_Pos_curr
			m_Pos_curr = _m_Target.get_position()

		if _TestFlags(SF_ROTATE):
			m_Angle_prev = m_Angle_curr
			m_Angle_curr = _m_Target.get_rotation()

		if _TestFlags(SF_SCALE):
			m_Scale_prev = m_Scale_curr
			m_Scale_curr = _m_Target.get_scale()


func _IsTargetParent(node):
	if node == _m_Target:
		return true  # disallow

	var parent = node.get_parent()
	if parent:
		return _IsTargetParent(parent)

	return false


func _FindTarget():
	_m_Target = null
	if target.is_empty():
		return

	var targ = get_node(target)

	if ! targ:
		printerr("ERROR SmoothingNode2D : Target " + target + " not found")
		return

	if not targ is Node2D:
		printerr("ERROR SmoothingNode2D : Target " + target + " is not Node2D")
		target = ""
		return

	# if we got to here targ is correct type
	_m_Target = targ

	# hard coded to off in 2d to allow this for now
	# but I'm still not sure it should be allowed...

	# do a final check
	# is the target a parent or grandparent of the smoothing node?
	# if so, disallow


#	if _IsTargetParent(self):
#		var msg = _m_Target.get_name() + " assigned to " + self.get_name() + "]"
#		printerr("ERROR SmoothingNode2D : Target should not be a parent or grandparent [", msg)
#
#		# error message
#		_m_Target = null
#		target = ""
#		return


func _HasTarget() -> bool:
	if _m_Target == null:
		return false

	# has not been deleted?
	if is_instance_valid(_m_Target):
		return true

	_m_Target = null
	return false


func _process(_delta):

	var f = Engine.get_physics_interpolation_fraction()

	if _TestFlags(SF_GLOBAL_OUT):
		# translate
		if _TestFlags(SF_TRANSLATE):
			set_global_position(m_Pos_prev.linear_interpolate(m_Pos_curr, f))

		# rotate
		if _TestFlags(SF_ROTATE):
			var r = _LerpAngle(m_Angle_prev, m_Angle_curr, f)
			set_global_rotation(r)

		if _TestFlags(SF_SCALE):
			set_global_scale(m_Scale_prev.linear_interpolate(m_Scale_curr, f))
	else:
		# translate
		if _TestFlags(SF_TRANSLATE):
			set_position(m_Pos_prev.linear_interpolate(m_Pos_curr, f))

		# rotate
		if _TestFlags(SF_ROTATE):
			var r = _LerpAngle(m_Angle_prev, m_Angle_curr, f)
			set_rotation(r)

		if _TestFlags(SF_SCALE):
			set_scale(m_Scale_prev.linear_interpolate(m_Scale_curr, f))

	pass


func _physics_process(_delta):
	_RefreshTransform()


func _LerpAngle(from: float, to: float, weight: float) -> float:
	return from + _ShortAngleDist(from, to) * weight


func _ShortAngleDist(from: float, to: float) -> float:
	var max_angle: float = 2 * PI
	var diff: float = fmod(to - from, max_angle)
	return fmod(2.0 * diff, max_angle) - diff


func _SetFlags(f):
	flags |= f


func _ClearFlags(f):
	flags &= ~f


func _TestFlags(f):
	return (flags & f) == f


func _ChangeFlags(f, bSet):
	if bSet:
		_SetFlags(f)
	else:
		_ClearFlags(f)
