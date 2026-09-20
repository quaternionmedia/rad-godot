class_name RadCells
## rad core — the nine cells, numbered as a numeric keypad, per rad's record
## "the menu addresses nine cells". Platform-free.
##
##     7 8 9        up-left    up    up-right
##     4 5 6   =    left      BACK   right
##     1 2 3        down-left  down  down-right
##
## A cell is an ADDRESS for an item, not a second geometry. `angleToIndex` is
## untouched and every polar vector still holds: an index identifies an item,
## and a cell identifies the same item by a name that does not move when the
## highlight does. Cardinal-first placement puts a four-item menu where the ring
## draws it; above four the two part company, and `cellAgreesWithRing` reports
## which case a host is in rather than leaving it to be assumed.

const BACK_CELL := 5
const PLACEMENT: Array[int] = [8, 6, 2, 4, 9, 3, 1, 7]
const CELL_XY := {
	7: Vector2i(0, 0), 8: Vector2i(1, 0), 9: Vector2i(2, 0),
	4: Vector2i(0, 1), 5: Vector2i(1, 1), 6: Vector2i(2, 1),
	1: Vector2i(0, 2), 2: Vector2i(1, 2), 3: Vector2i(2, 2),
}
const CELL_STEP := {
	"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0),
}
## The direction a cell means, in the contract's screen convention. The centre
## has no direction and is absent on purpose: asking for it is a bug.
const CELL_DEG := { 8: -90.0, 9: -45.0, 6: 0.0, 3: 45.0, 2: 90.0, 1: 135.0, 4: 180.0, 7: -135.0 }
## Keyed on the sorted pair, so up-then-left and left-then-up are one corner.
const CELL_DIAGONAL := { "left,up": 7, "right,up": 9, "down,left": 1, "down,right": 3 }


static func _xyCell(xy: Vector2i) -> int:
	for cell in CELL_XY:
		if CELL_XY[cell] == xy:
			return cell
	return -1


## Returns { byCell: {cell: index}, byIndex: [cell, ...] }, or null where the
## reference throws: more items than the grid has cells around its centre.
## The core never logs; a null here is the caller's to report.
static func placeCells(n: int) -> Variant:
	if n > PLACEMENT.size():
		return null   # will not fit: the grid holds eight around a centre that always backs out
	var chosen := PLACEMENT.slice(0, n)
	var byCell := {}
	for i in chosen.size():
		byCell[chosen[i]] = i
	return { "byCell": byCell, "byIndex": chosen }


## One press of a direction, as a step on the grid. Movement stops at the edge
## rather than wrapping: a ring wraps because it has no ends, a grid has
## corners, and a cursor that leaps between columns must be watched rather than
## predicted.
static func cellStep(cell: int, dir: String) -> int:
	if not CELL_STEP.has(dir):
		return cell
	var d: Vector2i = CELL_STEP[dir]
	var xy: Vector2i = CELL_XY[cell]
	return _xyCell(Vector2i(clampi(xy.x + d.x, 0, 2), clampi(xy.y + d.y, 0, 2)))


## The diagonal two directions name together, or null. Order does not matter.
static func cellChord(a: String, b: String) -> Variant:
	var pair := [a, b]
	pair.sort()
	var key := "%s,%s" % pair
	return CELL_DIAGONAL[key] if CELL_DIAGONAL.has(key) else null


## The item nearest the pressed direction, NOT a walk along the row.
##
## A menu of four sits at the cardinals, so walking left from 8 passes through
## the empty corner 7 and reaches the edge without ever turning down — which
## leaves cell 4 unreachable by arrows in the commonest menu size there is.
## That defect is why the record states reachability as a clause, and why this
## scores every occupied cell instead of stepping. Cells behind the cursor are
## never chosen: pressing left may not move you right, however close something
## is. The centre is never a candidate; it is reached by pressing 5.
static func cellStepToItem(cell: int, dir: String, placement: Dictionary, allowed: Variant = null) -> int:
	if not CELL_STEP.has(dir):
		return cell
	var d: Vector2i = CELL_STEP[dir]
	var c: Vector2i = CELL_XY[cell]
	var best := cell
	var bestScore: Variant = null
	for cand in placement.byCell:
		if cand == cell or cand == BACK_CELL:
			continue
		if allowed != null and not (allowed as Array).has(cand):
			continue
		var xy: Vector2i = CELL_XY[cand]
		var along := (xy.x - c.x) * d.x + (xy.y - c.y) * d.y
		if along <= 0:
			continue
		var across := absi((xy.x - c.x) * d.y - (xy.y - c.y) * d.x)
		var score := [along, -across]
		if bestScore == null or score[0] > bestScore[0] or (score[0] == bestScore[0] and score[1] > bestScore[1]):
			best = cand
			bestScore = score
	return best


## Whether every item's cell points where the ring draws it, at this size.
## True at n<=4 and false above it — see the class comment.
static func cellAgreesWithRing(n: int, startDeg: float = RadGeometry.GEOM.startDeg) -> bool:
	var placement: Variant = placeCells(n)
	if placement == null:
		return false
	var byIndex: Array = placement.byIndex
	for i in byIndex.size():
		var cell: int = byIndex[i]
		if absf(_wrap(_wrap(RadGeometry.itemCenterDeg(i, n, startDeg)) - CELL_DEG[cell])) >= 1e-9:
			return false
	return true


static func _wrap(d: float) -> float:
	return fmod(fmod(d, 360.0) + 540.0, 360.0) - 180.0
