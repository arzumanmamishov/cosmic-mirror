package swisseph

import (
	"fmt"
	"sync"

	"github.com/mshafiee/swephgo"
)

// planetSpec defines one body to compute, with its display name and Swiss
// Ephemeris planet ID.
type planetSpec struct {
	Name string
	ID   int
}

// chartPlanets is the standard list of bodies included in a natal chart.
// Order is canonical: luminaries → personal → social → outer → points.
var chartPlanets = []planetSpec{
	{"Sun", swephgo.SeSun},
	{"Moon", swephgo.SeMoon},
	{"Mercury", swephgo.SeMercury},
	{"Venus", swephgo.SeVenus},
	{"Mars", swephgo.SeMars},
	{"Jupiter", swephgo.SeJupiter},
	{"Saturn", swephgo.SeSaturn},
	{"Uranus", swephgo.SeUranus},
	{"Neptune", swephgo.SeNeptune},
	{"Pluto", swephgo.SePluto},
	{"North Node", swephgo.SeMeanNode},
	{"Chiron", swephgo.SeChiron},
}

// planetPosition is the raw output of a Swiss Ephemeris calculation for a
// single body.
type planetPosition struct {
	Name       string
	Longitude  float64 // degrees in zodiac (0..360)
	Speed      float64 // degrees/day; negative means retrograde
	Retrograde bool
}

// computeMu serializes calls into the Swiss Ephemeris C library, which is not
// thread-safe.
var computeMu sync.Mutex

// computePlanets returns the position of every body in chartPlanets at the
// given Julian Day (UT).
func computePlanets(jdUT float64) ([]planetPosition, error) {
	computeMu.Lock()
	defer computeMu.Unlock()

	flags := swephgo.SeflgSwieph | swephgo.SeflgSpeed
	results := make([]planetPosition, 0, len(chartPlanets))

	for _, p := range chartPlanets {
		xx := make([]float64, 6)
		serr := make([]byte, 256)

		ret := swephgo.CalcUt(jdUT, p.ID, flags, xx, serr)
		if ret < 0 {
			return nil, fmt.Errorf("calc %s: %s", p.Name, trimNullBytes(serr))
		}

		results = append(results, planetPosition{
			Name:       p.Name,
			Longitude:  xx[0],
			Speed:      xx[3],
			Retrograde: xx[3] < 0,
		})
	}

	return results, nil
}

func trimNullBytes(b []byte) string {
	for i, c := range b {
		if c == 0 {
			return string(b[:i])
		}
	}
	return string(b)
}
