package swisseph

// Human Design — the 9 energy centers and which gates belong to each.
//
// In a defined chart, a center "lights up" (defined) only when at least one
// of its gates is part of a defined channel (i.e. the OTHER end of the
// channel is also active in this chart). A defined center represents a
// reliable, consistent energy in your aura; an undefined center is open
// and absorbs/amplifies that energy from others.

// HDCenterName lists all 9 in canonical order.
var HDCenterNames = []string{
	"Head", "Ajna", "Throat", "G", "Heart",
	"Sacral", "SolarPlexus", "Spleen", "Root",
}

// centerGates maps each center to the list of gates that anchor in it.
// Sums to 64 across all centers (some centers have many gates, some few).
var centerGates = map[string][]int{
	"Head":        {64, 61, 63},
	"Ajna":        {47, 24, 4, 17, 43, 11},
	"Throat":      {62, 23, 56, 35, 12, 45, 33, 8, 31, 20, 16},
	"G":           {7, 1, 13, 25, 10, 15, 2, 46},
	"Heart":       {21, 40, 26, 51},
	"Sacral":      {5, 14, 29, 59, 9, 3, 42, 27, 34},
	"SolarPlexus": {36, 22, 37, 6, 49, 55, 30},
	"Spleen":      {48, 57, 44, 50, 32, 28, 18},
	"Root":        {53, 60, 52, 19, 39, 41, 58, 38, 54},
}

// gateCenter is the reverse map — each gate's home center.
var gateCenter = func() map[int]string {
	m := make(map[int]string, 64)
	for center, gates := range centerGates {
		for _, g := range gates {
			m[g] = center
		}
	}
	return m
}()

// motorCenters are the four energy generators in the system. A type is
// determined in part by whether one of these connects to the Throat.
var motorCenters = map[string]bool{
	"Heart":       true,
	"SolarPlexus": true,
	"Sacral":      true,
	"Root":        true,
}
