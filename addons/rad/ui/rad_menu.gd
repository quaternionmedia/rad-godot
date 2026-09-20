class_name RadMenu
extends Control
## The ring, drawn. A full-rect Control that is invisible and ignores input
## while closed, and captures the pointer once a ring is up so the host stops
## seeing motion the menu owns. It draws the reference's wedges — from r0+3 to
## r1, eight units taller when highlighted, a 1.2-degree gap each side — and
## reads every colour through RadTheme tokens. It holds no host reference: the
## host supplies a resolver and connects `intent`.
##
## Add it as a child of a CanvasLayer at the origin, so its local coordinates
## are the viewport's; the session's geometry is expressed in those units.

## Re-emitted from the session when a commit leaves the addon.
signal intent(intent: Dictionary)
## A ring is on screen.
signal opened()
## The ring left the screen without committing.
signal closed()

@export var tokens: RadTheme
## Cell digits are drawn only where the ring and the keypad agree (four items
## or fewer, per the nine-cells record). A ring host does not announce two
## placements at once.
@export var show_cell_digits := true
@export var label_font_size := 14
@export var hub_font_size := 13

var session := RadSession.new()


func _ready() -> void:
	if tokens == null:
		tokens = RadTheme.new()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	focus_mode = FOCUS_ALL
	_hide_ring()
	session.ring_changed.connect(queue_redraw)
	session.highlighted.connect(func(_i, _id, _label): queue_redraw())
	session.committed.connect(_on_committed)
	session.cancelled.connect(_on_cancelled)


## The host's content: (context: Dictionary) -> MenuSpec.
func set_resolver(resolver: Callable) -> void:
	session.resolve = resolver


## Open for `context` at a viewport position. `mode` is "idle" (tap-select)
## or "tracking" (release-select, the invoking press still down).
func open_at(context: Dictionary, screen_pos: Vector2, mode: String = "idle") -> void:
	session.open_at(context, screen_pos, get_viewport_rect().size, mode)
	if session.is_open():
		visible = true
		mouse_filter = MOUSE_FILTER_STOP
		grab_focus()
		queue_redraw()
		opened.emit()


func is_open() -> bool:
	return session.is_open()


func _on_committed(it: Dictionary) -> void:
	_hide_ring()
	intent.emit(it)


func _on_cancelled() -> void:
	_hide_ring()
	closed.emit()


func _hide_ring() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	if has_focus():
		release_focus()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not session.is_open():
		return
	var t := int(Time.get_ticks_msec())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			session.pointer("down" if event.pressed else "up", event.position, t)
			accept_event()
	elif event is InputEventMouseMotion:
		session.pointer("move", event.position, t)
	elif event is InputEventScreenTouch:
		session.pointer("down" if event.pressed else "up", event.position, t)
		accept_event()
	elif event is InputEventScreenDrag:
		session.pointer("move", event.position, t)
	elif event is InputEventKey and event.pressed and not event.echo:
		if _key(event, t):
			accept_event()


## The keyboard host binds all three of the nine-cells record's routes: a
## digit chooses its cell, an arrow moves to the nearest item in that
## direction, 5 backs out. Tab and Shift+Tab rotate the highlight through the
## machine's own key path, so the contract's rotate-and-commit is reachable too.
func _key(event: InputEventKey, t: int) -> bool:
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			session.key("Enter", t)
		KEY_ESCAPE:
			session.key("Escape", t)
		KEY_TAB:
			session.key("ArrowLeft" if event.shift_pressed else "ArrowRight", t)
		KEY_UP:
			session.move_cell("up", t)
		KEY_DOWN:
			session.move_cell("down", t)
		KEY_LEFT:
			session.move_cell("left", t)
		KEY_RIGHT:
			session.move_cell("right", t)
		_:
			var digit := _digit_of(event.keycode)
			if digit < 1:
				return false
			session.press_cell(digit, t)
	return true


static func _digit_of(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode - KEY_0)
	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return int(keycode - KEY_KP_0)
	return 0


func _draw() -> void:
	if not session.is_open():
		return
	var v: Dictionary = session.view()
	var g: Dictionary = v.geometry
	var c: Vector2 = v.centre
	var n: int = v.items.size()
	var half := 180.0 / n
	var digits := show_cell_digits and RadCells.cellAgreesWithRing(n)
	for i in n:
		var item: Dictionary = v.items[i]
		var hl: bool = v.highlight == i
		var a := RadGeometry.itemCenterDeg(i, n)
		var grow := 8.0 if hl else 0.0
		var pts := wedge_points(c, g.r0 + 3.0, g.r1 + grow, a - half + 1.2, a + half - 1.2)
		var fill := tokens.token("wedge-fill-hl" if hl else "wedge-fill")
		if not item.enabled:
			fill.a *= 0.45
		draw_colored_polygon(pts, fill)
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, tokens.token("wedge-stroke"), 1.5, true)
		var rm: float = (g.r0 + g.r1) / 2.0 + grow / 2.0
		var tp: Vector2 = c + Vector2.from_angle(deg_to_rad(a)) * rm
		if item.swatch != null and tokens.has_token(str(item.swatch)):
			draw_circle(tp, 11.0, tokens.token(str(item.swatch)))
			draw_arc(tp, 11.0, 0.0, TAU, 32, tokens.token("page-bg"), 2.0, true)
		else:
			var col := tokens.token("wedge-label-hl" if hl else ("wedge-label-danger" if item.destructive else "wedge-label"))
			if not item.enabled:
				col.a *= 0.6
			_text(str(item.label).substr(0, 12), tp, col, label_font_size)
			if item.hasChildren:
				_text("▸ more", tp + Vector2(0, 15), col, label_font_size - 4)
		if digits:
			var cell: int = v.placement.byIndex[i]
			var bp: Vector2 = c + Vector2.from_angle(deg_to_rad(a)) * (g.r1 + grow + 12.0)
			_text(str(cell), bp, tokens.token("text-dim"), 11)
	draw_circle(c, g.r0 - 2.0, tokens.token("hub-fill"))
	draw_arc(c, g.r0 - 2.0, 0.0, TAU, 48, tokens.token("hub-stroke"), 1.5, true)
	var title := "←" if v.depth > 1 else str(v.title if v.title != null else "").substr(0, 9)
	_text(title, c, tokens.token("hub-label"), hub_font_size)


## A wedge between two radii and two angles (degrees, screen convention), as a
## polygon: the outer arc one way, the inner arc back. Pure, so a host drawing
## its own wedges can use it.
static func wedge_points(c: Vector2, r0: float, r1: float, a0: float, a1: float, steps: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in steps + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(k) / steps))
		pts.append(c + Vector2.from_angle(a) * r1)
	for k in steps + 1:
		var a := deg_to_rad(lerpf(a1, a0, float(k) / steps))
		pts.append(c + Vector2.from_angle(a) * r0)
	return pts


func _text(s: String, at: Vector2, col: Color, size: int) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, at + Vector2(-w / 2.0, size * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
