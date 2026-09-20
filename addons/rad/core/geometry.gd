class_name RadGeometry
## rad core — geometry. Platform-free: no scene, input, display or engine API.
##
## A line-for-line port of the reference (rad `index.html`, the CORE block, at
## the commit `conformance/vectors.lock` names). Names are the reference's, not
## Godot's snake_case, so a grep aligns the cores; a rename is drift.

const GEOM := {
	"startDeg": -90.0, "clockwise": true, "r0": 36.0, "r1": 108.0,
	"cancelScale": 1.35, "longPressMs": 350.0, "slop": 10.0,
}

## Fitting the ring to a viewport. Contract §2: clamp by shifting the centre
## inward, never by shrinking below minimums; shrink r1 *toward* the band
## minimum when the viewport cannot hold it; centre on an axis whose clamp
## bounds invert rather than push the ring off the opposite edge.
const RING := { "bandMin": 56.0, "margin": 8.0, "topInset": 64.0, "bottomInset": 40.0 }


## The committing band, identical in both commit styles (contract §2/§3).
## Inward of r0 is the dead-zone cancel; outward of r_cancel is its mirror.
static func rCancel(g: Dictionary = GEOM) -> float:
	return g.r1 * g.cancelScale


static func inBand(r: float, g: Dictionary = GEOM) -> bool:
	return r > g.r0 and r <= rCancel(g)


static func fitRing(vw: float, vh: float, g: Dictionary = GEOM) -> Dictionary:
	var avail := minf(vw, vh) / 2.0 - RING.margin
	return { "r0": g.r0, "r1": maxf(g.r0 + RING.bandMin, minf(g.r1, avail)) }


static func clampRingCentre(x: float, y: float, vw: float, vh: float, r1: float) -> Dictionary:
	var m := r1 + 24.0
	return {
		"x": _axis(x, m, vw - m, vw),
		"y": _axis(y, maxf(m, RING.topInset), vh - m - RING.bottomInset, vh),
	}


static func _axis(v: float, lo: float, hi: float, extent: float) -> float:
	return extent / 2.0 if lo > hi else minf(maxf(v, lo), hi)


static func normDeg(d: float) -> float:
	return fmod(fmod(d, 360.0) + 360.0, 360.0)


static func angleToIndex(thetaDeg: float, n: int, startDeg: float = GEOM.startDeg) -> int:
	var rel := normDeg(thetaDeg - startDeg)
	return int(jsRound(rel / (360.0 / n))) % n


static func itemCenterDeg(i: int, n: int, startDeg: float = GEOM.startDeg) -> float:
	return startDeg + i * (360.0 / n)


## JavaScript's Math.round: halves go toward +infinity. GDScript's round()
## takes halves away from zero, which differs below zero, and the vectors are
## the reference's numbers.
static func jsRound(x: float) -> float:
	return floorf(x + 0.5)
