# GdUnitTestSuite
extends GdUnitTestSuite

## The Control: it is inert while closed, captures input while open, turns
## engine input events into the session's polar and key vocabulary, and draws
## the ring without a script error. The wedge polygon is checked as geometry
## because a headless run cannot look at pixels.

const CENTRE := Vector2(400, 300)


func _resolve(_context: Dictionary) -> Dictionary:
	return { "title": "canvas", "items": [
		{ "id": "a", "label": "a", "action": "act:a" }, { "id": "b", "label": "b", "action": "act:b" },
		{ "id": "c", "label": "c", "action": "act:c" }, { "id": "d", "label": "d", "action": "act:d" },
	] }


func _menu() -> RadMenu:
	var m: RadMenu = auto_free(RadMenu.new())
	add_child(m)
	m.set_resolver(_resolve)
	return m


func _mouse_at(pos: Vector2) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	return ev


func _click(pos: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.button_index = button
	ev.pressed = pressed
	return ev


func _key(keycode: Key, shift: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.shift_pressed = shift
	return ev


func test_closed_menu_is_invisible_and_ignores_input() -> void:
	var m := _menu()
	assert_bool(m.visible).is_false()
	assert_int(m.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	m._gui_input(_click(CENTRE, true))
	assert_bool(m.is_open()).is_false()


func test_open_menu_captures_input_and_a_click_commits() -> void:
	var m := _menu()
	var got := []
	m.intent.connect(func(it): got.append(it))
	m.open_at({ "type": "canvas", "targetIds": [] }, CENTRE, "idle")
	assert_bool(m.visible).is_true()
	assert_int(m.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	var right := m.session.centre() + Vector2(72, 0)
	m._gui_input(_mouse_at(right))
	assert_that(m.session.view().highlight).is_equal(1)
	m._gui_input(_click(right, true))
	m._gui_input(_click(right, false))
	assert_int(got.size()).is_equal(1)
	assert_str(got[0].action).is_equal("act:b")
	assert_bool(m.visible).is_false()
	assert_int(m.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_keys_reach_the_session_routes() -> void:
	var m := _menu()
	var got := []
	m.intent.connect(func(it): got.append(it))
	m.open_at({ "type": "canvas" }, CENTRE, "idle")
	m._gui_input(_key(KEY_TAB))                    # rotate: highlight 0
	assert_that(m.session.view().highlight).is_equal(0)
	m._gui_input(_key(KEY_DOWN))                   # nearest item below: cell 2, index 2
	assert_that(m.session.view().highlight).is_equal(2)
	m._gui_input(_key(KEY_KP_4))                   # keypad 4: left cell, index 3, commits
	assert_int(got.size()).is_equal(1)
	assert_str(got[0].itemId).is_equal("d")


func test_escape_closes_and_the_control_goes_inert() -> void:
	var m := _menu()
	var closed := [false]
	m.closed.connect(func(): closed[0] = true)
	m.open_at({ "type": "canvas" }, CENTRE, "idle")
	m._gui_input(_key(KEY_ESCAPE))
	assert_bool(closed[0]).is_true()
	assert_bool(m.visible).is_false()


func test_the_ring_draws_without_error() -> void:
	var m := _menu()
	m.open_at({ "type": "canvas" }, CENTRE, "idle")
	m._gui_input(_mouse_at(m.session.centre() + Vector2(0, -72)))
	m.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(m.is_open()).is_true()


func test_wedge_points_span_the_two_radii() -> void:
	# Vector2 is single precision: a thousandth of a unit is the tolerance it can hold.
	var pts := RadMenu.wedge_points(CENTRE, 36.0, 108.0, -45.0, 45.0, 8)
	assert_int(pts.size()).is_equal(18)
	assert_float(CENTRE.distance_to(pts[0])).is_equal_approx(108.0, 1e-3)
	assert_float(CENTRE.distance_to(pts[8])).is_equal_approx(108.0, 1e-3)
	assert_float(CENTRE.distance_to(pts[9])).is_equal_approx(36.0, 1e-3)
	assert_float(CENTRE.distance_to(pts[17])).is_equal_approx(36.0, 1e-3)
	# the outer arc starts at a0 and the inner arc returns to it
	assert_float(rad_to_deg((pts[0] - CENTRE).angle())).is_equal_approx(-45.0, 1e-3)
	assert_float(rad_to_deg((pts[17] - CENTRE).angle())).is_equal_approx(-45.0, 1e-3)


func test_tokens_resolve_roles_and_colour_verbs() -> void:
	var t := RadTheme.new()
	assert_that(t.token("wedge-fill-hl")).is_equal(t.palette["accent"])
	assert_that(t.token("color:signal")).is_equal(t.palette["signal"])
	assert_that(t.token("--rad-hub-label")).is_equal(t.palette["ink-dim"])
	assert_bool(t.has_token("color:leaf")).is_true()
	assert_bool(t.has_token("color:#ff0000")).is_false()
