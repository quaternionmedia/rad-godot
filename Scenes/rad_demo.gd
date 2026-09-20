extends Control
## A surface for the menu on its own, before the graph host wires it in: a
## ground that opens a ring on right-click, long-press or `m`, a resolver with
## the contract's canvas vocabulary and one colour submenu, and a log of every
## intent that leaves the addon. `tools/dev.ps1 play -Scene res://Scenes/rad_demo.tscn`.
##
## This is the scene the by-hand checklist in the scope record's v0.0.2 is run
## on: 44-unit targets at eight items, dead-zone cancel, outward cancel, the
## keyboard-only path. Nothing here reaches the graph.

var tokens := RadTheme.new()
var menu: RadMenu
var log_label: Label
var _lines: PackedStringArray = []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var ground := ColorRect.new()
	ground.color = tokens.token("page-bg")
	ground.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ground.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(ground)

	var hint := Label.new()
	hint.text = "rad-godot — right-click, long-press or M opens a ring at the pointer.\nOpen: drag into the band and release, or click a wedge. Digits choose a cell, arrows move, 5 backs out, Tab rotates, Enter commits, Escape closes.\nHold R while opening for an eight-item ring."
	hint.position = Vector2(16, 12)
	hint.add_theme_color_override("font_color", tokens.token("text-dim"))
	add_child(hint)

	log_label = Label.new()
	log_label.position = Vector2(16, 84)
	log_label.add_theme_color_override("font_color", tokens.token("text"))
	add_child(log_label)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	menu = RadMenu.new()
	menu.tokens = tokens
	layer.add_child(menu)
	menu.set_resolver(resolve)
	menu.intent.connect(_on_intent)
	menu.closed.connect(func(): _log("cancelled"))

	var invoker := RadInvoker.new()
	add_child(invoker)
	invoker.invoke.connect(func(pos: Vector2, mode: String):
		var kind := "wide" if Input.is_key_pressed(KEY_R) else "canvas"
		menu.open_at({ "type": kind, "targetIds": [], "position": { "x": pos.x, "y": pos.y } }, pos, mode))

	# `--autoopen` after `--` on the command line opens the eight-item ring at the
	# centre with a highlight, so a windowed frames-limited run draws one on the
	# real renderer with nobody at the mouse. The loop's play mode passes it.
	if OS.get_cmdline_user_args().has("--autoopen"):
		await get_tree().process_frame
		var c := get_viewport_rect().size / 2.0
		menu.open_at({ "type": "wide", "targetIds": [], "position": { "x": c.x, "y": c.y } }, c, "idle")
		menu.session.move_cell("right")
		_log("autoopen: ring at %s, highlight %s" % [menu.session.centre(), menu.session.view().highlight])


## The contract's canvas vocabulary, and one submenu whose items are swatches
## naming palette tokens — never a literal colour.
func resolve(context: Dictionary) -> Dictionary:
	var colours := []
	for name in RadTheme.SWATCHES:
		colours.append({ "id": "color:" + name, "action": "color:" + name, "label": name, "swatch": name })
	if context.type == "wide":
		return { "title": "wide", "items": [
			{ "id": "add-node", "label": "add node" }, { "id": "fit", "label": "fit" },
			{ "id": "relayout", "label": "relayout" }, { "id": "toggle-physics", "label": "physics" },
			{ "id": "hide", "label": "hide" }, { "id": "spread", "label": "spread" },
			{ "id": "cluster", "label": "cluster", "enabled": false },
			{ "id": "delete", "label": "delete", "destructive": true },
		] }
	return { "title": "canvas", "items": [
		{ "id": "add-node", "label": "add node" },
		{ "id": "fit", "label": "fit" },
		{ "id": "relayout", "label": "relayout" },
		{ "id": "colour", "label": "colour", "children": colours },
	] }


func _on_intent(it: Dictionary) -> void:
	_log("%s  (%s, item %s, t=%d)" % [it.action, it.context.type, it.itemId, it.t])


func _log(line: String) -> void:
	print("rad-demo: ", line)
	_lines.append(line)
	while _lines.size() > 12:
		_lines.remove_at(0)
	log_label.text = "\n".join(_lines)
