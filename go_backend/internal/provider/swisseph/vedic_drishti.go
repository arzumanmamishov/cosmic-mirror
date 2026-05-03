package swisseph

import "cosmic-mirror/internal/domain"

// Vedic aspects (graha drishti) are sign-based, not orb-based. Each graha
// fully aspects the 7th sign from itself. In addition:
//   Mars    — also 4th and 8th
//   Jupiter — also 5th and 9th
//   Saturn  — also 3rd and 10th
//   Rahu/Ketu — 5th, 7th, 9th (Parashara school)
//
// drishtiHouses lists the house-distances each graha aspects, including the
// universal 7th. Distances are 1-indexed: distance 1 = same sign, 7 = opposite.
var drishtiHouses = map[string][]int{
	"Sun":     {7},
	"Moon":    {7},
	"Mercury": {7},
	"Venus":   {7},
	"Mars":    {4, 7, 8},
	"Jupiter": {5, 7, 9},
	"Saturn":  {3, 7, 10},
	"Rahu":    {5, 7, 9},
	"Ketu":    {5, 7, 9},
}

// drishtiTypeName returns a human label for an aspect distance.
func drishtiTypeName(distance int) string {
	switch distance {
	case 3:
		return "3rd"
	case 4:
		return "4th"
	case 5:
		return "5th"
	case 7:
		return "7th"
	case 8:
		return "8th"
	case 9:
		return "9th"
	case 10:
		return "10th"
	default:
		return ""
	}
}

// drishtiStrength returns the classical fractional strength of an aspect.
// The 7th aspect is full (1.0). The "special" aspects of Mars/Jupiter/Saturn
// are also full per BPHS. Rahu/Ketu's special aspects are full per Parashara.
// Some schools use 0.25/0.5/0.75 for various distances; we use full strength
// for the canonical seven, which matches the most common modern convention.
func drishtiStrength(distance int) float64 {
	switch distance {
	case 3, 4, 5, 7, 8, 9, 10:
		return 1.0
	default:
		return 0.0
	}
}

// computeDrishti produces directional Vedic aspects:
//   1. graha → graha   (when one planet's drishti reaches another planet's bhava)
//   2. graha → bhava   (each drishti always reaches a house)
//
// `planets` must already carry sidereal house numbers (1..12).
func computeDrishti(planets []domain.VedicPlanetPlacement) []domain.VedicAspect {
	out := make([]domain.VedicAspect, 0)

	// Build a fast lookup: bhava -> [planet names occupying it].
	occupants := make(map[int][]string, 12)
	for _, p := range planets {
		occupants[p.House] = append(occupants[p.House], p.Name)
	}

	for _, p := range planets {
		distances, ok := drishtiHouses[p.Name]
		if !ok {
			continue
		}
		for _, d := range distances {
			targetHouse := ((p.House - 1 + (d - 1)) % 12) + 1
			typeName := drishtiTypeName(d)
			strength := drishtiStrength(d)

			// 1) graha → bhava
			out = append(out, domain.VedicAspect{
				From:         p.Name,
				FromSanskrit: grahaSanskrit[p.Name],
				To:           "House",
				ToHouse:      targetHouse,
				Type:         typeName,
				Strength:     strength,
			})

			// 2) graha → graha (every planet that occupies the targeted bhava)
			for _, target := range occupants[targetHouse] {
				if target == p.Name {
					continue
				}
				out = append(out, domain.VedicAspect{
					From:         p.Name,
					FromSanskrit: grahaSanskrit[p.Name],
					To:           target,
					ToHouse:      targetHouse,
					Type:         typeName,
					Strength:     strength,
				})
			}
		}
	}

	return out
}
