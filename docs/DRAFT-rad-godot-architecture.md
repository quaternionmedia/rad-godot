# DRAFT — rad-godot architecture

| | |
|---|---|
| **Status** | Draft |
| **Date** | 2026-09-19 |
| **Pends on** | DRAFT-rad-godot-adoption-and-scope; rad platform plans; rad interaction contract §2–§3; the menu addresses nine cells §5 |
| **Principle** | `seams-on-standard-protocols`; `minimal-legible-deliverables` |

## 1. Modules

```
addons/rad/                     the portable menu; copy the directory, provide a resolver, connect one signal
  core/geometry.gd              GEOM, RING, rCancel, inBand, fitRing, clampRingCentre, normDeg, angleToIndex, itemCenterDeg
  core/cells.gd                 BACK_CELL, PLACEMENT, CELL_XY, CELL_STEP, CELL_DEG, CELL_DIAGONAL,
                                placeCells, cellStep, cellChord, cellStepToItem, cellAgreesWithRing
  core/time.gd                  TIME, DIVS, medianOf, estimateBpm, quantizeTime, apsFromTempo, ccToRange, ccToDiv
  core/chord.gd                 splitBursts, classifyBurst, prefixCollisions
  core/machine.gd               MAX_ITEMS, assertRing, createMachine, step
  session.gd                    RadSession — owns one machine state; pointer, key and cell entry points; signals
  ui/rad_invoker.gd             Node — right-click, long-press with slop, or a key: emits where and in which mode
  ui/rad_menu.gd                Control — draws the ring, fits it to the viewport, routes input to the session
  ui/rad_theme.gd               Resource — rad's theme tokens as Colors
Scenes/                         the host: graph store, resolver, visuals
conformance/                    vectors.json (copied) + vectors.lock (rad ref + sha256)
tests/                          gdUnit4 suites: bootstrap, conformance, session, resolver, store
tools/                          dev.ps1 and the checks it runs; repo.py is what they share
```

**Port names stay identical to the reference**, as `rad-android` requires of
its Kotlin core: `angleToIndex`, `createMachine`, `step`, `rCancel`, `inBand`,
`fitRing`, `clampRingCentre`, `placeCells`, `cellStepToItem`,
`cellAgreesWithRing`, `estimateBpm`, `quantizeTime`, `apsFromTempo`,
`ccToRange`, `ccToDiv`, `classifyBurst`, `splitBursts`, `assertRing`. Inside
`core/` this overrides Godot's snake_case convention on purpose: a grep aligns
the three cores line by line, and a rename is drift. Everything outside
`core/` is idiomatic Godot.

Core scripts are `class_name` scripts of `static func`s over plain
`Dictionary` and `Array` values. Machine state carries the reference's keys —
`geom`, `status`, `mode`, `stack`, `highlight`, `pressIndex`, `opened`,
`committed`, `cancelled` — and an effect is a `Dictionary` whose `t` is one of
`highlight | commit | cancel | submenu | back | open`, with `highlight`
carrying `i`, `id` and `label` as the contract's effect clause requires.

**The one semantic the language cannot mirror.** The reference raises on a
ring of zero or more than eight items. GDScript has no exceptions, so
`assertRing` returns an error string (empty on success) and `createMachine`
returns `null`. The core never logs — it returns verdicts and the session
above it reports — because an engine error raised inside the case that
expects the refusal would read as a test error. The replayer reads a vector's
`expectThrows` as "returned null". Nothing else in the port departs from the
reference's control flow.

## 2. Conformance

`conformance/vectors.json` is a byte-exact copy of rad's, taken from the commit
`vectors.lock` names. `tests/test_conformance.gd` loads it at run time and
dispatches on the same keys as the reference's `runConformanceWith`: `fit`,
`clamp`, `ceiling`, `vocab`, `aps`, `cc`, `ccdiv`, `grid`, `quant`, `tempo`,
`chord`, `split`, `cells`, `pure`, and a trace when none of those is present.
Traces build their items as `{id: "i" + k, label: "i" + k}`, read the committed
index back as `int(id.substr(1))`, collect highlight effects edge-triggered
and compare `expectLabels` when a case carries them; a case's `geom` block is
merged over `GEOM` for that machine only. Every failure is collected as
`[name, why]` and the suite asserts the list is empty, so one run names every
failing vector rather than the first.

JSON numbers arrive in GDScript as floats. Indices, cells and counts are
compared as integers explicitly, and the first green run of the suite is
checked against a deliberately wrong expected index before it is believed.

## 3. Vector pinning

`vectors.lock` holds `rad_ref` (the full commit in `quaternionmedia/rad`) and
`sha256` (of the copied bytes). `tools/check_vector_pin.py` recomputes the hash
on every `tools/dev.ps1 check` and refuses a mismatch; it prints the version
and hash prefix a release claim quotes. Upgrading the pin is one reviewed
change to both files, never a side effect. The `.gitattributes` rule that
normalises line endings does not touch this file's bytes because it is
committed with LF and the hash is taken over what git stores.

Rejected: a submodule of `rad` (the seam is one JSON file; the reference is a
few thousand lines and its media), and a fetched artefact (one consumer per
platform, publishing taxes every core edit — rejected upstream for the same
reason).

## 4. The session and the cells

The machine's `step()` is a verbatim port and takes the events the reference
takes: `down`, `longpress`, `move`, `up`, `open`, `key`, `close`. The nine-cells
record's keyboard clauses — a digit chooses its cell, a direction moves to the
nearest item in that direction, `5` backs out — live **above** the machine in
`RadSession`, exactly as the terminal implementation in `dossier` places them:

- `press_cell(d)`: `5` calls `back`; otherwise look the cell up in
  `placeCells(n).byCell`, refuse an empty or disabled cell without a
  transition, else set `highlight` to that index, emit the highlight effect,
  and step `key Enter`.
- `move_cell(dir)`: `cellStepToItem(current_cell, dir, placement, enabled_cells)`
  → set the highlight to the item there and emit its highlight effect.
- Two directions inside a short window resolve through `cellChord` to the
  corner between them; the movement route reaches the same corner without a
  clock.

Setting the highlight directly is what the reference's own `key` arrows do
inside `step()`; the session does it from outside so that no new event type
enters the machine and the vectors keep describing it completely.

`RadSession` signals: `highlighted(i, id, label)`, `committed(intent)`,
`cancelled()`, `ring_changed()`, and `effect(fx)` for a host that meters. An
intent is the contract's dictionary — `action`, `context`, `itemId`, `t` — and
is the only value that leaves the addon. `action` defaults to the item's `id`
when a resolver gives none.

## 5. Input adapter

Two nodes, one path each, split where the reference splits it: the host owns
invocation (it alone knows what is under the point), the menu owns everything
after the ring is up.

`ui/rad_invoker.gd` (`RadInvoker`, a Node the host adds) listens on
`_unhandled_input` while nothing is open and emits `invoke(screen_pos, mode)`:

- Secondary button press, or the `m` key → mode `idle` (tap-select) at the
  pointer.
- Primary press or touch arms a `SceneTreeTimer` of `GEOM.longPressMs`; motion
  beyond `GEOM.slop` units before it fires disarms it (slop lives here and
  never in `step()`, as the contract states); the timer firing with the same
  press still down → mode `tracking` (release-select). A serial number ties
  the timer to the press that armed it.

`ui/rad_menu.gd` (`RadMenu`, a full-rect Control under a CanvasLayer) is
invisible with `mouse_filter = IGNORE` while closed, and on `open_at` becomes
visible, sets `mouse_filter = STOP` and takes focus, so the host stops seeing
motion the menu owns. Its `_gui_input`:

- Motion → `move` with `r` and `thetaDeg` computed from the ring centre, in
  the contract's convention: `thetaDeg = rad_to_deg(atan2(dy, dx))`, so up is
  −90 and clockwise is positive in screen space. Button and touch press →
  `down`, release → `up`.
- Enter and Escape → the machine's `key`. **Arrows → `move_cell`**, the
  nine-cells record's direction route (nearest item in that direction, never a
  walk along the row); **digits and keypad digits → `press_cell`**, with `5`
  backing out; **Tab and Shift+Tab → the machine's `ArrowRight`/`ArrowLeft`**,
  so the contract's rotate-and-commit path is also bound. At four items the
  arrows and the rotation land in the same places; above four they do not,
  and both are available on purpose.

Density: one contract unit is one pixel times the window's
`content_scale_factor`, so `r0`, `r1` and the 44-unit target hold on a scaled
display. The ring is fitted per opening with `fitRing(viewport)` and its
centre with `clampRingCentre`, and the fitted geometry is what the machine is
created with — the contract's "the machine judges the ring it was opened with".

## 6. Rendering

Hub, wedges and labels are drawn in `_draw()`: each wedge a filled sector
between `r0` and `r1` centred on `itemCenterDeg(i, n)` spanning `±180/n` with
a small angular gap; the highlighted wedge in the accent token; a disabled
wedge in the muted token; the label at mid-band, at most twelve characters
(the resolver shortens, the renderer never ellipsizes); a submenu's title in
the hub. Cell digits are drawn as small badges only when
`cellAgreesWithRing(n)` is true — the host is a ring host and, per the
nine-cells record, does not announce two placements at once. Colours come only
from `rad_theme.gd` tokens; no literal colour appears in the addon.

## 7. Host wiring

The menu holds no reference to the graph. The host provides a resolver —
`resolve(context) -> MenuSpec` — when it opens the menu, and connects
`committed(intent)` to its `GraphStore`, which owns nodes, edges and selection
and applies one command per action string in the contract's standard
vocabulary. Visuals rebuild from the store's `changed` signal. Nothing in the
scene mutates a node or edge except through the store, which is the contract's
"the menu never mutates the scene" carried one layer further.

## 8. Loop and checks

`tools/dev.ps1 check`: headless import → imported artefacts present → vector
pin → the engine's parser on every tracked script outside `addons/` → the
core-boundary lint (from v0.0.1) → the main scene headless for a few frames with stderr read
for `SCRIPT ERROR:` lines (the engine exits 0 on a runtime script error).
`tools/dev.ps1 test` (from v0.0.1): gdUnit4 headless, the invocation the org's
other Godot project uses. Every check under `tools/` imports `tools/repo.py` for tracked-
file listing, hashing and the `OK:`/`FAIL:` grammar, and its exit status is
the verdict.

The core-boundary lint, `tools/check_core_boundary.py` (from v0.0.1), fails on
any line of
`addons/rad/core/*.gd` matching

    \b(Node|Input|Viewport|DisplayServer|SceneTree|get_tree|get_node|OS|Engine)\b|\$[A-Za-z_]|\b(pre)?load\(

which is the Godot reading of "no DOM, no `android.*`": the core may not touch
the scene tree, input, the display, the OS or resource loading.

## Alternatives considered

- **Extend `step()` with a `cell` event.** One machine for everything, and the
  vectors would no longer describe it completely. Rejected in favour of the
  session layer the terminal port already proved.
- **C# for the core.** Exceptions and a static type system that mirrors the
  Kotlin port more closely. Rejected: it adds a .NET toolchain to a GDScript
  project and to every host that copies the addon; the throw-to-null mapping
  is one sentence.
- **A bespoke headless test runner instead of gdUnit4.** Fewer bytes in the
  tree. Rejected for now: the sibling Godot project's harness, CI recipe and
  its known headless quirks are already paid for; a replayer is one suite in
  it.

## Revision triggers

- The vector schema gains a key — extend the replayer with the pin bump.
- The engine's accessibility layer cannot label a hand-drawn wedge — wedges
  become child controls, and this record's §6 is rewritten.
- A second Godot host copies the addon — the split in the scope record.
- `step()` needs a change to pass a vector — that is a contract question and
  goes upstream before any line here moves.

## Amendments

*(none)*
