class_name RadTheme
extends Resource
## rad's token layer, as a Godot resource. Every colour the renderer paints is
## read through `token()`; no literal appears outside this file, and a
## `color:<token>` intent names a palette token here and never a value.
##
## Two tiers, as rad's theme record splits them: PALETTE tokens are named for
## what they are and live in `palette`; ROLE tokens are named for what they do
## and are defined in terms of palette tokens in ROLES. A theme redefines
## palette values and inherits every role.
##
## The defaults are rad's `radical` palette, the house mood: neon accents on a
## soft deep-indigo ground, and one warm hue that deliberately does not glow.

@export var palette: Dictionary = {
	"bg": Color("#14111f"), "surface": Color("#1d1930"), "surface-2": Color("#262041"),
	"ink": Color("#f4eeff"), "ink-dim": Color("#bdb2d9"), "line": Color("#3b3358"),
	"line-strong": Color("#9186c9"), "line-soft": Color("#241f3c"),
	"accent": Color("#5cf0ff"), "accent-ink": Color("#0a0716"),
	"signal": Color("#ff7aa8"), "leaf": Color("#6ef2a0"), "calm": Color("#4ae3d0"),
	"royal": Color("#bd93ff"), "gold": Color("#ffc861"), "sky": Color("#5cf0ff"),
}

## Role -> palette token, the same map the reference stylesheet declares.
const ROLES := {
	"wedge-fill": "surface-2", "wedge-fill-hl": "accent", "wedge-stroke": "line-strong",
	"wedge-label": "ink", "wedge-label-hl": "accent-ink", "wedge-label-danger": "signal",
	"hub-fill": "surface", "hub-stroke": "line-strong", "hub-label": "ink-dim",
	"focus-ring": "accent", "page-bg": "bg", "text": "ink", "text-dim": "ink-dim",
	"ok": "leaf", "danger": "signal",
}

## The palette tokens a `color:<token>` intent may name.
const SWATCHES: Array[String] = ["signal", "leaf", "calm", "royal", "gold", "sky"]


## Resolve a role token, a palette token, or a `color:<token>` verb to a Color.
## An unknown name resolves to magenta on purpose: an unthemed colour should be
## seen, not guessed.
func token(name: String) -> Color:
	var key := _palette_key(name)
	if palette.has(key):
		return palette[key]
	push_warning("rad: no token named '%s'" % name)
	return Color.MAGENTA


func has_token(name: String) -> bool:
	return palette.has(_palette_key(name))


func _palette_key(name: String) -> String:
	var key := name.trim_prefix("color:").trim_prefix("--rad-")
	return ROLES[key] if ROLES.has(key) else key
