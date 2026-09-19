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
