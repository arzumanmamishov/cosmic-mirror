// Package swisseph wraps the Swiss Ephemeris C library to compute precise
// astrological natal charts. It produces the same output shape as the existing
// AstrologyAPI provider so that ChartService can be swapped without changes.
//
// Calculations performed:
//   - Planet positions (longitude in zodiac, sign, retrograde flag, house)
//   - 12 house cusps via Placidus (configurable)
//   - All major aspects (conjunction, sextile, square, trine, opposition, quincunx)
//   - Element distribution (fire, earth, air, water as percentages)
//
// Thread safety: the underlying C library is not thread-safe. The package
// serializes all calls through a single mutex.
package swisseph

import (
	"context"
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/mshafiee/swephgo"

	"cosmic-mirror/internal/domain"
)

// Client computes natal charts using the Swiss Ephemeris.
type Client struct {
	ephemerisPath string
	// pathBytes pins the null-terminated byte slice passed to swe_set_ephe_path.
	// The C library stores a pointer to this memory rather than copying it, so
	// it must live as long as the client itself.
	pathBytes   []byte
	houseSystem HouseSystem
	initOnce    sync.Once
	initErr     error
}

// NewClient constructs a Swiss Ephemeris client. ephemerisPath must point to a
// directory containing the .se1 data files (sepl_*.se1, semo_*.se1, etc).
func NewClient(ephemerisPath string) *Client {
	return &Client{
		ephemerisPath: ephemerisPath,
		houseSystem:   HousePlacidus,
	}
}

// Init configures the Swiss Ephemeris with the data file path. Safe to call
// multiple times; the actual setup runs once.
func (c *Client) Init() error {
	c.initOnce.Do(func() {
		if c.ephemerisPath == "" {
			c.initErr = fmt.Errorf("ephemeris path is not set")
			return
		}
		// The C library reads the SE_EPHE_PATH environment variable with
		// highest priority. We export it here as a defense-in-depth measure
		// in case docker-compose or the operator forgot to set it.
		_ = os.Setenv("SE_EPHE_PATH", c.ephemerisPath)
		// Pin the path bytes on the client struct so the underlying memory
		// outlives this function. Swiss Ephemeris keeps the pointer.
		c.pathBytes = append([]byte(c.ephemerisPath), 0)
		swephgo.SetEphePath(c.pathBytes)
	})
	return c.initErr
}

// Close releases Swiss Ephemeris resources. Should be called on application
// shutdown.
func (c *Client) Close() {
	computeMu.Lock()
	defer computeMu.Unlock()
	swephgo.Close()
}

// GetNatalChart computes the full natal chart for the given birth data.
// All times must be UTC; tzone is the offset in hours (e.g. -8.0 for PST).
//
// Implementation contract: returned shape matches the prior AstrologyAPI
// provider exactly, so ChartService consumers don't need to change.
func (c *Client) GetNatalChart(
	ctx context.Context,
	birthDate time.Time,
	birthHour, birthMin int,
	lat, lon, tzone float64,
) (*domain.NatalChart, error) {
	if err := c.Init(); err != nil {
		return nil, fmt.Errorf("swisseph init: %w", err)
	}

	// Convert local birth time to a Universal Time Julian Day.
	// Swiss Ephemeris expects UT, so we subtract the timezone offset.
	hourLocal := float64(birthHour) + float64(birthMin)/60.0
	hourUT := hourLocal - tzone

	jdUT := swephgo.Julday(
		birthDate.Year(),
		int(birthDate.Month()),
		birthDate.Day(),
		hourUT,
		swephgo.SeGregCal,
	)

	// 1) Compute planet positions
	planetPositions, err := computePlanets(jdUT)
	if err != nil {
		return nil, fmt.Errorf("planets: %w", err)
	}

	// 2) Compute house cusps
	houses, err := computeHouses(jdUT, lat, lon, c.houseSystem)
	if err != nil {
		return nil, fmt.Errorf("houses: %w", err)
	}

	// 3) Compute aspects between planets
	aspectMatches := computeAspects(planetPositions)

	// 4) Build the domain chart
	chart := &domain.NatalChart{
		Planets:  buildPlanetPlacements(planetPositions, houses.Cusps),
		Houses:   buildHouses(houses.Cusps),
		Aspects:  buildAspects(aspectMatches),
		Elements: calculateElements(planetPositions),
	}

	return chart, nil
}

// --- Domain conversion helpers ---

func buildPlanetPlacements(positions []planetPosition, cusps [13]float64) []domain.PlanetPlacement {
	out := make([]domain.PlanetPlacement, 0, len(positions))
	for _, p := range positions {
		out = append(out, domain.PlanetPlacement{
			Name:       p.Name,
			Sign:       signFromLongitude(p.Longitude),
			Degree:     round2(degreeInSign(p.Longitude)),
			House:      houseForLongitude(p.Longitude, cusps),
			Retrograde: p.Retrograde,
		})
	}
	return out
}

func buildHouses(cusps [13]float64) []domain.House {
	out := make([]domain.House, 0, 12)
	for i := 1; i <= 12; i++ {
		out = append(out, domain.House{
			Number: i,
			Sign:   signFromLongitude(cusps[i]),
			Degree: round2(degreeInSign(cusps[i])),
		})
	}
	return out
}

func buildAspects(matches []aspectMatch) []domain.Aspect {
	out := make([]domain.Aspect, 0, len(matches))
	for _, m := range matches {
		out = append(out, domain.Aspect{
			Planet1: m.Planet1,
			Planet2: m.Planet2,
			Type:    m.Type,
			Orb:     m.Orb,
		})
	}
	return out
}

// calculateElements returns the percentage distribution of planets across the
// four classical elements. Only the seven traditional planets count toward the
// totals (Sun through Saturn) since outer planets and points belong to whole
// generations.
func calculateElements(positions []planetPosition) map[string]float64 {
	counts := map[string]float64{"fire": 0, "earth": 0, "air": 0, "water": 0}

	traditional := map[string]bool{
		"Sun": true, "Moon": true, "Mercury": true, "Venus": true,
		"Mars": true, "Jupiter": true, "Saturn": true,
	}

	for _, p := range positions {
		if !traditional[p.Name] {
			continue
		}
		sign := signFromLongitude(p.Longitude)
		if el, ok := signElements[sign]; ok {
			counts[el]++
		}
	}

	total := counts["fire"] + counts["earth"] + counts["air"] + counts["water"]
	if total == 0 {
		return counts
	}
	for k := range counts {
		counts[k] = round2(counts[k] / total * 100)
	}
	return counts
}
