package swisseph

import (
	"fmt"
	"math"
	"sort"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/mshafiee/swephgo"
)

// TransitEvent is a single astrologically-meaningful moment we hand to
// the AI as ground truth. The model writes prose around these — it
// never invents dates or aspects.
type TransitEvent struct {
	Date        time.Time `json:"date"`
	Type        string    `json:"type"`        // ingress | lunation | retrograde | aspect
	Body        string    `json:"body"`        // transiting planet
	NatalPoint  string    `json:"natal_point,omitempty"`
	Aspect      string    `json:"aspect,omitempty"` // conjunction | sextile | square | trine | opposition
	Sign        string    `json:"sign,omitempty"`
	Phase       string    `json:"phase,omitempty"`  // new_moon | full_moon | retrograde | direct
	Description string    `json:"description"`
}

// transitBody is a planet we treat as "transiting" — i.e. its current
// motion across the sky is what we narrate against the user's natal
// chart. Inner planets are noted for stations + lunations only; outer
// planets get full aspect-to-natal coverage because their slow motion
// makes their hits feel like real life chapters.
type transitBody struct {
	Name  string
	ID    int
	Outer bool
}

var transitBodies = []transitBody{
	{Name: "Sun", ID: swephgo.SeSun},
	{Name: "Moon", ID: swephgo.SeMoon},
	{Name: "Mercury", ID: swephgo.SeMercury},
	{Name: "Venus", ID: swephgo.SeVenus},
	{Name: "Mars", ID: swephgo.SeMars},
	{Name: "Jupiter", ID: swephgo.SeJupiter, Outer: true},
	{Name: "Saturn", ID: swephgo.SeSaturn, Outer: true},
	{Name: "Uranus", ID: swephgo.SeUranus, Outer: true},
	{Name: "Neptune", ID: swephgo.SeNeptune, Outer: true},
	{Name: "Pluto", ID: swephgo.SePluto, Outer: true},
	{Name: "Chiron", ID: swephgo.SeChiron, Outer: true},
}

// transitAspectAngles is the standard set we narrate for transits:
// conjunction (0), sextile (60), square (90), trine (120), opposition
// (180). 1° orb so we only emit tight, narratable hits. Kept separate
// from the natal `majorAspects` (in aspects.go) because that one carries
// per-aspect orbs sized for natal-vs-natal pairings, while transits use
// a single tight orb to avoid spamming overlapping events.
var transitAspectAngles = []struct {
	Angle float64
	Name  string
}{
	{0, "conjunction"},
	{60, "sextile"},
	{90, "square"},
	{120, "trine"},
	{180, "opposition"},
}

const aspectOrb = 1.0

// ComputeTransitEvents walks the given window day-by-day and returns
// every transit event we'd want to surface in a forecast. The events
// list is sorted by date.
//
// The caller is responsible for picking sensible start/end (e.g. now
// to now+30d for the short window, now to now+1y for the yearly
// forecast).
func ComputeTransitEvents(
	natal *domain.NatalChart,
	start, end time.Time,
) ([]TransitEvent, error) {
	if !end.After(start) {
		return nil, fmt.Errorf("end must be after start")
	}
	if natal == nil {
		return nil, fmt.Errorf("natal chart required")
	}

	natalPoints := natalReferencePoints(natal)

	out := make([]TransitEvent, 0, 32)
	seenAspect := map[string]time.Time{} // dedup key → last-emitted date

	var prev map[string]planetPosition
	var prevDate time.Time
	day := start
	for !day.After(end) {
		positions, err := computeBodiesAt(day)
		if err != nil {
			return nil, err
		}

		if prev != nil {
			// Sign-change ingress: only meaningful for outer planets +
			// Jupiter (inner-planet ingresses are weekly noise).
			for _, b := range transitBodies {
				if !b.Outer {
					continue
				}
				p0 := prev[b.Name]
				p1 := positions[b.Name]
				s0 := signIndexFromLongitude(p0.Longitude)
				s1 := signIndexFromLongitude(p1.Longitude)
				if s0 != s1 {
					out = append(out, TransitEvent{
						Date:        day,
						Type:        "ingress",
						Body:        b.Name,
						Sign:        signNameFromIndex(s1),
						Description: fmt.Sprintf("%s enters %s", b.Name, signNameFromIndex(s1)),
					})
				}
			}

			// Retrograde stations for Mercury/Venus/Mars (inner) and
			// the four outer planets. Detected by speed sign flip.
			for _, b := range transitBodies {
				if b.Name == "Sun" || b.Name == "Moon" {
					continue
				}
				p0 := prev[b.Name]
				p1 := positions[b.Name]
				if (p0.Speed >= 0) != (p1.Speed >= 0) {
					phase := "direct"
					if p1.Speed < 0 {
						phase = "retrograde"
					}
					out = append(out, TransitEvent{
						Date:        day,
						Type:        "retrograde",
						Body:        b.Name,
						Phase:       phase,
						Description: fmt.Sprintf("%s stations %s", b.Name, phase),
					})
				}
			}

			// Lunations — Moon catches the Sun (new) or opposes it (full).
			// We watch the Moon-Sun angular delta cross 0 / 180.
			delta0 := normalizeSignedDelta(prev["Moon"].Longitude - prev["Sun"].Longitude)
			delta1 := normalizeSignedDelta(positions["Moon"].Longitude - positions["Sun"].Longitude)
			if crossesZero(delta0, delta1) {
				out = append(out, TransitEvent{
					Date:        day,
					Type:        "lunation",
					Body:        "Moon",
					Phase:       "new_moon",
					Sign:        signNameFromIndex(signIndexFromLongitude(positions["Sun"].Longitude)),
					Description: fmt.Sprintf("New moon in %s",
						signNameFromIndex(signIndexFromLongitude(positions["Sun"].Longitude))),
				})
			}
			// Full moon: the Moon-Sun delta passes 180°. We can't detect
			// this with crossesValue(..., 180) because normalizeSignedDelta's
			// branch cut sits exactly at ±180 — the delta wraps from ~+179
			// to ~-179, which the >90° guard rejects as an artifact. Shift
			// the delta by 180° so opposition becomes a clean zero-crossing
			// away from the cut.
			fullDelta0 := normalizeSignedDelta(delta0 - 180)
			fullDelta1 := normalizeSignedDelta(delta1 - 180)
			if crossesZero(fullDelta0, fullDelta1) {
				out = append(out, TransitEvent{
					Date:        day,
					Type:        "lunation",
					Body:        "Moon",
					Phase:       "full_moon",
					Sign:        signNameFromIndex(signIndexFromLongitude(positions["Moon"].Longitude)),
					Description: fmt.Sprintf("Full moon in %s",
						signNameFromIndex(signIndexFromLongitude(positions["Moon"].Longitude))),
				})
			}

			// Outer-planet aspects to natal points. Daily resolution is
			// enough — Jupiter is the fastest outer at ~5° / month, so
			// it crosses a 1° aspect orb over ~6 days.
			for _, b := range transitBodies {
				if !b.Outer {
					continue
				}
				p := positions[b.Name]
				for _, np := range natalPoints {
					for _, a := range transitAspectAngles {
						orb := angularOrb(p.Longitude, np.Longitude, a.Angle)
						if orb > aspectOrb {
							continue
						}
						key := fmt.Sprintf("%s|%s|%s", b.Name, np.Name, a.Name)
						if last, ok := seenAspect[key]; ok &&
							day.Sub(last) < 60*24*time.Hour {
							continue // already emitted recently
						}
						seenAspect[key] = day
						out = append(out, TransitEvent{
							Date:       day,
							Type:       "aspect",
							Body:       b.Name,
							NatalPoint: np.Name,
							Aspect:     a.Name,
							Description: fmt.Sprintf(
								"%s %s natal %s (%.1f° orb)",
								b.Name, a.Name, np.Name, orb,
							),
						})
					}
				}
			}
		}

		prev = positions
		prevDate = day
		day = day.AddDate(0, 0, 1)
	}
	_ = prevDate // silence unused

	sort.Slice(out, func(i, j int) bool {
		return out[i].Date.Before(out[j].Date)
	})
	return out, nil
}

// natalRef is a point on the natal chart we check transits against.
type natalRef struct {
	Name      string
	Longitude float64
}

// natalReferencePoints picks the chart points worth tracking — the
// luminaries, the chart angles, and the personal/social planets.
// Slower outer placements are skipped because they only get touched
// by even slower transits.
func natalReferencePoints(natal *domain.NatalChart) []natalRef {
	wanted := map[string]bool{
		"Sun":     true,
		"Moon":    true,
		"Mercury": true,
		"Venus":   true,
		"Mars":    true,
		"Jupiter": true,
		"Saturn":  true,
	}
	refs := make([]natalRef, 0, 9)
	for _, pl := range natal.Planets {
		if wanted[pl.Name] {
			refs = append(refs, natalRef{
				Name:      pl.Name,
				Longitude: longitudeFromPlacement(pl.Sign, pl.Degree),
			})
		}
	}
	// Ascendant + MC come from the house cusps. House.Degree is the
	// degree-in-sign, not the raw longitude, so reconstruct via Sign+Degree.
	if len(natal.Houses) >= 10 {
		refs = append(refs, natalRef{
			Name:      "Ascendant",
			Longitude: longitudeFromPlacement(natal.Houses[0].Sign, natal.Houses[0].Degree),
		})
		refs = append(refs, natalRef{
			Name:      "Midheaven",
			Longitude: longitudeFromPlacement(natal.Houses[9].Sign, natal.Houses[9].Degree),
		})
	}
	return refs
}

// computeBodiesAt runs the Swiss Ephemeris for every body in
// transitBodies at noon UT of the given calendar day. Noon is a
// convenient sampling time — it avoids edge cases at the day boundary
// and keeps the longitude error vs. midnight under ~0.2° even for the
// Moon, which is fine for the 1° aspect orb we use.
func computeBodiesAt(day time.Time) (map[string]planetPosition, error) {
	jdUT := julianDayUTNoon(day)
	computeMu.Lock()
	defer computeMu.Unlock()

	flags := swephgo.SeflgSwieph | swephgo.SeflgSpeed
	out := make(map[string]planetPosition, len(transitBodies))

	for _, b := range transitBodies {
		xx := make([]float64, 6)
		serr := make([]byte, 256)
		if ret := swephgo.CalcUt(jdUT, b.ID, flags, xx, serr); ret < 0 {
			return nil, fmt.Errorf("calc %s: %s", b.Name, trimNullBytes(serr))
		}
		out[b.Name] = planetPosition{
			Name:       b.Name,
			Longitude:  xx[0],
			Speed:      xx[3],
			Retrograde: xx[3] < 0,
		}
	}
	return out, nil
}

// julianDayUTNoon converts a calendar date to a Julian Day at 12:00 UT,
// avoiding the cgo round-trip swephgo.Julday would add.
func julianDayUTNoon(t time.Time) float64 {
	y := t.Year()
	m := int(t.Month())
	d := t.Day()
	if m <= 2 {
		y--
		m += 12
	}
	a := y / 100
	b := 2 - a + a/4
	jd := float64(int(365.25*float64(y+4716))) +
		float64(int(30.6001*float64(m+1))) +
		float64(d) + float64(b) - 1524.5
	jd += 12.0 / 24.0
	return jd
}

// signIndexFromLongitude returns the 0..11 zodiac index for a longitude.
// Named with the long suffix to distinguish from the string-arg signIndex in
// vedic_ashtakavarga.go.
func signIndexFromLongitude(longitude float64) int {
	l := math.Mod(longitude, 360)
	if l < 0 {
		l += 360
	}
	return int(l / 30)
}

func signNameFromIndex(idx int) string {
	if idx < 0 || idx >= len(signs) {
		return "—"
	}
	return signs[idx]
}

// signIndexFromName returns the 0..11 index for a zodiac sign name; -1 if not
// found. Used to reconstruct full longitudes from domain.PlanetPlacement which
// only stores Sign + Degree-in-sign.
func signIndexFromName(name string) int {
	for i, s := range signs {
		if s == name {
			return i
		}
	}
	return -1
}

// longitudeFromPlacement reconstructs the 0..360 ecliptic longitude from a
// natal placement's Sign + Degree fields (the natal chart never stores the
// raw longitude — only the sign-relative degree).
func longitudeFromPlacement(sign string, degreeInSign float64) float64 {
	idx := signIndexFromName(sign)
	if idx < 0 {
		return 0
	}
	return float64(idx)*30 + degreeInSign
}

// normalizeSignedDelta returns the shortest angular delta in (-180, 180].
func normalizeSignedDelta(d float64) float64 {
	for d > 180 {
		d -= 360
	}
	for d <= -180 {
		d += 360
	}
	return d
}

// crossesZero returns true if a, b are on opposite sides of 0 AND
// the jump between them is small (less than 90° — anything bigger is
// a wrap-around artifact, not a real crossing).
func crossesZero(a, b float64) bool {
	if math.Abs(a-b) > 90 {
		return false
	}
	return (a < 0 && b >= 0) || (a > 0 && b <= 0)
}

// angularOrb returns the smallest distance between two longitudes
// after subtracting the target aspect angle. Used to detect whether
// |angDistance(a, b) - aspect| is within the orb.
func angularOrb(a, b, aspect float64) float64 {
	d := math.Mod(math.Abs(a-b), 360)
	if d > 180 {
		d = 360 - d
	}
	orb := math.Abs(d - aspect)
	return orb
}
