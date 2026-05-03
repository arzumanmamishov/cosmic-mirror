package swisseph

import (
	"context"
	"fmt"
	"time"

	"github.com/mshafiee/swephgo"

	"cosmic-mirror/internal/domain"
)

// vedicGrahas is the canonical set of nine Vedic planets (Navagraha). The
// outer modern planets (Uranus, Neptune, Pluto) and Chiron are not used in
// classical Jyotish.
//
// Rahu is computed via SeTrueNode (true lunar node, more accurate than the
// mean node for short-term predictions). Ketu is derived as Rahu + 180°
// since swephgo does not expose a separate Ketu constant.
var vedicGrahas = []planetSpec{
	{"Sun", swephgo.SeSun},
	{"Moon", swephgo.SeMoon},
	{"Mars", swephgo.SeMars},
	{"Mercury", swephgo.SeMercury},
	{"Jupiter", swephgo.SeJupiter},
	{"Venus", swephgo.SeVenus},
	{"Saturn", swephgo.SeSaturn},
	{"Rahu", swephgo.SeTrueNode},
	// Ketu is appended in computeSiderealPlanets after Rahu is known.
}

// vargaName returns the human label for a divisional chart code.
func vargaName(divisor int) string {
	switch divisor {
	case 1:
		return "Rasi"
	case 2:
		return "Hora"
	case 3:
		return "Drekkana"
	case 4:
		return "Chaturthamsa"
	case 7:
		return "Saptamsa"
	case 9:
		return "Navamsa"
	case 10:
		return "Dasamsa"
	case 12:
		return "Dvadasamsa"
	case 16:
		return "Shodasamsa"
	case 20:
		return "Vimsamsa"
	case 24:
		return "Chaturvimsamsa"
	case 27:
		return "Bhamsa"
	case 30:
		return "Trimsamsa"
	case 40:
		return "Khavedamsa"
	case 45:
		return "Akshavedamsa"
	case 60:
		return "Shashtiamsa"
	default:
		return ""
	}
}

// computeSiderealPlanets returns the 9 grahas as raw planetPosition values
// using sidereal longitudes. The mutex is held throughout because
// SetSidMode mutates global C state and CalcUt must run with that state set.
func computeSiderealPlanets(jdUT float64, ayanamsa int) ([]planetPosition, float64, error) {
	computeMu.Lock()
	defer computeMu.Unlock()

	swephgo.SetSidMode(ayanamsa, 0, 0)
	flags := swephgo.SeflgSwieph | swephgo.SeflgSpeed | swephgo.SeflgSidereal

	results := make([]planetPosition, 0, len(vedicGrahas)+1)
	var rahuLon, rahuSpeed float64
	for _, g := range vedicGrahas {
		xx := make([]float64, 6)
		serr := make([]byte, 256)

		ret := swephgo.CalcUt(jdUT, g.ID, flags, xx, serr)
		if ret < 0 {
			return nil, 0, fmt.Errorf("sidereal calc %s: %s", g.Name, trimNullBytes(serr))
		}
		pos := planetPosition{
			Name:       g.Name,
			Longitude:  xx[0],
			Speed:      xx[3],
			Retrograde: xx[3] < 0,
		}
		results = append(results, pos)
		if g.Name == "Rahu" {
			rahuLon = xx[0]
			rahuSpeed = xx[3]
		}
	}

	// Ketu: 180° opposite Rahu, same speed (but opposite sign retains retrograde).
	results = append(results, planetPosition{
		Name:       "Ketu",
		Longitude:  normalize360(rahuLon + 180),
		Speed:      rahuSpeed,
		Retrograde: rahuSpeed < 0,
	})

	// Compute current ayanamsa offset in degrees for transparency to the UI.
	ayanamsaValue := swephgo.GetAyanamsaUt(jdUT)

	return results, ayanamsaValue, nil
}

// computeSiderealAscendant returns the rising sign / ascendant longitude in
// the sidereal frame. Reuses Whole Sign system for Vedic.
func computeSiderealAscendant(jdUT, lat, lon float64, ayanamsa int) (float64, error) {
	computeMu.Lock()
	defer computeMu.Unlock()

	swephgo.SetSidMode(ayanamsa, 0, 0)
	cusps := make([]float64, 13)
	ascmc := make([]float64, 10)

	ret := swephgo.HousesEx(
		jdUT,
		swephgo.SeflgSidereal,
		lat,
		lon,
		int(HouseWholeSign),
		cusps,
		ascmc,
	)
	if ret < 0 {
		return 0, fmt.Errorf("sidereal houses calculation failed")
	}
	return ascmc[0], nil
}

// GetVedicChart computes the full Vedic Rasi (D1) chart for given birth data.
// ayanamsa is one of the swephgo SE_SIDM_* constants; pass 1 (Lahiri) for
// the modern Vedic standard. House layout is Whole Sign (1st sign of Asc =
// 1st bhava, next sign = 2nd bhava, etc.).
func (c *Client) GetVedicChart(
	ctx context.Context,
	birthDate time.Time,
	birthHour, birthMin int,
	lat, lon, tzone float64,
	ayanamsa int,
) (*domain.VedicChart, error) {
	if err := c.Init(); err != nil {
		return nil, fmt.Errorf("swisseph init: %w", err)
	}

	hourLocal := float64(birthHour) + float64(birthMin)/60.0
	hourUT := hourLocal - tzone
	jdUT := swephgo.Julday(
		birthDate.Year(),
		int(birthDate.Month()),
		birthDate.Day(),
		hourUT,
		swephgo.SeGregCal,
	)

	planetPositions, ayanamsaVal, err := computeSiderealPlanets(jdUT, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("sidereal planets: %w", err)
	}

	ascLon, err := computeSiderealAscendant(jdUT, lat, lon, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("sidereal ascendant: %w", err)
	}

	chart := buildVedicChart(planetPositions, ascLon, ayanamsa, ayanamsaVal, 1)
	return chart, nil
}

// buildVedicChart assembles the domain object from raw sidereal positions.
// Used by both Rasi (D1) and divisional chart computations — for divisional
// charts the planet longitudes have already been re-mapped per Parashara rule.
//
// varga is the divisor code (1 for Rasi, 9 for Navamsa, etc.).
func buildVedicChart(positions []planetPosition, ascLon float64, ayanamsa int, ayanamsaVal float64, varga int) *domain.VedicChart {
	// Whole Sign houses: house 1 = sign of ascendant; planet's house derived
	// from sign-difference between planet's sign and Asc's sign.
	ascSignIdx := int(normalize360(ascLon) / 30)

	houseOfSign := func(longitude float64) int {
		signIdx := int(normalize360(longitude) / 30)
		diff := (signIdx - ascSignIdx + 12) % 12
		return diff + 1
	}

	// Find Sun longitude for combustion checks (always uses sidereal — same frame).
	var sunLon float64
	for _, p := range positions {
		if p.Name == "Sun" {
			sunLon = p.Longitude
			break
		}
	}

	planets := make([]domain.VedicPlanetPlacement, 0, len(positions))
	for _, p := range positions {
		signName := signFromLongitude(p.Longitude)
		signIdx := int(normalize360(p.Longitude) / 30)
		degInSign := degreeInSign(p.Longitude)
		nak := nakshatraOf(p.Longitude)
		planets = append(planets, domain.VedicPlanetPlacement{
			Name:         p.Name,
			Sanskrit:     grahaSanskrit[p.Name],
			Sign:         signName,
			SignSanskrit: signSanskrit[signIdx],
			Degree:       round2(degInSign),
			Longitude:    round2(normalize360(p.Longitude)),
			House:        houseOfSign(p.Longitude),
			Retrograde:   p.Retrograde,
			Combust:      isCombust(p.Name, p.Longitude, sunLon),
			Nakshatra:    nak,
			Pada:         padaOf(p.Longitude),
			Dignity:      dignityOf(p.Name, signName, degInSign),
		})
	}

	// Build Bhavas (12 Whole Sign houses).
	bhavas := make([]domain.VedicBhava, 12)
	for i := 0; i < 12; i++ {
		bhavaSignIdx := (ascSignIdx + i) % 12
		signName := signs[bhavaSignIdx]
		bhavaNum := i + 1
		// collect planets in this house
		var occ []string
		for _, p := range planets {
			if p.House == bhavaNum {
				occ = append(occ, p.Name)
			}
		}
		bhavas[i] = domain.VedicBhava{
			Number:       bhavaNum,
			Sign:         signName,
			SignSanskrit: signSanskrit[bhavaSignIdx],
			Lord:         signLord[signName],
			Description:  bhavaSignifications[bhavaNum],
			Planets:      occ,
		}
	}

	// Aspects (graha drishti).
	aspects := computeDrishti(planets)

	// AtmaKaraka: highest-degree planet among Sun..Saturn + Rahu (Ketu excluded
	// in the Parashari/Jaimini convention). Degree means deg-in-sign (0..30).
	atmaKaraka := ""
	highest := -1.0
	for _, p := range planets {
		if p.Name == "Ketu" {
			continue
		}
		if p.Degree > highest {
			highest = p.Degree
			atmaKaraka = p.Name
		}
	}

	// Lagna details
	ascSign := signs[ascSignIdx]
	lagna := domain.VedicLagna{
		Sign:         ascSign,
		SignSanskrit: signSanskrit[ascSignIdx],
		Degree:       round2(degreeInSign(ascLon)),
		Longitude:    round2(normalize360(ascLon)),
		Lord:         signLord[ascSign],
		Nakshatra:    nakshatraOf(ascLon),
		Pada:         padaOf(ascLon),
	}

	return &domain.VedicChart{
		Ayanamsa:      ayanamsaLabel(ayanamsa),
		AyanamsaValue: round2(ayanamsaVal),
		Lagna:         lagna,
		Planets:       planets,
		Bhavas:        bhavas,
		Aspects:       aspects,
		AtmaKaraka:    atmaKaraka,
		Varga:         varga,
		VargaName:     vargaName(varga),
	}
}
