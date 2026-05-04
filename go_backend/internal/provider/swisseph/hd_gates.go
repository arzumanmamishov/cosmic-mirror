package swisseph

import "math"

// Human Design — the Rave I Ching wheel.
//
// The 64 hexagrams are mapped onto the 360° tropical ecliptic in a fixed
// non-zodiac order. Each hexagram (gate) spans 360/64 = 5.625°. Each gate
// is split into 6 lines, so each line spans 5.625/6 = 0.9375°.
//
// The wheel "starts" at Gate 41 line 1, located at 2°00'00" Aquarius (=
// 302° absolute longitude in tropical terms, more precisely 302°00'00").
//
// Walking forward through the ecliptic from there, the gate sequence is the
// canonical Ra Uru Hu order below.

// gateSequence is the 64 gates in the order they appear walking forward
// (anticlockwise on the wheel diagram, but increasing tropical longitude).
var gateSequence = [64]int{
	41, 19, 13, 49, 30, 55, 37, 63, 22, 36, 25, 17, 21, 51, 42, 3,
	27, 24, 2, 23, 8, 20, 16, 35, 45, 12, 15, 52, 39, 53, 62, 56,
	31, 33, 7, 4, 29, 59, 40, 64, 47, 6, 46, 18, 48, 57, 32, 50,
	28, 44, 1, 43, 14, 34, 9, 5, 26, 11, 10, 58, 38, 54, 61, 60,
}

// wheelStartLongitude is the tropical longitude (0..360) of Gate 41 line 1.
//   Aquarius starts at 300°. 2°00'00" Aqu = 302°.
const wheelStartLongitude = 302.0

// gateSpan = 360 / 64 = 5.625°
const gateSpan = 360.0 / 64.0

// lineSpan = gateSpan / 6 = 0.9375°
const lineSpan = gateSpan / 6.0

// colorSpan = lineSpan / 6 = 0.15625°
const colorSpan = lineSpan / 6.0

// toneSpan = colorSpan / 6 = 0.026...
const toneSpan = colorSpan / 6.0

// gateForLongitude returns the (gate, line, color, tone) for a given
// tropical longitude in degrees [0, 360). Line is 1..6, color 1..6,
// tone 1..6.
func gateForLongitude(lon float64) (gate, line, color, tone int) {
	lon = math.Mod(lon-wheelStartLongitude+360, 360)
	gateIdx := int(lon / gateSpan) // 0..63
	if gateIdx < 0 {
		gateIdx = 0
	}
	if gateIdx > 63 {
		gateIdx = 63
	}
	gate = gateSequence[gateIdx]

	withinGate := lon - float64(gateIdx)*gateSpan
	line = int(withinGate/lineSpan) + 1
	if line < 1 {
		line = 1
	}
	if line > 6 {
		line = 6
	}

	withinLine := withinGate - float64(line-1)*lineSpan
	color = int(withinLine/colorSpan) + 1
	if color < 1 {
		color = 1
	}
	if color > 6 {
		color = 6
	}

	withinColor := withinLine - float64(color-1)*colorSpan
	tone = int(withinColor/toneSpan) + 1
	if tone < 1 {
		tone = 1
	}
	if tone > 6 {
		tone = 6
	}
	return
}

// gateName returns the canonical Rave I Ching name + theme for a gate.
var gateName = map[int]string{
	1: "The Creative — Self-Expression", 2: "The Receptive — Direction of the Self",
	3: "Difficulty at the Beginning — Ordering", 4: "Youthful Folly — Formulization",
	5: "Waiting — Fixed Patterns", 6: "Conflict — Friction",
	7: "The Army — The Role of the Self", 8: "Holding Together — Contribution",
	9: "Small Taming — Focus", 10: "Treading — Behaviour of the Self",
	11: "Peace — Ideas", 12: "Standstill — Caution",
	13: "Fellowship of Man — The Listener", 14: "Possession in Great Measure — Power Skills",
	15: "Modesty — Extremes", 16: "Enthusiasm — Skills",
	17: "Following — Opinions", 18: "Work on the Decayed — Correction",
	19: "Approach — Wanting", 20: "Contemplation — The Now",
	21: "Biting Through — The Hunter / Huntress", 22: "Grace — Openness",
	23: "Splitting Apart — Assimilation", 24: "Returning — Rationalization",
	25: "Innocence — Spirit of the Self", 26: "Taming Power of the Great — The Egoist",
	27: "Nourishment — Caring", 28: "Preponderance of the Great — The Game Player",
	29: "The Abysmal — Perseverance", 30: "Clinging Fire — Feelings",
	31: "Influence — Leadership", 32: "Duration — Continuity",
	33: "Retreat — Privacy", 34: "Power of the Great — Power",
	35: "Progress — Change", 36: "Darkening of the Light — Crisis",
	37: "The Family — Friendship", 38: "Opposition — The Fighter",
	39: "Obstruction — Provocation", 40: "Deliverance — Aloneness",
	41: "Decrease — Imagination", 42: "Increase — Growth",
	43: "Breakthrough — Insight", 44: "Coming to Meet — Alertness",
	45: "Gathering Together — The Gatherer", 46: "Pushing Upward — Determination",
	47: "Oppression — Realization", 48: "The Well — Depth",
	49: "Revolution — Principles", 50: "The Cauldron — Values",
	51: "The Arousing — Shock", 52: "Keeping Still — Inaction",
	53: "Development — Beginnings", 54: "The Marrying Maiden — Ambition",
	55: "Abundance — Spirit", 56: "The Wanderer — Stimulation",
	57: "The Gentle — Intuitive Clarity", 58: "The Joyous — Vitality",
	59: "Dispersion — Sexuality", 60: "Limitation — Acceptance",
	61: "Inner Truth — Mystery", 62: "Preponderance of the Small — Details",
	63: "After Completion — Doubt", 64: "Before Completion — Confusion",
}

// gateForLongitudeBasic returns just (gate, line) — used for the activations
// list where color/tone aren't needed (those are only computed for the
// Sun's variables).
func gateForLongitudeBasic(lon float64) (gate, line int) {
	g, l, _, _ := gateForLongitude(lon)
	return g, l
}
