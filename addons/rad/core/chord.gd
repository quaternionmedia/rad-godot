class_name RadChord
## rad core — chords. Platform-free.
##
## A CharaChorder chord arrives as a word whose inter-key gaps are machine-fast;
## serial typing is human-slow. Same words, same verbs — `chorded` only affects
## IPA accounting (a chord is one input). Events are {t, k}.

## The reference host's chord vocabulary. It is here because the vectors pin
## its prefix-freeness by name; a Godot host binds its own words to the same
## verbs and is held to the same rule.
const CHORD_MAP := {
	"pin": "pin", "hd": "hide", "del": "delete", "nbr": "select-neighbors",
	"fit": "fit", "lay": "relayout", "add": "add-node", "un": "show-hidden",
	"sp": "spread", "cl": "cluster", "ds": "clear-selection",
	"red": "color:signal", "blu": "color:sky", "tea": "color:calm",
	"vio": "color:royal", "gld": "color:gold",
}


static func splitBursts(evts: Array, splitGap: float = RadTime.TIME.burstSplitMs) -> Array:
	var out := []
	for e in evts:
		if out.is_empty() or e.t - out[-1][-1].t > splitGap:
			out.append([e])
		else:
			out[-1].append(e)
	return out


static func classifyBurst(evts: Array, chordGap: float = RadTime.TIME.chordGapMs) -> Dictionary:
	var word := ""
	for e in evts:
		word += str(e.k)
	var chorded := evts.size() >= 2
	for i in range(1, evts.size()):
		if evts[i].t - evts[i - 1].t > chordGap:
			chorded = false
	return { "word": word, "chorded": chorded }


## Every pair where one word is a proper prefix of another, as "a ⊂ b", sorted.
## A prefix-free vocabulary finalizes on its last keystroke; a collision means
## the shorter word can never be typed without waiting for the split window.
static func prefixCollisions(words: Array) -> Array:
	var out := []
	for a in words:
		for b in words:
			if a != b and str(b).begins_with(str(a)):
				out.append("%s ⊂ %s" % [a, b])
	out.sort()
	return out
