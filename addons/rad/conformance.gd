class_name RadConformance
## Replays rad's conformance vectors against this core. A port of the
## reference's runConformanceWith, case for case, so that the same JSON file is
## the oracle on every platform. Pure: takes the parsed vector file, returns
## one {name, pass, why} per case. Callers decide what to do with a failure.
##
## JSON numbers arrive as floats. Indices, cells and counts are compared as
## integers explicitly, through _i / _ints, and nowhere else.

const EPS := 1e-9


static func run(V: Dictionary) -> Array:
	var results := []
	for c in V.cases:
		var r: Array = _case(c)
		results.append({ "name": c.name, "pass": r[0], "why": r[1] })
	return results


static func failures(V: Dictionary) -> Array:
	var out := []
	for r in run(V):
		if not r.pass:
			out.append("%s — %s" % [r.name, r.why])
	return out


static func _case(c: Dictionary) -> Array:
	if c.has("fit"):
		for k in c.fit:
			var got: float = RadGeometry.fitRing(k.vw, k.vh).r1
			if absf(got - k.expectR1) > EPS:
				return [false, "%sx%s → r1 %s, want %s" % [k.vw, k.vh, got, k.expectR1]]
	elif c.has("clamp"):
		for k in c.clamp:
			var got := RadGeometry.clampRingCentre(k.x, k.y, k.vw, k.vh, k.r1)
			if absf(got.x - k.expectX) > EPS or absf(got.y - k.expectY) > EPS:
				return [false, "(%s,%s) in %sx%s r1=%s → (%s,%s), want (%s,%s)" % [k.x, k.y, k.vw, k.vh, k.r1, got.x, got.y, k.expectX, k.expectY]]
	elif c.has("ceiling"):
		for k in c.ceiling:
			var threw := RadMachine.createMachine({ "items": _items(_i(k.n)) }) == null
			if threw != bool(k.expectThrows):
				return [false, "n=%s threw %s" % [k.n, threw]]
	elif c.has("vocab"):
		var words: Array = c.vocab.words if c.vocab.has("words") else RadChord.CHORD_MAP.keys()
		var cols := RadChord.prefixCollisions(words)
		if cols.is_empty() != bool(c.vocab.expectPrefixFree):
			return [false, "collisions %s" % JSON.stringify(cols)]
		if c.vocab.has("expectCollisions") and cols != Array(c.vocab.expectCollisions):
			return [false, "collisions %s" % JSON.stringify(cols)]
	elif c.has("aps"):
		for k in c.aps:
			var got := RadTime.apsFromTempo(k.bpm, k.div)
			if absf(got - k.expectAps) > EPS:
				return [false, "bpm=%s div=%s → %s" % [k.bpm, k.div, got]]
	elif c.has("cc"):
		for k in c.cc:
			var got := RadTime.ccToRange(k.cc, k.lo, k.hi)
			if absf(got - k.expect) > EPS:
				return [false, "cc=%s → %s, want %s" % [k.cc, got, k.expect]]
	elif c.has("ccdiv"):
		for k in c.ccdiv:
			var got := RadTime.ccToDiv(k.cc)
			if got != float(k.expect):
				return [false, "cc=%s → %s, want %s" % [k.cc, got, k.expect]]
	elif c.has("grid"):
		for k in c.grid:
			var got: float = (60000.0 / k.bpm) / k.div
			if absf(got - k.expectMs) > EPS:
				return [false, "bpm=%s div=%s → %sms" % [k.bpm, k.div, got]]
	elif c.has("quant"):
		for q in c.quant:
			var got := RadTime.quantizeTime(q.t, q.phase, q.period, q.policy)
			if absf(got - q.expectT) > 1e-6:
				return [false, "t=%s → %s, want %s" % [q.t, got, q.expectT]]
	elif c.has("tempo"):
		var times := []
		var t := 1000.0
		for p in c.tempo.periods:
			times.append(t)
			t += p
		if not (c.tempo.periods as Array).is_empty():
			times.append(t)
		var got: Variant = RadTime.estimateBpm(times)
		var bad: bool = (got != null) if c.tempo.expectBpm == null else (got == null or absf(got - c.tempo.expectBpm) > c.tempo.tol)
		if bad:
			return [false, "bpm %s" % [got]]
	elif c.has("chord"):
		var r := RadChord.classifyBurst(c.chord.evts)
		if r.word != c.chord.expectWord or r.chorded != bool(c.chord.expectChorded):
			return [false, "%s/%s" % [r.word, r.chorded]]
	elif c.has("split"):
		var words := []
		for b in RadChord.splitBursts(c.split.evts):
			var w := ""
			for e in b:
				w += str(e.k)
			words.append(w)
		if words != Array(c.split.expectWords):
			return [false, JSON.stringify(words)]
	elif c.has("cells"):
		return _cells(c)
	elif c.has("pure"):
		for p in c.pure:
			var got := RadGeometry.angleToIndex(p.thetaDeg, _i(c.n))
			if got != _i(p.expectIndex):
				return [false, "θ=%s → %s, want %s" % [p.thetaDeg, got, p.expectIndex]]
	else:
		return _trace(c)
	return [true, ""]


static func _cells(c: Dictionary) -> Array:
	for k in c.cells:
		if k.has("place"):
			var got: Variant = RadCells.placeCells(_i(k.place))
			var threw := got == null
			if threw != bool(k.get("expectThrows", false)):
				return [false, "place %s threw %s" % [k.place, threw]]
			if not threw and Array(got.byIndex) != _ints(k.expectCells):
				return [false, "place %s → %s" % [k.place, JSON.stringify(got.byIndex)]]
		elif k.has("step"):
			var got := RadCells.cellStep(_i(k.from), k.step)
			if got != _i(k.expectCell):
				return [false, "%s %s → %s, want %s" % [k.from, k.step, got, k.expectCell]]
		elif k.has("toItem"):
			var allowed: Variant = _ints(k.allowed) if k.has("allowed") and k.allowed != null else null
			var got := RadCells.cellStepToItem(_i(k.from), k.toItem, RadCells.placeCells(_i(k.n)), allowed)
			if got != _i(k.expectCell):
				return [false, "n=%s %s %s → %s, want %s" % [k.n, k.from, k.toItem, got, k.expectCell]]
		elif k.has("chord"):
			var got: Variant = RadCells.cellChord(k.chord[0], k.chord[1])
			if _i(got) != _i(k.expectCell):
				return [false, "%s+%s → %s, want %s" % [k.chord[0], k.chord[1], got, k.expectCell]]
		elif k.has("agreesWithRing"):
			var got := RadCells.cellAgreesWithRing(_i(k.agreesWithRing))
			if got != bool(k.expectAgrees):
				return [false, "n=%s agrees %s" % [k.agreesWithRing, got]]
		elif k.has("centre"):
			var held: Array = RadCells.placeCells(_i(k.centre)).byCell.keys()
			if held.has(RadCells.BACK_CELL):
				return [false, "n=%s placed an item in the centre" % k.centre]
	return [true, ""]


static func _trace(c: Dictionary) -> Array:
	var geom := RadGeometry.GEOM.duplicate()
	if c.has("geom"):
		geom.merge(c.geom, true)
	var st: Variant = RadMachine.createMachine({ "items": _items(_i(c.n)) }, geom)
	if st == null:
		return [false, "createMachine refused n=%s" % c.n]
	var hl := []
	var labels := []
	for ev in c.trace:
		for f in RadMachine.step(st, ev):
			if f.t == "highlight":
				hl.append(_i(f.i))
				if f.i != null:
					labels.append(f.label)
	var e: Dictionary = c.expect
	var committedIdx: Variant = int(str(st.committed.id).substr(1)) if st.committed != null else null
	if hl != _ints(c.expectHighlights):
		return [false, "highlights %s" % JSON.stringify(hl)]
	if c.has("expectLabels") and labels != Array(c.expectLabels):
		return [false, "labels %s" % JSON.stringify(labels)]
	if committedIdx != _i(e.committed):
		return [false, "committed %s" % [committedIdx]]
	if st.cancelled != bool(e.cancelled):
		return [false, "cancelled %s" % st.cancelled]
	if e.has("opened") and st.opened != bool(e.opened):
		return [false, "opened %s" % st.opened]
	if e.get("stillOpen", false) and st.status != "open":
		return [false, "status %s" % st.status]
	return [true, ""]


static func _items(n: int) -> Array:
	var items := []
	for i in n:
		items.append({ "id": "i%d" % i, "label": "i%d" % i })
	return items


static func _i(v: Variant) -> Variant:
	return null if v == null else int(v)


static func _ints(arr: Variant) -> Array:
	var out := []
	for v in arr:
		out.append(_i(v))
	return out
