package swisseph

import "math"

// aspectDef describes a recognized aspect between two planets.
type aspectDef struct {
	Name  string
	Angle float64 // exact angular separation
	Orb   float64 // tolerance in degrees
}

// majorAspects are the five Ptolemaic aspects plus the inconjunct (quincunx).
// Orbs follow common Western astrology defaults.
var majorAspects = []aspectDef{
	{"conjunction", 0, 8},
	{"sextile", 60, 6},
	{"square", 90, 8},
	{"trine", 120, 8},
	{"opposition", 180, 10},
	{"quincunx", 150, 3},
}

// aspectMatch is a found aspect between two named planets.
type aspectMatch struct {
	Planet1 string
	Planet2 string
	Type    string
	Orb     float64
}

// computeAspects finds every aspect within orb between the given planet
// positions. It avoids duplicate pairs (A-B and B-A) and self-aspects.
func computeAspects(planets []planetPosition) []aspectMatch {
	matches := make([]aspectMatch, 0)

	for i := 0; i < len(planets); i++ {
		for j := i + 1; j < len(planets); j++ {
			a := planets[i]
			b := planets[j]
			separation := angularDistance(a.Longitude, b.Longitude)

			for _, def := range majorAspects {
				diff := math.Abs(separation - def.Angle)
				if diff <= def.Orb {
					matches = append(matches, aspectMatch{
						Planet1: a.Name,
						Planet2: b.Name,
						Type:    def.Name,
						Orb:     round2(diff),
					})
					break
				}
			}
		}
	}

	return matches
}

// angularDistance returns the absolute angular separation between two
// longitudes (0..180). It handles the 360°/0° wrap.
func angularDistance(a, b float64) float64 {
	diff := math.Abs(normalize360(a) - normalize360(b))
	if diff > 180 {
		diff = 360 - diff
	}
	return diff
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
