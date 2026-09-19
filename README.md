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
- [`Resources/`](Resources) — styles and themes for the UI.
- [`Assets/`](Assets) — art and media assets.
- [`addons/`](addons) — third-party editor plugins (the Godot Git plugin).

## Requirements

- [Godot Engine](https://godotengine.org/) 4.7+.

## Running

Open `project.godot` in the Godot editor and run the project (F5), or run it
headless from the command line:

```sh
godot --path . 
```
