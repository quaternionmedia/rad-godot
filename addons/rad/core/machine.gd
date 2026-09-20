class_name RadMachine
## rad core — the state machine. Platform-free.
##
## Reducer-style: step(state, ev) mutates the state Dictionary and returns the
## effects. ev: {type: down|longpress|move|up|open|key|close, r, thetaDeg, key}.
## Effects: {t: highlight, i, id, label} {t: commit, item} {t: cancel}
##          {t: submenu, item} {t: back} {t: open}
##
## The reference raises where a ring is malformed; GDScript has no exceptions,
## so assertRing returns the message (empty when the ring is fine) and
## createMachine returns null. The core never logs: it returns verdicts, and
## the session above it reports. That is the one departure from the
## reference's control flow, and the conformance replayer reads a vector's
## expectThrows as "returned null".

const MAX_ITEMS := 8   # contract §1; the resolver enforces it


## Contract §1: at most 8 items per ring, and the resolver enforces it rather
## than a reviewer noticing. Checked here so submenu rings are covered too —
## overflow is a design error, and thinner-than-44-unit wedges are what it
## silently produces.
static func assertRing(items: Variant, where: String) -> String:
	if not (items is Array) or (items as Array).size() < 1:
		return "rad: %s ring must hold at least one item" % where
	if (items as Array).size() > MAX_ITEMS:
		return "rad: %s ring has %d items, contract §1 caps a ring at %d — group into a submenu" % [where, (items as Array).size(), MAX_ITEMS]
	return ""


## The machine carries the geometry it was opened with. Reading a module global
## made the committing band a property of the page rather than of the menu, so
## a ring fitted to a small viewport would have been drawn at one radius and
## judged at another.
static func createMachine(spec: Dictionary, geom: Dictionary = RadGeometry.GEOM) -> Variant:
	if assertRing(spec.get("items"), str(spec.get("title", "")) if spec.get("title") else "root") != "":
		return null
	return {
		"geom": geom,
		"status": "closed",          # closed | pending | open
		"mode": null,                # 'tracking' (release-select) | 'idle' (tap-select)
		"stack": [spec],             # submenu stack; top = current MenuSpec
		"highlight": null,
		"pressIndex": null,
		"opened": false, "committed": null, "cancelled": false,
	}


static func mItems(s: Dictionary) -> Array:
	return s.stack[-1].items


static func step(s: Dictionary, ev: Dictionary) -> Array:
	var fx := []
	var items := mItems(s)
	var n := items.size()
	var g: Dictionary = s.geom if s.get("geom") != null else RadGeometry.GEOM

	match str(ev.type):
		"open":                     # explicit open -> tap-select mode
			s.status = "open"; s.mode = "idle"; s.opened = true; fx.append({ "t": "open" })

		"down":
			if s.status == "closed":
				s.status = "pending"
			elif s.status == "open" and s.mode == "idle":
				if ev.r <= g.r0:
					s.pressIndex = "hub"    # latch the back/cancel affordance
				elif _beyond(ev.r, g):
					_close(s, fx, true)
				else:
					s.pressIndex = RadGeometry.angleToIndex(ev.thetaDeg, n)
					_setHl(s, fx, items, s.pressIndex)

		"longpress":                # pending press matured -> release-select mode
			if s.status == "pending":
				s.status = "open"; s.mode = "tracking"; s.opened = true; fx.append({ "t": "open" })

		"move":
			if s.status != "open":
				pass
			# A latched hub press can no longer commit a wedge, so it must not
			# highlight one: a highlight that cannot commit is the interface lying
			# about its own next state, and it fires a haptic for a non-event.
			elif s.pressIndex is String and s.pressIndex == "hub":
				pass
			elif RadGeometry.inBand(ev.r, g):
				var i := RadGeometry.angleToIndex(ev.thetaDeg, n)
				_setHl(s, fx, items, i)
				# drag-through submenu entry (release-select only)
				if s.mode == "tracking" and ev.r > g.r1 + 12 and i < n and _hasChildren(items[i]):
					_enterSub(s, fx, items[i])
			else:
				_setHl(s, fx, items, null)   # inside the dead zone, or beyond r_cancel

		"up":
			if s.status == "pending":
				_close(s, fx, true)            # short press: never opened
			elif s.status != "open":
				pass
			elif s.mode == "tracking":
				if RadGeometry.inBand(ev.r, g) and s.highlight != null:
					_commit(s, fx, items[s.highlight])
				else:
					_close(s, fx, true)        # dead zone or beyond r_cancel
			else:                              # idle / tap-select
				if s.pressIndex is String and s.pressIndex == "hub":
					s.pressIndex = null
					_back(s, fx)
				else:
					if s.pressIndex != null and RadGeometry.inBand(ev.r, g) \
							and RadGeometry.angleToIndex(ev.thetaDeg, n) == s.pressIndex:
						_commit(s, fx, items[s.pressIndex])
					s.pressIndex = null

		"key":
			if s.status != "open":
				pass
			elif ev.key == "ArrowRight" or ev.key == "ArrowDown":
				_setHl(s, fx, items, 0 if s.highlight == null else (s.highlight + 1) % n)
			elif ev.key == "ArrowLeft" or ev.key == "ArrowUp":
				_setHl(s, fx, items, n - 1 if s.highlight == null else (s.highlight - 1 + n) % n)
			elif ev.key == "Enter":
				if s.highlight != null:
					_commit(s, fx, items[s.highlight])
			elif ev.key == "Escape":
				_back(s, fx)

		"close":
			_close(s, fx, true)
	return fx


## A highlight effect carries the resolved label and id, not just an index
## (contract §3). A batch can replace the ring — `submenu` does — so an index
## alone is ambiguous by the time the consumer reads it: it names the ring
## that was current when the effect was emitted, and the consumer sees the
## ring that is current after the whole batch.
static func _setHl(s: Dictionary, fx: Array, items: Array, i: Variant) -> void:
	if i == s.highlight:
		return
	s.highlight = i
	var it: Variant = null if i == null else items[i]
	var label: Variant = it.get("label") if it != null else null
	fx.append({ "t": "highlight", "i": i, "id": it.id if it != null else null, "label": str(label) if label != null else "" })


static func _beyond(r: float, g: Dictionary) -> bool:
	return r > RadGeometry.rCancel(g)


static func _hasChildren(item: Dictionary) -> bool:
	return item.get("children") != null


static func _enterSub(st: Dictionary, fx2: Array, item: Dictionary) -> void:
	if assertRing(item.get("children"), str(item.label) if item.get("label") else str(item.id)) != "":
		# The reference throws out of step() here. A malformed submenu is a
		# resolver bug the ceiling check exists to catch before it reaches the
		# machine; refusing to enter it is the closest a language without
		# exceptions comes to the same outcome, and no vector reaches this.
		return
	st.stack.append({ "items": item.children, "title": item.get("label") })
	st.highlight = null; st.pressIndex = null
	fx2.append({ "t": "submenu", "item": item })


static func _back(st: Dictionary, fx2: Array) -> void:
	if st.stack.size() > 1:
		st.stack.pop_back(); st.highlight = null; fx2.append({ "t": "back" })
	else:
		_close(st, fx2, true)


static func _commit(st: Dictionary, fx2: Array, item: Variant) -> void:
	if item == null or item.get("enabled", true) == false:
		_close(st, fx2, true)
		return
	if _hasChildren(item):
		_enterSub(st, fx2, item)
		if st.mode == "tracking":
			st.mode = "idle"
		return
	st.committed = item; st.status = "closed"
	fx2.append({ "t": "commit", "item": item })


static func _close(st: Dictionary, fx2: Array, cancelled: bool) -> void:
	st.status = "closed"; st.cancelled = cancelled; st.highlight = null
	fx2.append({ "t": "cancel" })
