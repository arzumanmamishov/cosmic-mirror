package swisseph

import "cosmic-mirror/internal/domain"

// Ashtakavarga is the classical bindu (benefic point) accumulation system.
// For each of seven grahas (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn),
// a 12-element bindu array is built by iterating over a "contributor set"
// (the same seven plus the Lagna/Ascendant). Each contributor adds 1 bindu
// to specific signs counted from its own sign.
//
// The reference tables below come from BPHS chapter 65 / Sarvarth Chintamani.
// Each row: contributor → list of house-distances (1-indexed from contributor)
// at which the contributor places a bindu in the planet's chart.

// avBenefic[planet][contributor] = []house-distances (1..12) where bindu is given.
// "Lagna" is treated as a pseudo-contributor.
var avBenefic = map[string]map[string][]int{
	"Sun": {
		"Sun":     {1, 2, 4, 7, 8, 9, 10, 11},
		"Moon":    {3, 6, 10, 11},
		"Mars":    {1, 2, 4, 7, 8, 9, 10, 11},
		"Mercury": {3, 5, 6, 9, 10, 11, 12},
		"Jupiter": {5, 6, 9, 11},
		"Venus":   {6, 7, 12},
		"Saturn":  {1, 2, 4, 7, 8, 9, 10, 11},
		"Lagna":   {3, 4, 6, 10, 11, 12},
	},
	"Moon": {
		"Sun":     {3, 6, 7, 8, 10, 11},
		"Moon":    {1, 3, 6, 7, 10, 11},
		"Mars":    {2, 3, 5, 6, 9, 10, 11},
		"Mercury": {1, 3, 4, 5, 7, 8, 10, 11},
		"Jupiter": {1, 4, 7, 8, 10, 11, 12},
		"Venus":   {3, 4, 5, 7, 9, 10, 11},
		"Saturn":  {3, 5, 6, 11},
		"Lagna":   {3, 6, 10, 11},
	},
	"Mars": {
		"Sun":     {3, 5, 6, 10, 11},
		"Moon":    {3, 6, 11},
		"Mars":    {1, 2, 4, 7, 8, 10, 11},
		"Mercury": {3, 5, 6, 11},
		"Jupiter": {6, 10, 11, 12},
		"Venus":   {6, 8, 11, 12},
		"Saturn":  {1, 4, 7, 8, 9, 10, 11},
		"Lagna":   {1, 3, 6, 10, 11},
	},
	"Mercury": {
		"Sun":     {5, 6, 9, 11, 12},
		"Moon":    {2, 4, 6, 8, 10, 11},
		"Mars":    {1, 2, 4, 7, 8, 9, 10, 11},
		"Mercury": {1, 3, 5, 6, 9, 10, 11, 12},
		"Jupiter": {6, 8, 11, 12},
		"Venus":   {1, 2, 3, 4, 5, 8, 9, 11},
		"Saturn":  {1, 2, 4, 7, 8, 9, 10, 11},
		"Lagna":   {1, 2, 4, 6, 8, 10, 11},
	},
	"Jupiter": {
		"Sun":     {1, 2, 3, 4, 7, 8, 9, 10, 11},
		"Moon":    {2, 5, 7, 9, 11},
		"Mars":    {1, 2, 4, 7, 8, 10, 11},
		"Mercury": {1, 2, 4, 5, 6, 9, 10, 11},
		"Jupiter": {1, 2, 3, 4, 7, 8, 10, 11},
		"Venus":   {2, 5, 6, 9, 10, 11},
		"Saturn":  {3, 5, 6, 12},
		"Lagna":   {1, 2, 4, 5, 6, 7, 9, 10, 11},
	},
	"Venus": {
		"Sun":     {8, 11, 12},
		"Moon":    {1, 2, 3, 4, 5, 8, 9, 11, 12},
		"Mars":    {3, 4, 6, 9, 11, 12},
		"Mercury": {3, 5, 6, 9, 11},
		"Jupiter": {5, 8, 9, 10, 11},
		"Venus":   {1, 2, 3, 4, 5, 8, 9, 10, 11},
		"Saturn":  {3, 4, 5, 8, 9, 10, 11},
		"Lagna":   {1, 2, 3, 4, 5, 8, 9, 11},
	},
	"Saturn": {
		"Sun":     {1, 2, 4, 7, 8, 10, 11},
		"Moon":    {3, 6, 11},
		"Mars":    {3, 5, 6, 10, 11, 12},
		"Mercury": {6, 8, 9, 10, 11, 12},
		"Jupiter": {5, 6, 11, 12},
		"Venus":   {6, 11, 12},
		"Saturn":  {3, 5, 6, 11},
		"Lagna":   {1, 3, 4, 6, 10, 11},
	},
}

// signIndex returns the 0..11 index for an English sign name.
func signIndex(name string) int {
	for i, s := range signs {
		if s == name {
			return i
		}
	}
	return 0
}

// ComputeAshtakavarga produces the 7 BhinnAshtakavarga arrays plus the Sarva
// total. Each cell is a count of bindus (max 8 per cell since 8 contributors).
func (c *Client) ComputeAshtakavarga(chart *domain.VedicChart) *domain.Ashtakavarga {
	pm := planetMap(chart)
	contributorSign := map[string]int{}
	for _, p := range chart.Planets {
		contributorSign[p.Name] = signIndex(p.Sign)
	}
	contributorSign["Lagna"] = signIndex(chart.Lagna.Sign)

	bhinn := make(map[string][12]int, 7)
	var sarva [12]int

	for _, planet := range []string{"Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"} {
		var arr [12]int
		// The planet must be in the chart.
		if _, ok := pm[planet]; !ok && planet != "Lagna" {
			bhinn[planet] = arr
			continue
		}
		ruleset, ok := avBenefic[planet]
		if !ok {
			bhinn[planet] = arr
			continue
		}
		for contributor, distances := range ruleset {
			contribSignIdx, found := contributorSign[contributor]
			if !found {
				continue
			}
			for _, d := range distances {
				targetSign := (contribSignIdx + d - 1) % 12
				arr[targetSign]++
			}
		}
		bhinn[planet] = arr
		for i := 0; i < 12; i++ {
			sarva[i] += arr[i]
		}
	}

	return &domain.Ashtakavarga{
		Sarva: sarva,
		Bhinn: bhinn,
	}
}
