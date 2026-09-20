class_name RadTime
## rad core — time. Platform-free; pure functions, no clock of its own.
##
## MIDI clock = 24 ppqn 0xF8 ticks. Tempo from the median inter-tick period
## (robust to USB jitter). Quantization maps a wall-clock time onto a grid
## {phase, period}; a scheduler commits at max(now, gridT). The three tempo
## axes (bpm, div, aps) and their MIDI CC mappings are here because the
## vectors pin them; nothing in this repository schedules yet.

const TIME := { "ppqn": 24, "chordGapMs": 30.0, "burstSplitMs": 250.0 }
const TEMPO_RANGE := { "bpm": [30.0, 300.0], "aps": [0.25, 8.0] }
const DIVS: Array[float] = [0.5, 1.0, 2.0, 3.0, 4.0]


static func medianOf(xs: Array) -> Variant:
	if xs.is_empty():
		return null
	var s := xs.duplicate()
	s.sort()
	var m := s.size() >> 1
	return s[m] if s.size() % 2 == 1 else (s[m - 1] + s[m]) / 2.0


static func estimateBpm(tickTimes: Array, ppqn: int = TIME.ppqn) -> Variant:
	if tickTimes.size() < 2:
		return null
	var diffs := []
	for i in range(1, tickTimes.size()):
		diffs.append(tickTimes[i] - tickTimes[i - 1])
	var p: Variant = medianOf(diffs)
	return 60000.0 / (p * ppqn) if p > 0 else null


static func quantizeTime(t: float, phase: float, period: float, policy: String) -> float:
	if policy == "nearest":
		return phase + RadGeometry.jsRound((t - phase) / period) * period
	return phase + ceilf((t - phase - 1e-9) / period) * period   # 'next' (on-grid stays)


static func clampTo(v: float, range: Array) -> float:
	return minf(range[1], maxf(range[0], v))


static func apsFromTempo(bpm: float, div: float) -> float:
	return (bpm / 60.0) * div


static func ccToRange(cc: float, lo: float, hi: float) -> float:
	return lo + (clampTo(cc, [0.0, 127.0]) / 127.0) * (hi - lo)


static func ccToDiv(cc: float, divs: Array = DIVS) -> float:
	return divs[mini(divs.size() - 1, int(floorf(clampTo(cc, [0.0, 127.0]) / 128.0 * divs.size())))]
