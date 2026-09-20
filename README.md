# rad-godot

The Godot implementation of [rad](https://github.com/quaternionmedia/rad), QM's
radial menu: a platform-neutral interaction contract with executable
conformance vectors, implemented natively per platform. `rad` holds the
contract, the vectors and the web reference; `rad-android` is the Kotlin and
Compose implementation; this repository is the Godot one. The three share a
contract and one JSON file, and no code.

Two things live here, on purpose in one repository until a second host wants
the first:

- **`addons/rad/`** — the portable menu. A Godot addon any project copies in:
  a pure core (geometry, the nine cells, time, chords, the state machine) that
  replays rad's vectors, a session above it, and a renderer. It holds no
  reference to a host; it emits intents.
- **The graph scene** — the demonstration host. A Godot 4 (Mobile renderer)
  scene for building a graph in 3D space, where every node, edge, canvas and
  selection action is a rad intent routed through the graph's own state.

## Status

The core is in the tree and replays every one of rad's vectors green; the
session, renderer and host wiring are not yet. What each tag claims, in order,
is the ladder in
[docs/DRAFT-rad-godot-adoption-and-scope.md](docs/DRAFT-rad-godot-adoption-and-scope.md).
The vectors are already pinned: [conformance/vectors.json](conformance/vectors.json)
is a byte-exact copy of rad's, and [conformance/vectors.lock](conformance/vectors.lock)
names the rad commit and the hash `tools/dev.ps1 check` verifies on every run.

## The host today

The graph editor as it stood before the menu, kept running while the addon is
built beside it:

- **Left click** on the ground creates a node; click-drag an existing node
  moves it (hold **Shift** to move it vertically).
- **Right click** a node to select it, then right click another to connect
  them with an edge.
- A **number key (0–9)** sets the type (colour) of the next node or edge.
  This is retired when the menu arrives: digits become the menu's cell
  addresses and colour becomes a `color:<token>` intent (scope record,
  decision on the host).

## Project layout

- [`addons/rad/core/`](addons/rad/core) — the pure core: geometry, the nine
  cells, time, chords, the state machine, with the reference's names kept
  verbatim; [`addons/rad/conformance.gd`](addons/rad/conformance.gd) replays
  the vectors against it.
- [`tests/`](tests) — gdUnit4 suites: the engine pin, and every vector.
- [`conformance/`](conformance) — rad's vectors and their lock.
- [`docs/`](docs) — the scope and architecture records, drafted here and
  ratified by a human, and [`docs/integrations.md`](docs/integrations.md),
  the ledger of the addon's way into the organisation's other Godot projects
  (titanharvest, golfvs).
- [`Scenes/`](Scenes) — the host: `main.tscn`/`main.gd`, the orbiting camera,
  and the `Graph`/`NodeVisual`/`EdgeVisual` classes.
- [`addons/godot-git-plugin/`](addons/godot-git-plugin) — third-party editor
  plugin.
- [`tools/`](tools) — the development loop and its checks.

## Requirements

- [Godot Engine](https://godotengine.org/) at the version pinned in
  [`.godot-version`](.godot-version). The loop below refuses any other.

## Running

Open `project.godot` in the Godot editor and run the project (F5), or run it
from the command line:

```sh
godot --path .
```

## Development loop

[`tools/dev.ps1`](tools/dev.ps1) is the local loop, on the pinned engine and
nothing else:

```powershell
tools/dev.ps1 check            # import, vector pin, core boundary, the engine's parser on every script, a headless smoke run
tools/dev.ps1 test             # the gdUnit4 suites, headless: engine pin and every vector
tools/dev.ps1 play -Frames 60  # run the main scene windowed, quit after 60 frames
tools/dev.ps1 editor           # open the editor, refusing if one already has the project
```

`check` reads the smoke run's stderr for `SCRIPT ERROR:` lines because the
engine exits 0 on a runtime script error. Every gate in it has been broken on
purpose and seen to go red before it was trusted. The checks under `tools/`
share [`tools/repo.py`](tools/repo.py): one `OK:` line or `FAIL:` lines, and
the exit status is the verdict.

## Governance

Drafted under the [qm constitution](https://github.com/quaternionmedia/qm):
records are `DRAFT-*.md` until a human ratifies them, commits name only humans,
and a version tag is the only claim. Formal adoption (the governance submodule
and a `project/rad-godot` branch) is a step on the ladder, not yet taken.
