package swisseph

import (
	"fmt"

	"github.com/mshafiee/swephgo"
)

// HouseSystem represents the algorithm used to divide the sky into 12 houses.
type HouseSystem byte

const (
	// HousePlacidus is the most common Western house system.
	HousePlacidus HouseSystem = 'P'
	// HouseWholeSign treats each 30° sign as one house.
	HouseWholeSign HouseSystem = 'W'
	// HouseEqual divides the houses evenly, starting from the Ascendant.
	HouseEqual HouseSystem = 'A'
	// HouseKoch is another common system.
	HouseKoch HouseSystem = 'K'
)

// houseResult holds the 12 house cusps and the four key angles.
type houseResult struct {
	// Cusps[1..12] are the 12 house cusp longitudes. Cusps[0] is unused
	// (Swiss Ephemeris convention).
	Cusps [13]float64
	// Ascendant is the rising sign degree (1st house cusp).
	Ascendant float64
	// MC is the Midheaven (10th house cusp).
	MC float64
	// ARMC is the right ascension of the Midheaven.
	ARMC float64
	// Vertex is a sensitive western horizon point.
	Vertex float64
}

// computeHouses calculates the house cusps for the given Julian Day, latitude,
// longitude, and house system.
func computeHouses(jdUT, geoLat, geoLon float64, system HouseSystem) (*houseResult, error) {
	computeMu.Lock()
	defer computeMu.Unlock()

	cusps := make([]float64, 13)
	ascmc := make([]float64, 10)

	ret := swephgo.HousesEx(
		jdUT,
		swephgo.SeflgSwieph,
		geoLat,
		geoLon,
		int(system),
		cusps,
		ascmc,
	)
	if ret < 0 {
		return nil, fmt.Errorf("houses calculation failed for system %c", system)
	}

	res := &houseResult{
		Ascendant: ascmc[0],
		MC:        ascmc[1],
		ARMC:      ascmc[2],
		Vertex:    ascmc[3],
	}
	copy(res.Cusps[:], cusps)
	return res, nil
}
