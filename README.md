# moe

A Godot 4 (Mobile renderer) project for building and visualizing graphs in 3D
space.

## Controls

- **Left click** on the ground to create a node, or click-drag an existing
  node to move it (hold **Shift** while dragging to move it vertically).
- **Right click** a node to select it, then right click another node to
  connect them with an edge.
- Hold a **number key (0–9)** while clicking to set the type (color) of the
  next node or edge created.

## Project layout

- [`Scenes/`](Scenes) — the main scene (`main.tscn`/`main.gd`), the orbiting
  camera controller, and the `Graph`/`NodeVisual`/`EdgeVisual` data/visual
  classes.
- [`addons/`](addons) — third-party editor plugins (the Godot Git plugin).
- [`tools/`](tools) — the development loop below.

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
tools/dev.ps1 check            # import, the engine's parser on every script, a headless smoke run
tools/dev.ps1 play -Frames 60  # run the main scene windowed, quit after 60 frames
tools/dev.ps1 editor           # open the editor, refusing if one already has the project
```

`check` reads the smoke run's stderr for `SCRIPT ERROR:` lines because the
engine exits 0 on a runtime script error. Every gate in it has been broken on
purpose and seen to go red before it was trusted.
