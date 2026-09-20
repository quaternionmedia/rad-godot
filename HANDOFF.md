# Handoff and retrospective

## Current state

Work stopped on 2026-09-19 at the user's request. No commit was created, and
no remote is configured.

The repository is on `master` with no commits. The current baseline is staged
and ready for an agent with the required Git permissions.

## Changes prepared

- Removed unused, unreferenced Godot boilerplate scripts under
  `Scripts/UI/` and `Scripts/Utils/`.
- Removed the unreferenced dialog scenes under `Scenes/dialogs/`.
- Added `README.md` describing the project, controls, layout, requirements, and
  how to run it.
- Expanded `.gitattributes` with explicit rules for Godot text formats,
  native addon binaries, and common binary assets.
- Staged the existing Godot project, scenes, assets, and the
  `godot-git-plugin` addon.

## Governance work not started

Integration with `quaternionmedia/qm` was researched but not applied. The QM
repository's authoritative adoption procedure is
`handbook/forking-a-project.md`; its required work includes:

1. Confirm the source and project commits.
2. Add QM as a submodule at `governance/qm`.
3. Create and push the permanent `project/moe` branch in the governance
   repository, including the seeded ADR directory.
4. Point the submodule at that branch and configure `.gitmodules`.
5. Copy and wire the required CI workflows.
6. Copy the IDE-integrated governance files while preserving symlinks.
7. Add the initial numberless project records.
8. Register any carried patches, if applicable.

## Recommended next steps

1. Review the staged diff, especially the deleted files and the new README.
2. Run the available Godot validation/import check.
3. Create the authorized initial commit, including the required
   `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
   trailer if applicable.
4. Configure the canonical remote and push the baseline.
5. Perform QM adoption from the authoritative handbook rather than copying
   only the abbreviated project guide.
6. Verify each adoption step with the checks documented by QM.

## Retrospective

The cleanup was intentionally limited to clearly unused scaffolding and
repository hygiene. The stub scripts and dialog scenes were not attached to
the main scene and had no references elsewhere, so removing them reduced
noise without changing the running project. The documentation and
`.gitattributes` additions improve handoff and cross-platform repository
behavior.

The governance integration was deliberately left untouched after the user
requested a stop. No attempt was made to create commits, configure remotes,
push branches, or alter the external `quaternionmedia/qm` repository.

---

## Session 2: the development loop

Stamped 2026-09-19. Tools: written with an AI coding assistant, reviewed and
committed by a human. Append a section for every session after this one and
do not rewrite an earlier session's.

### Where we are

- `master` has two signed commits and no remote: `46a1537` the baseline exactly
  as the previous section staged it, and `f8cfdcb` the development loop.
- The engine is pinned to `4.7.2-stable` in `.godot-version`. On this
  workstation that is the Steam build, which reports `4.7.2.stable.steam`.
- `tools/dev.ps1 check` is green: headless import with every declared artefact
  present, the engine's own parser on all five scripts, and the main scene run
  headless for thirty frames with nothing on stderr. `play` and `editor` exist
  and have not been exercised with a hand on the mouse.
- Every gate was broken and seen red before being trusted: a parse error in
  `main.gd` fails the parser step; a runtime error in `_ready` passes the
  parser and fails the smoke step on stderr, with the engine still exiting 0,
  which is why that step reads stderr; an imported artefact moved out of
  `.godot/imported/` fails `check_imports.py`; a wrong pin refuses to run.

### Two of the previous section's steps were not taken, on purpose

1. **No `Co-authored-by` trailer.** The organisation this project is adopting
   holds human-only contributorship (`records/DRAFT-human-only-contributorship.md`
   in `quaternionmedia/qm`): no tool, model or unmonitored address in any
   commit. The tool is disclosed in this file's `Tools:` line instead. Any
   future session should treat step 3's trailer as superseded by that record.
2. **No remote configured, nothing pushed.** `git@github.com:quaternionmedia/moe.git`
   already exists and is a different project: M.O.E., "Meticulous Oversight
   Engine", a Python and Docker web application last touched in 2022, with a
   local clone at `repos/qm/moe`. Pushing this baseline there would graft an
   unrelated history onto it. Whether this project takes a new name, or that
   repository is archived and renamed first, is the human's decision and
   blocks the remote, and therefore blocks QM adoption (which needs the
   repository's canonical name for `project/<name>`).

### Read in the code, left as found

Candidates for the first iterations of the loop. None was changed, because
each changes behaviour and the session had no human at the keyboard to say
which behaviour is wanted.

- `main.gd` `_input`: every key press, not only digits, is parsed as the type.
  `int("Shift")` is 0, so holding Shift to drag vertically also resets the
  current type to red. The README describes "hold a number key while
  clicking"; the code sets the type on press and keeps it.
- `main.gd` line 4: `DEPTH_DRAW_MODE_ALWAYS = 2`. In Godot 4,
  `BaseMaterial3D.DEPTH_DRAW_ALWAYS` is 1 and `DEPTH_DRAW_DISABLED` is 2. The
  constant is misnamed and the "workaround" comment suggests 2 was chosen for
  how it looked. Renaming it is safe; changing the value changes the look.
- `main.gd` `world_to_screen` reimplements `Camera3D.unproject_position` and
  `is_position_behind`. Replacing it is a simplification with a visible
  oracle: hover and click hit-testing must behave identically afterwards.
- `Graph` is a `Resource` holding untyped dictionaries and is never saved or
  loaded; the project has no persistence at all.
- The README listed `Resources/` and `Assets/` as holding themes and art. Both
  are empty and untracked, so those links were dead in any clone; the loop's
  commit drops them.

### What to distrust in this page

- "Green" means the scene ran thirty headless frames with no input. `_ready`
  and `_process` are exercised; not one click path is. A test framework (the
  sibling Godot project in this organisation vendors gdUnit4) is the next
  piece of the loop once there is a behaviour worth pinning.
- The previous section's "Changes prepared" cannot be diffed: there was no
  commit before the cleanup, so the deleted scaffolding left no trace. Its
  description is the only record of what was removed.

### Next

1. The human decides the repository's name (see above). Then the remote, the
   push, and QM adoption from `handbook/forking-a-project.md`, verified with
   the checks that handbook names.
2. First loop iteration with a human present: pick one item from "read in the
   code", change it, `tools/dev.ps1 check`, `tools/dev.ps1 play`, commit.

---

## Session 3: the project becomes rad-godot

Stamped 2026-09-19. Tools: written with an AI coding assistant, reviewed and
committed by a human.

### What changed, and why

The human named the project **rad-godot**: the Godot implementation of rad's
interaction contract, sibling to `rad-android`, whose purpose is a portable rad
menu (an addon) with the existing 3D graph scene as the host that demonstrates
node and graph manipulation through intents. The name collision noted in
session 2 is resolved by that decision rather than by a new remote for `moe`.

Established before writing anything, from the repositories rather than from
memory:

- The org's family record says a radial menu is substrate and belongs to no
  roster family. "The rad family" here is the set of implementations of one
  contract, and no roster family field is claimed.
- `rad-android`'s shape, read from the host: a pure core with the reference's
  names kept verbatim, a renderer, a demo host, a byte-exact copy of
  `conformance/vectors.json` locked to a rad commit by hash, and two DRAFT
  records (scope, architecture) with a milestone ladder. This repository
  mirrors that shape.
- rad's platform-plans record names this case as an expected revision
  trigger: a host on a platform it did not order.

In the tree at this session's commit:

- `project.godot` names the project `rad-godot`; the loop's editor guard
  matches the new window title.
- `conformance/vectors.json` is rad's file at commit `2c10fd1` on
  `origin/evolve/consolidate-rad`, byte-identical (same git blob);
  `conformance/vectors.lock` holds the full ref and the SHA-256;
  `tools/check_vector_pin.py` verifies it on every `check`. Seen red on one
  flipped byte in the file and on one edited digit in the lock.
- `tools/repo.py` is what the checks share (tracked files, hashing, the
  `OK:`/`FAIL:` grammar with the exit status as verdict); `check_imports.py`
  uses it now and later checks will.
- `docs/DRAFT-rad-godot-adoption-and-scope.md` and
  `docs/DRAFT-rad-godot-architecture.md`: the plan as records, drafted for a
  human to ratify. The scope record carries the ladder v0.0.0 → v0.1.0, the
  upstream triggers this repository knowingly trips, the open questions, and
  the one product change the human confirms: number-key typing is retired
  when the menu arrives, because digits are the menu's cell addresses and the
  contract forbids literal colours in intents.
- `README.md` rewritten for rad-godot. It describes the host as it stands
  today; the menu is not in the tree yet.
- The directory is renamed from `moe` to `rad-godot` after the commit; nothing
  in the tree depends on the path.

### Queue

- **B** — port the core: `addons/rad/core/*.gd` line for line from the
  reference (rad `index.html`, the block between the CORE banner and the
  generated vectors block, at the pinned commit), gdUnit4 vendored as in
  titanharvest, `tests/test_conformance.gd` replaying every vector,
  `tools/check_core_boundary.py`, `tools/dev.ps1 test`. Mutations to see red
  before believing green: `cancelScale` perturbed, `PLACEMENT` reordered, an
  input API reference in `core/`, one byte in the vector file. Claim: v0.0.1.
- **C** — session, renderer, input adapter (architecture record §4–§6).
- **D** — the host through a graph store and a resolver (§7).
- **E** — human: name confirmed, remote created, visibility chosen; then
  adoption per the org handbook or the lighter shape; a roster entry; the
  upstream proposals to rad.

### What to distrust in this page

- The two records are drafts written by the session that wrote the code they
  describe. Sections marked "from v0.0.1" describe tooling not yet in the tree.
- `vectors.lock` pins a commit on a rad branch that has no upstream tracking
  and may be merged or rebased; the hash is what holds, the ref is where to
  look.

---

## Session 4: the core replays the vectors

Stamped 2026-09-19. Tools: written with an AI coding assistant, reviewed and
committed by a human.

### In the tree

- `addons/rad/core/` — geometry, cells, time, chord, machine — ported line for
  line from rad `index.html` at the pinned commit, the block between the CORE
  banner and the generated vectors block, plus `CHORD_MAP`, `DIVS` and
  `TEMPO_RANGE` from further down because the vectors name them. Reference
  names kept verbatim. The core never logs: where the reference throws,
  `assertRing` returns the message and `createMachine` / `placeCells` return
  null.
- `addons/rad/conformance.gd` — the port of the reference's
  `runConformanceWith`, pure, reusable by a host that wants to show
  conformance in-scene the way the web reference does.
- `tests/test_conformance.gd` replays the whole file and names every failing
  case in one run; two tests beside it are the suite's own mutation (a wrong
  expected index, a wrong expected commit) and must stay red-capable.
  `tests/test_bootstrap.gd` refuses an engine that is not the pin.
- gdUnit4 vendored as titanharvest vendors it; `tools/dev.ps1 test` runs it
  headless after an import; `check` gains the core-boundary lint
  (`tools/check_core_boundary.py`) and parses `addons/rad/` scripts too.

### Verified, at this commit

`tools/dev.ps1 check` and `tools/dev.ps1 test` both green; the conformance
run prints the case count it replayed. Four mutations of the core, each seen
red on the case its record names, each restored: `cancelScale` perturbed →
the r_cancel boundary case; `PLACEMENT` reordered clockwise-from-top → the
placement, reachability and agreement cases; the hub-latch guard removed from
`move` → "latched hub press does not highlight while dragging out"; an
`Input` call in `core/` → the boundary lint.

Two things learned, both now in `dev.ps1` comments: a new `class_name` is
invisible to `--check-only` and to the test runner until the project has been
imported once, so both modes import first; and a headless runtime script error
leaves the exit code 0, so the smoke step reads stderr.

The v0.0.1 claim in the scope record is met by this tree. The tag is the
human's to cut.

### Queue

C (session, renderer, input adapter), D (host through a store and resolver),
E (remote, adoption) — unchanged from session 3. The directory is still
`Documents/moe`; renaming it to `rad-godot` waits on the other agent session
that holds the folder being closed.

---

## Session 5: the other Godot projects are tracked

Stamped 2026-09-19. Tools: written with an AI coding assistant, reviewed and
committed by a human.

The human asked that the effort to integrate the addon with the
organisation's other Godot projects — titanharvest and golfvs — be added and
tracked. It is:

- `docs/integrations.md` is the ledger: how any host consumes the addon
  (copy at a tag, lock by hash, its own resolver, one signal, one test in the
  host), one section per host with where the ring fits and where it does not,
  the milestone that first needs it, what blocks it on each side, its status,
  and the `[PROPOSED]` text its design document receives. A dated log closes
  it.
- The scope record gains §9 naming both hosts, a v0.0.5 rung for the first
  external host, and a split trigger worded for it.

Read from the hosts before writing, at their current heads: titanharvest's
ring is the tool swap in its verbs fork (`DESIGN.md` §5.2), first needed at
its M2; golfvs's is the defender's authoring surface (`DESIGN.md` §11.4,
`DefensePlan`), first needed at its M5, and expressly not the stroke, the club
selector or the first run, which that project has decided against menus for
(pillar 3, ADR-014, ADR-018 — checked on the head of its open pull request,
which carries ADR-020 to ADR-030 and changes none of that).

Nothing was put into either host. Both contributor slots are held by open
pull requests (titanharvest #2, golfvs #1), so the proposals wait in the
ledger, ready to paste, and the ledger says so. One question for rad upstream
came out of golfvs and is recorded there: whether an icon-only ring, with
labels only in the accessibility tree, is conformant.

### Queue

C, D, E unchanged. Add: when either host's slot frees, open the proposal
pull request the ledger holds for it and move its status to `proposed in
host`; raise the icon-only question in rad's records before golfvs reaches
M5.
