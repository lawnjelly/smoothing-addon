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

extends Node3D

@export
var target: NodePath:
	get:
		return target
	set(v):
		target = v
		set_target()


var _m_Target: Node3D

var _m_trCurr: Transform3D
var _m_trPrev: Transform3D

const SF_ENABLED = 1 << 0
const SF_TRANSLATE = 1 << 1
const SF_BASIS = 1 << 2
const SF_SLERP = 1 << 3
const SF_INVISIBLE = 1 << 4

@export_flags("enabled", "translate", "basis", "slerp") var flags: int = SF_ENABLED | SF_TRANSLATE | SF_BASIS:
	set(v):
		flags = v
		# we may have enabled or disabled
		_SetProcessing()
	get:
		return flags


##########################################################################################
# USER FUNCS


# call this checked e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport():
	var temp_flags = flags
	_SetFlags(SF_TRANSLATE | SF_BASIS)

	_RefreshTransform()
	_m_trPrev = _m_trCurr

	# do one frame update to make sure all components are updated
	_process(0)

	# resume old flags
	flags = temp_flags


func set_enabled(bEnable: bool):
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()


func is_enabled():
	return _TestFlags(SF_ENABLED)


##########################################################################################


func _ready():
	_m_trCurr = Transform3D()
	_m_trPrev = Transform3D()
	set_process_priority(100)
	set_as_top_level(true)
	Engine.set_physics_jitter_fix(0.0)


func set_target():
	if is_inside_tree():
		_FindTarget()


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
	pass


func _enter_tree():
	# might have been moved
	_FindTarget()
	pass


func _notification(what):
	match what:
		# invisible turns unchecked processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()


func _RefreshTransform():
	if _HasTarget() == false:
		return

	_m_trPrev = _m_trCurr
	_m_trCurr = _m_Target.global_transform

func _FindTarget():
	_m_Target = null
	
	# If no target has been assigned in the property,
	# default to using the parent as the target.
	if target.is_empty():
		var parent = get_parent()
		if parent and parent is Node3D:
			_m_Target = parent
		return
		
	var targ = get_node(target)

	if ! targ:
		printerr("ERROR SmoothingNode : Target " + str(target) + " not found")
		return

	if not targ is Node3D:
		printerr("ERROR SmoothingNode : Target " + str(target) + " is not node 3D")
		target = ""
		return

	# if we got to here targ is a spatial
	_m_Target = targ

	# certain targets are disallowed
	if _m_Target == self:
		var msg = str(_m_Target.get_name()) + " assigned to " + str(self.get_name()) + "]"
		printerr("ERROR SmoothingNode : Target should not be self [", msg)

		# error message
		#OS.alert("Target cannot be a parent or grandparent in the scene tree.", "SmoothingNode")
		_m_Target = null
		target = ""
		return


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
	var tr: Transform3D = Transform3D()

	# translate
	if _TestFlags(SF_TRANSLATE):
		var ptDiff = _m_trCurr.origin - _m_trPrev.origin
		tr.origin = _m_trPrev.origin + (ptDiff * f)

	# rotate
	if _TestFlags(SF_BASIS):
		if _TestFlags(SF_SLERP):
			tr.basis = _m_trPrev.basis.slerp(_m_trCurr.basis, f)
		else:
			tr.basis = _LerpBasis(_m_trPrev.basis, _m_trCurr.basis, f)

	transform = tr


func _physics_process(_delta):
	_RefreshTransform()


func _LerpBasis(from: Basis, to: Basis, f: float) -> Basis:
	var res: Basis = Basis()
	res.x = from.x.lerp(to.x, f)
	res.y = from.y.lerp(to.y, f)
	res.z = from.z.lerp(to.z, f)
	return res


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
