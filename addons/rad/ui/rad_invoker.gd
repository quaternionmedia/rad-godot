class_name RadInvoker
extends Node
## How a ring gets opened, as a node a host adds beside its RadMenu. The
## contract names three invocations and this owns all of them: a secondary
## button (tap-select), a long-press that matures while the finger is still
## down (release-select), and a key. It emits where and in which mode; the
## host decides what context is under the point and calls `RadMenu.open_at`.
##
## Slop lives here and never in the machine, as the contract states: a press
## that moves more than `slop` units before `long_press_ms` is a drag, not an
## invocation. Both values are the contract's constants; a host that changes
## them states what it used.

## Open a ring at a viewport position. `mode` is "idle" or "tracking".
signal invoke(screen_pos: Vector2, mode: String)

@export var long_press_ms: int = int(RadGeometry.GEOM.longPressMs)
@export var slop: float = RadGeometry.GEOM.slop
## The key that opens a ring idle at the pointer; the reference binds `m`.
@export var open_key: Key = KEY_M
## Whether a primary mouse press may mature into release-select. Touch and
## pen always may; a mouse long-press is a desktop convenience.
@export var mouse_long_press := true

var _press_pos: Variant = null
var _press_serial := 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_disarm()
			invoke.emit(event.position, "idle")
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and mouse_long_press:
			if event.pressed:
				_arm(event.position)
			else:
				_disarm()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_arm(event.position)
		else:
			_disarm()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if _press_pos != null and (event.position - _press_pos).length() > slop:
			_disarm()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == open_key:
		invoke.emit(get_viewport().get_mouse_position(), "idle")
		get_viewport().set_input_as_handled()


func _arm(pos: Vector2) -> void:
	_press_pos = pos
	_press_serial += 1
	var serial := _press_serial
	get_tree().create_timer(long_press_ms / 1000.0).timeout.connect(func():
		# Only the press that armed this timer may fire it: a release and a new
		# press inside the window would otherwise open a ring for the wrong one.
		if _press_pos != null and serial == _press_serial:
			var p: Vector2 = _press_pos
			_press_pos = null
			invoke.emit(p, "tracking"))


func _disarm() -> void:
	_press_pos = null
