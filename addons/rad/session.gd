class_name RadSession
extends RefCounted
## The seam a host integrates against — the port of the reference's
## createSession. A host supplies CONTENT (`resolve`) and STATE (whatever it
## connects to `committed`); the session owns one machine, the geometry it was
## opened with, and nothing else. It never reaches a scene.
##
## Above the machine, not inside it, live the nine-cells record's keyboard
## clauses — a digit chooses its cell, a direction moves to the nearest item in
## that direction, 5 backs out — exactly as the terminal port in dossier places
## them, so step() stays a verbatim port and the vectors keep describing it.

## The ring on screen changed: opened, entered a submenu, or came back.
signal ring_changed()
## Edge-triggered, carrying what the effect carried; never re-resolved.
signal highlighted(i: Variant, id: Variant, label: String)
## An intent left the addon: {action, context, itemId, t}.
signal committed(intent: Dictionary)
## The menu closed without committing.
signal cancelled()
## Every machine effect, raw, for a host that meters.
signal effect(fx: Dictionary)

## Two directions inside this window name the corner between them (nine-cells
## record §6). The chord is a shortcut over the movement, never the only route.
const CHORD_WINDOW_MS := 250

## (context: Dictionary) -> MenuSpec Dictionary. The host's content.
var resolve: Callable
## Merged over the fitted geometry at every opening; a host's density override.
var geometry_override: Dictionary = {}

var _machine: Variant = null
var _ctx: Variant = null
var _geom: Variant = null
var _centre := Vector2.ZERO
var _last_direction: String = ""
var _last_direction_at: int = -1


func is_open() -> bool:
	return _machine != null


func centre() -> Vector2:
	return _centre


func geometry() -> Variant:
	return _geom


## The ring currently on screen, or null. A read-only view for a renderer.
func view() -> Variant:
	if _machine == null:
		return null
	var top: Dictionary = _machine.stack[-1]
	var items := []
	for it in top.items:
		items.append({
			"id": it.id, "label": str(it.get("label", "")), "swatch": it.get("swatch"),
			"icon": it.get("icon"), "enabled": it.get("enabled", true) != false,
			"destructive": bool(it.get("destructive", false)), "hasChildren": it.get("children") != null,
		})
	return {
		"title": top.get("title"), "items": items, "highlight": _machine.highlight,
		"depth": _machine.stack.size(), "geometry": _geom, "centre": _centre,
		"placement": RadCells.placeCells(items.size()),
	}


## Open a menu for `context` at a screen position, fitted to the viewport and
## clamped inside it. `mode` is "idle" (tap-select) or "tracking"
## (release-select: the invoking press is still down).
func open_at(context: Dictionary, screen_pos: Vector2, viewport: Vector2, mode: String = "idle") -> Array:
	if not resolve.is_valid():
		push_error("rad: a host must supply resolve(context) -> MenuSpec")
		return []
	var spec: Dictionary = resolve.call(context)
	var problem := RadMachine.assertRing(spec.get("items"), str(spec.get("title", "root")))
	if problem != "":
		push_error(problem)
		return []
	var geom := RadGeometry.GEOM.duplicate()
	geom.merge(RadGeometry.fitRing(viewport.x, viewport.y), true)
	geom.merge(geometry_override, true)
	var c := RadGeometry.clampRingCentre(screen_pos.x, screen_pos.y, viewport.x, viewport.y, geom.r1)
	_centre = Vector2(c.x, c.y)
	_geom = geom
	_ctx = context
	_machine = RadMachine.createMachine(spec, geom)
	_last_direction = ""
	if mode == "tracking":
		_machine.status = "pending"
		return _dispatch({ "type": "longpress" })
	return _dispatch({ "type": "open" })


## Feed one raw machine event: down | move | up | key | longpress | close.
func input(ev: Dictionary) -> Array:
	return _dispatch(ev)


## A pointer event in screen coordinates, converted to the contract's polar
## frame around the ring centre: r in units, thetaDeg with -90 up, clockwise
## positive in screen space. `kind` is down | move | up.
func pointer(kind: String, screen_pos: Vector2, t: int = -1) -> Array:
	if _machine == null:
		return []
	var p := polar(screen_pos)
	return _dispatch({ "type": kind, "r": p.r, "thetaDeg": p.thetaDeg, "t": _stamp(t) })


## A key in the machine's vocabulary: ArrowLeft/Right/Up/Down, Enter, Escape.
func key(name: String, t: int = -1) -> Array:
	if _machine == null:
		return []
	return _dispatch({ "type": "key", "key": name, "t": _stamp(t) })


func close() -> Array:
	if _machine == null:
		return []
	return _dispatch({ "type": "close" })


func polar(screen_pos: Vector2) -> Dictionary:
	var d := screen_pos - _centre
	return { "r": d.length(), "thetaDeg": rad_to_deg(atan2(d.y, d.x)) }


## Choose the item in a numpad cell directly. One input. The centre backs out
## at every depth. An empty cell is not a transition; a disabled one is
## recognized and refused, and the highlight does not move onto it.
func press_cell(cell: int, t: int = -1) -> Array:
	if _machine == null:
		return []
	if cell == RadCells.BACK_CELL:
		return key("Escape", t)
	var v: Dictionary = view()
	var placement: Variant = v.placement
	if placement == null or not placement.byCell.has(cell):
		return []
	var index: int = placement.byCell[cell]
	if not v.items[index].enabled:
		return []
	var fx := _set_highlight(index)
	fx.append_array(key("Enter", t))
	return fx


## Move the highlight to the nearest item in a direction (up|down|left|right).
## Two directions inside CHORD_WINDOW_MS name the corner between them.
func move_cell(dir: String, t: int = -1) -> Array:
	if _machine == null or not RadCells.CELL_STEP.has(dir):
		return []
	var now := _stamp(t)
	var v: Dictionary = view()
	var placement: Variant = v.placement
	if placement == null:
		return []
	var allowed := []
	for cell in placement.byCell:
		if v.items[placement.byCell[cell]].enabled:
			allowed.append(cell)
	var target: Variant = null
	if _last_direction != "" and _last_direction_at >= 0 and now - _last_direction_at <= CHORD_WINDOW_MS:
		var corner: Variant = RadCells.cellChord(_last_direction, dir)
		if corner != null and placement.byCell.has(corner) and allowed.has(corner):
			target = corner
	if target == null:
		target = RadCells.cellStepToItem(current_cell(), dir, placement, allowed)
	_last_direction = dir
	_last_direction_at = now
	if not placement.byCell.has(target):
		return []
	return _set_highlight(placement.byCell[target])


## The cell the highlight sits in, or the centre when nothing is highlighted —
## which is where a direction press starts from.
func current_cell() -> int:
	if _machine == null or _machine.highlight == null:
		return RadCells.BACK_CELL
	var placement: Variant = RadCells.placeCells(RadMachine.mItems(_machine).size())
	return placement.byIndex[_machine.highlight] if placement != null else RadCells.BACK_CELL


## Setting the highlight from outside is what the machine's own arrow keys do
## inside step(); doing it here keeps the cell layer out of the machine. The
## effect is shaped exactly as the machine shapes it, label and id included.
func _set_highlight(index: int) -> Array:
	if _machine.highlight == index:
		return []
	_machine.highlight = index
	var it: Dictionary = RadMachine.mItems(_machine)[index]
	var fx := [{ "t": "highlight", "i": index, "id": it.id, "label": str(it.get("label", "")) }]
	_emit(fx)
	return fx


func _dispatch(ev: Dictionary) -> Array:
	if _machine == null:
		return []
	var fx := RadMachine.step(_machine, ev)
	_emit(fx, ev.get("t", _stamp(-1)))
	return fx


func _emit(fx: Array, t: int = -1) -> void:
	for f in fx:
		match str(f.t):
			"commit":
				var item: Dictionary = f.item
				var context: Variant = _ctx
				_machine = null
				_ctx = null
				# Plain data: a verb, the context it applies to, the item id that
				# produced it, and when. Nothing here is a closure, which is what
				# lets a host serialize, queue, replay or send it over a wire.
				committed.emit({ "action": item.get("action", item.id), "context": context, "itemId": item.id, "t": t })
			"cancel":
				_machine = null
				_ctx = null
				cancelled.emit()
			"highlight":
				highlighted.emit(f.i, f.id, f.label)
			"open", "submenu", "back":
				ring_changed.emit()
		effect.emit(f)


func _stamp(t: int) -> int:
	return t if t >= 0 else Time.get_ticks_msec()
