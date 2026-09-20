# GdUnitTestSuite
extends GdUnitTestSuite

## The session above the machine: both commit styles through screen
## coordinates, and the nine-cells record's three keyboard routes — a digit
## chooses its cell, a direction moves to the nearest item in that direction,
## 5 backs out — plus the corner two directions name inside the chord window.
##
## Four items sit at the cardinals (cells 8, 6, 2, 4 for indices 0..3), which
## is the case where the ring and the keypad agree; eight items is the case
## where they do not, and where a corner exists to chord into.

const VIEWPORT := Vector2(800, 600)
const CENTRE := Vector2(400, 300)


func _spec(n: int, disabled: Array = [], with_children_at: int = -1) -> Callable:
	return func(_context: Dictionary) -> Dictionary:
		var items := []
		for i in n:
			var item := { "id": "i%d" % i, "label": "item %d" % i, "action": "act:%d" % i }
			if disabled.has(i):
				item.enabled = false
			if i == with_children_at:
				item.children = [{ "id": "c0", "label": "child 0" }, { "id": "c1", "label": "child 1" }]
			items.append(item)
		return { "title": "t", "items": items }


func _session(n: int, disabled: Array = [], with_children_at: int = -1) -> RadSession:
	var s := RadSession.new()
	s.resolve = _spec(n, disabled, with_children_at)
	return s


## A point in the committing band at a contract angle (degrees, -90 up).
func _band(angle_deg: float, r: float = 72.0) -> Vector2:
	return CENTRE + Vector2.from_angle(deg_to_rad(angle_deg)) * r


func test_open_idle_reports_a_view_and_fits_the_ring() -> void:
	var s := _session(4)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	assert_bool(s.is_open()).is_true()
	var v: Dictionary = s.view()
	assert_int(v.items.size()).is_equal(4)
	assert_int(v.depth).is_equal(1)
	assert_float(v.geometry.r1).is_equal(RadGeometry.GEOM.r1)
	assert_that(s.centre()).is_equal(CENTRE)


func test_the_ring_is_clamped_inside_the_viewport() -> void:
	var s := _session(4)
	s.open_at({ "type": "canvas" }, Vector2(5, 5), VIEWPORT, "idle")
	var c := s.centre()
	assert_float(c.x).is_greater(RadGeometry.GEOM.r1)
	assert_float(c.y).is_greater(RadGeometry.GEOM.r1)


func test_tap_select_commits_the_wedge_under_a_click() -> void:
	var s := _session(4)
	var got := []
	s.committed.connect(func(it): got.append(it))
	s.open_at({ "type": "canvas", "targetIds": [] }, CENTRE, VIEWPORT, "idle")
	s.pointer("move", _band(0.0))          # right: index 1
	assert_that(s.view().highlight).is_equal(1)
	s.pointer("down", _band(0.0))
	s.pointer("up", _band(0.0))
	assert_int(got.size()).is_equal(1)
	assert_str(got[0].action).is_equal("act:1")
	assert_str(got[0].itemId).is_equal("i1")
	assert_str(got[0].context.type).is_equal("canvas")
	assert_bool(got[0].has("t")).is_true()
	assert_bool(s.is_open()).is_false()


func test_release_select_commits_on_release_in_the_band() -> void:
	var s := _session(4)
	var got := []
	var hl := []
	s.committed.connect(func(it): got.append(it))
	s.highlighted.connect(func(i, _id, label): hl.append([i, label]))
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "tracking")
	s.pointer("move", _band(90.0))         # down: index 2
	s.pointer("move", _band(92.0))         # same wedge: edge-triggered, no second highlight
	s.pointer("up", _band(90.0))
	assert_array(hl).is_equal([[2, "item 2"]])
	assert_int(got.size()).is_equal(1)
	assert_str(got[0].action).is_equal("act:2")


func test_release_in_the_dead_zone_cancels() -> void:
	var s := _session(4)
	var cancelled := [false]
	s.cancelled.connect(func(): cancelled[0] = true)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "tracking")
	s.pointer("move", _band(0.0))
	s.pointer("up", CENTRE + Vector2(10, 0))
	assert_bool(cancelled[0]).is_true()
	assert_bool(s.is_open()).is_false()


func test_a_digit_chooses_its_cell() -> void:
	var s := _session(4)
	var got := []
	s.committed.connect(func(it): got.append(it))
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.press_cell(6)                          # right cell holds index 1
	assert_int(got.size()).is_equal(1)
	assert_str(got[0].itemId).is_equal("i1")


func test_five_backs_out_at_every_depth() -> void:
	var s := _session(4, [], 0)
	var cancelled := [false]
	s.cancelled.connect(func(): cancelled[0] = true)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.press_cell(8)                          # item 0 has children: enters the submenu
	assert_int(s.view().depth).is_equal(2)
	s.press_cell(5)
	assert_int(s.view().depth).is_equal(1)
	assert_bool(cancelled[0]).is_false()
	s.press_cell(5)
	assert_bool(cancelled[0]).is_true()


func test_an_empty_or_disabled_cell_is_not_a_landing_place() -> void:
	var s := _session(4, [1])
	var got := []
	s.committed.connect(func(it): got.append(it))
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	assert_array(s.press_cell(7)).is_empty()         # corner: empty at four items
	assert_array(s.press_cell(6)).is_empty()         # right: disabled
	assert_that(s.view().highlight).is_null()
	assert_int(got.size()).is_equal(0)


func test_a_direction_moves_to_the_nearest_item_in_that_direction() -> void:
	var s := _session(4)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.move_cell("right", 1000)
	assert_that(s.view().highlight).is_equal(1)      # from the centre to cell 6
	s.move_cell("left", 2000)                         # far enough apart not to chord
	assert_that(s.view().highlight).is_equal(3)      # cell 4, past the empty centre
	s.move_cell("up", 3000)
	assert_that(s.view().highlight).is_equal(0)      # cell 8, the defect the record names


func test_two_directions_inside_the_window_name_the_corner() -> void:
	var s := _session(8)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.move_cell("up", 1000)
	s.move_cell("left", 1100)                         # inside CHORD_WINDOW_MS
	var placement: Dictionary = RadCells.placeCells(8)
	assert_that(s.view().highlight).is_equal(placement.byCell[7])
	assert_that(s.current_cell()).is_equal(7)


func test_the_same_two_directions_apart_walk_to_the_same_corner() -> void:
	var s := _session(8)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.move_cell("up", 1000)
	s.move_cell("left", 5000)                         # well past the window
	assert_that(s.current_cell()).is_equal(7)


func test_tab_rotates_through_the_machine_key_path() -> void:
	var s := _session(4)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	s.key("ArrowRight")
	assert_that(s.view().highlight).is_equal(0)
	s.key("ArrowRight")
	assert_that(s.view().highlight).is_equal(1)
	s.key("ArrowLeft")
	assert_that(s.view().highlight).is_equal(0)


func test_polar_uses_the_contract_convention() -> void:
	var s := _session(4)
	s.open_at({ "type": "canvas" }, CENTRE, VIEWPORT, "idle")
	assert_float(s.polar(CENTRE + Vector2(0, -50)).thetaDeg).is_equal_approx(-90.0, 1e-6)
	assert_float(s.polar(CENTRE + Vector2(50, 0)).thetaDeg).is_equal_approx(0.0, 1e-6)
	assert_float(s.polar(CENTRE + Vector2(0, 50)).thetaDeg).is_equal_approx(90.0, 1e-6)
	assert_float(s.polar(CENTRE + Vector2(0, 50)).r).is_equal_approx(50.0, 1e-6)
