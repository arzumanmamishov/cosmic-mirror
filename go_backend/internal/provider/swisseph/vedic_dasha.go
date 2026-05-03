package swisseph

import (
	"context"
	"fmt"
	"time"

	"github.com/mshafiee/swephgo"

	"cosmic-mirror/internal/domain"
)

// Vimshottari Dasha is the dominant Vedic predictive system. The 120-year
// cycle is split into 9 Mahadasha periods, each owned by one of the nine
// grahas. The starting graha and birth-balance are determined by the Moon's
// nakshatra at birth.

// vimshottariOrder is the canonical sequence of dasha lords starting from
// Ketu. Every nakshatra maps to one of these as its ruling planet (see
// nakshatra.Ruler), and the dasha cycle proceeds from there.
var vimshottariOrder = []string{
	"Ketu",   // 7y
	"Venus",  // 20y
	"Sun",    // 6y
	"Moon",   // 10y
	"Mars",   // 7y
	"Rahu",   // 18y
	"Jupiter", // 16y
	"Saturn", // 19y
	"Mercury", // 17y
}

// vimshottariYears holds each lord's full mahadasha length in years.
var vimshottariYears = map[string]float64{
	"Ketu":    7,
	"Venus":   20,
	"Sun":     6,
	"Moon":    10,
	"Mars":    7,
	"Rahu":    18,
	"Jupiter": 16,
	"Saturn":  19,
	"Mercury": 17,
}

// vimshottariTotal is the sum (always 120 years).
const vimshottariTotal = 120.0

// indexOfLord returns the position of `lord` in vimshottariOrder.
func indexOfLord(lord string) int {
	for i, l := range vimshottariOrder {
		if l == lord {
			return i
		}
	}
	return 0
}

// addYears advances `t` by a fractional number of solar years using the
// Hindu-conventional 365.25 days/year. We avoid time.AddDate's calendar
// rollover quirks because dasha periods are defined as fractional years, not
// calendar years.
func addYears(t time.Time, years float64) time.Time {
	nanos := years * 365.25 * 24 * float64(time.Hour)
	return t.Add(time.Duration(nanos))
}

// expandDasha builds the dasha tree for a single (parent) period, recursively
// subdividing into child periods up to `maxLevel` (1=maha-only, 2=+antar, 3=+pratyantar).
// `parentLord` is the lord whose period we are subdividing; the first child
// starts at `parentLord` and proceeds in vimshottariOrder.
func expandDasha(parentLord string, parentStart time.Time, parentYears float64, currentLevel, maxLevel int) []domain.DashaPeriod {
	if currentLevel > maxLevel {
		return nil
	}
	startIdx := indexOfLord(parentLord)
	periods := make([]domain.DashaPeriod, 0, 9)
	cursor := parentStart
	for i := 0; i < 9; i++ {
		lord := vimshottariOrder[(startIdx+i)%9]
		// child period length = parentYears * (lord's full years / 120)
		childYears := parentYears * vimshottariYears[lord] / vimshottariTotal
		end := addYears(cursor, childYears)
		p := domain.DashaPeriod{
			Lord:      lord,
			Level:     currentLevel,
			StartDate: cursor,
			EndDate:   end,
		}
		if currentLevel < maxLevel {
			p.Sub = expandDasha(lord, cursor, childYears, currentLevel+1, maxLevel)
		}
		periods = append(periods, p)
		cursor = end
	}
	return periods
}

// computeVimshottariFromMoon computes the full dasha tree given the Moon's
// sidereal longitude and birth time.
//
//   Step 1: identify the birth nakshatra and its ruling lord (= birth dasha lord).
//   Step 2: compute how much of the birth dasha has already elapsed at birth
//           (proportional to the Moon's position within the nakshatra).
//   Step 3: walk the cycle to produce 9 Mahadashas spanning 120 years.
//
// Returns the tree at `levels` depth (1, 2, or 3).
func computeVimshottariFromMoon(moonSiderealLon float64, birthTime time.Time, levels int) *domain.DashaTree {
	if levels < 1 {
		levels = 1
	}
	if levels > 3 {
		levels = 3
	}

	birthNak := nakshatraOf(moonSiderealLon)
	startLord := birthNak.Ruler

	// Position within nakshatra (0..nakshatraSpan).
	withinNak := normalize360(moonSiderealLon)
	withinNak -= float64(int(withinNak/nakshatraSpan)) * nakshatraSpan
	fractionElapsed := withinNak / nakshatraSpan
	fullYears := vimshottariYears[startLord]
	elapsedYears := fullYears * fractionElapsed
	remainingYears := fullYears - elapsedYears

	// The first Mahadasha (the birth dasha) is shortened to remainingYears.
	mahadashas := make([]domain.DashaPeriod, 0, 9)
	cursor := birthTime
	end := addYears(cursor, remainingYears)
	first := domain.DashaPeriod{
		Lord:      startLord,
		Level:     1,
		StartDate: cursor,
		EndDate:   end,
	}
	if levels >= 2 {
		// For the partial-first-mahadasha, antar periods are subdivided
		// proportionally over the *original* full mahadasha and we keep only
		// the antars that fall within the remaining slice.
		fullSubs := expandDasha(startLord, addYears(cursor, -elapsedYears), fullYears, 2, levels)
		for _, s := range fullSubs {
			if s.EndDate.After(birthTime) {
				if s.StartDate.Before(birthTime) {
					s.StartDate = birthTime
				}
				first.Sub = append(first.Sub, s)
			}
		}
	}
	mahadashas = append(mahadashas, first)
	cursor = end

	// Subsequent Mahadashas use full lengths.
	startIdx := indexOfLord(startLord)
	for i := 1; i < 9; i++ {
		lord := vimshottariOrder[(startIdx+i)%9]
		yrs := vimshottariYears[lord]
		end := addYears(cursor, yrs)
		p := domain.DashaPeriod{
			Lord:      lord,
			Level:     1,
			StartDate: cursor,
			EndDate:   end,
		}
		if levels >= 2 {
			p.Sub = expandDasha(lord, cursor, yrs, 2, levels)
		}
		mahadashas = append(mahadashas, p)
		cursor = end
	}

	tree := &domain.DashaTree{
		System:     "Vimshottari",
		Levels:     levels,
		Mahadashas: mahadashas,
	}
	tree.Current = currentDashaPathTree(mahadashas, time.Now())
	return tree
}

// currentDashaPathTree finds the active maha/antar/pratyantar at moment `at`.
func currentDashaPathTree(mahadashas []domain.DashaPeriod, at time.Time) domain.DashaPath {
	path := domain.DashaPath{At: at}
	for _, m := range mahadashas {
		if !at.Before(m.StartDate) && at.Before(m.EndDate) {
			path.Maha = m.Lord
			for _, a := range m.Sub {
				if !at.Before(a.StartDate) && at.Before(a.EndDate) {
					path.Antar = a.Lord
					for _, pp := range a.Sub {
						if !at.Before(pp.StartDate) && at.Before(pp.EndDate) {
							path.Pratyantar = pp.Lord
							return path
						}
					}
					return path
				}
			}
			return path
		}
	}
	return path
}

// ComputeDasha is the public entry point used by the service layer. It looks
// up the Moon's sidereal longitude at birth and produces the full tree.
func (c *Client) ComputeDasha(
	ctx context.Context,
	birthDate time.Time,
	birthHour, birthMin int,
	lat, lon, tzone float64,
	ayanamsa, levels int,
) (*domain.DashaTree, error) {
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

	positions, _, err := computeSiderealPlanets(jdUT, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("dasha planets: %w", err)
	}
	var moonLon float64
	for _, p := range positions {
		if p.Name == "Moon" {
			moonLon = p.Longitude
			break
		}
	}

	// Construct birth time as a real time.Time. We treat the input
	// (birthDate UTC midnight + local hours, then -tzone) as a UTC instant.
	birthInstant := time.Date(
		birthDate.Year(), birthDate.Month(), birthDate.Day(),
		birthHour, birthMin, 0, 0,
		time.UTC,
	).Add(time.Duration(-tzone * float64(time.Hour)))

	tree := computeVimshottariFromMoon(moonLon, birthInstant, levels)
	return tree, nil
}
