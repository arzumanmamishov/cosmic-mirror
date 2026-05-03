package swisseph

import (
	"context"
	"fmt"
	"time"

	"github.com/mshafiee/swephgo"

	"cosmic-mirror/internal/domain"
)

// Divisional chart (varga) computation. Each varga subdivides every 30° sign
// into N equal parts and re-maps each part to a sign per Parashara's rules in
// BPHS chapters 6 (Varga) and following. The resulting longitude is plugged
// back into buildVedicChart to produce a complete sub-chart.

// vargaSignFn maps a Rasi-frame longitude (0..360) to a Varga-frame longitude.
// The output longitude has the integer part of (signIdx * 30) plus the
// remainder mod 30 for placement clarity. Many texts treat varga charts as
// pure sign-mapping (no intra-sign degrees), but storing the proportional
// position lets the renderer continue to show "degree in sign" if desired.
type vargaSignFn func(longitude float64) float64

// vargaMappers holds the per-divisor sign-mapping rule. Distances start at the
// sign in question (signIdx 0 = Aries, etc).
var vargaMappers = map[int]vargaSignFn{
	1:  vargaD1,
	2:  vargaD2,
	3:  vargaD3,
	4:  vargaD4,
	7:  vargaD7,
	9:  vargaD9,
	10: vargaD10,
	12: vargaD12,
	16: vargaD16,
	20: vargaD20,
	24: vargaD24,
	27: vargaD27,
	30: vargaD30,
	40: vargaD40,
	45: vargaD45,
	60: vargaD60,
}

// remap takes the planet's Rasi longitude and produces the longitude as it
// would appear in the varga chart. The fractional position within the new
// 30° sign is preserved as `(part_index_within_sign + 0.5) * 30 / N` so the
// nakshatra/pada lookups still produce something meaningful, but the chart
// rendering should treat varga positions as sign-only.
func remap(longitude float64, divisor int, partIdx, newSignIdx int) float64 {
	// Place the planet at the proportional middle of its part within the new
	// sign. Some apps use the actual proportional offset; either is valid.
	withinSignDeg := (float64(partIdx) + 0.5) * (30.0 / float64(divisor))
	return float64(newSignIdx)*30 + withinSignDeg
}

// signOf returns the 0-indexed sign (0=Aries..11=Pisces) of a longitude.
func signOf(longitude float64) int {
	return int(normalize360(longitude) / 30)
}

// vargaD1: Rasi — identity mapping.
func vargaD1(lon float64) float64 { return normalize360(lon) }

// vargaD2: Hora.
// Odd signs (Aries, Gemini, Leo, Libra, Sag, Aquarius): 0-15° → Leo (Sun),
// 15-30° → Cancer (Moon). Even signs reverse: 0-15° → Cancer, 15-30° → Leo.
func vargaD2(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	odd := signIdx%2 == 0 // 0=Aries (odd in 1-indexed), 1=Taurus (even)...
	firstHalf := deg < 15
	var newSign int
	if odd {
		if firstHalf {
			newSign = 4 // Leo
		} else {
			newSign = 3 // Cancer
		}
	} else {
		if firstHalf {
			newSign = 3 // Cancer
		} else {
			newSign = 4 // Leo
		}
	}
	partIdx := 0
	if !firstHalf {
		partIdx = 1
	}
	return remap(lon, 2, partIdx, newSign)
}

// vargaD3: Drekkana. Each sign split into 3 × 10°.
// 0-10° → same sign, 10-20° → 5th from same sign, 20-30° → 9th from same sign.
func vargaD3(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 10)
	offsets := [3]int{0, 4, 8} // 1st, 5th, 9th
	newSign := (signIdx + offsets[partIdx]) % 12
	return remap(lon, 3, partIdx, newSign)
}

// vargaD4: Chaturthamsa. Each sign split into 4 × 7.5°.
// Mapping: same sign, 4th, 7th, 10th from itself (kendras).
func vargaD4(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 7.5)
	if partIdx > 3 {
		partIdx = 3
	}
	offsets := [4]int{0, 3, 6, 9}
	newSign := (signIdx + offsets[partIdx]) % 12
	return remap(lon, 4, partIdx, newSign)
}

// vargaD7: Saptamsa.
// Odd signs: counting begins from same sign. Even signs: from 7th from same sign.
func vargaD7(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / (30.0 / 7.0))
	if partIdx > 6 {
		partIdx = 6
	}
	start := signIdx
	if signIdx%2 == 1 { // even-indexed (1=Taurus, 3=Cancer, ...) — but Aries idx=0 is odd in 1-indexed
		// Vedic "odd sign" = Aries, Gemini, Leo, ... = signIdx 0,2,4,6,8,10
		// "even sign" = signIdx 1,3,5,7,9,11
		start = (signIdx + 6) % 12
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 7, partIdx, newSign)
}

// vargaD9: Navamsa. Critical for marriage / dharma.
// Movable signs (Aries, Cancer, Libra, Capricorn): start from same sign.
// Fixed signs (Taurus, Leo, Scorpio, Aquarius): start from 9th sign.
// Dual signs (Gemini, Virgo, Sag, Pisces): start from 5th sign.
func vargaD9(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / (30.0 / 9.0))
	if partIdx > 8 {
		partIdx = 8
	}
	mode := signIdx % 3 // 0=movable, 1=fixed, 2=dual
	var start int
	switch mode {
	case 0: // movable
		start = signIdx
	case 1: // fixed
		start = (signIdx + 8) % 12 // 9th from
	case 2: // dual
		start = (signIdx + 4) % 12 // 5th from
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 9, partIdx, newSign)
}

// vargaD10: Dasamsa. Career / achievements.
// Odd signs: count from same sign. Even signs: count from 9th sign.
func vargaD10(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 3)
	if partIdx > 9 {
		partIdx = 9
	}
	start := signIdx
	if signIdx%2 == 1 { // even sign
		start = (signIdx + 8) % 12
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 10, partIdx, newSign)
}

// vargaD12: Dvadasamsa. Parents / lineage.
// Counting always begins from the same sign; each part is 2.5°.
func vargaD12(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 2.5)
	if partIdx > 11 {
		partIdx = 11
	}
	newSign := (signIdx + partIdx) % 12
	return remap(lon, 12, partIdx, newSign)
}

// vargaD16: Shodasamsa. Vehicles / comforts.
// Movable: from Aries. Fixed: from Leo. Dual: from Sagittarius.
func vargaD16(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 1.875)
	if partIdx > 15 {
		partIdx = 15
	}
	var start int
	switch signIdx % 3 {
	case 0:
		start = 0 // Aries
	case 1:
		start = 4 // Leo
	case 2:
		start = 8 // Sagittarius
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 16, partIdx, newSign)
}

// vargaD20: Vimsamsa. Spirituality.
// Movable: from Aries. Fixed: from Sagittarius. Dual: from Leo.
func vargaD20(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 1.5)
	if partIdx > 19 {
		partIdx = 19
	}
	var start int
	switch signIdx % 3 {
	case 0:
		start = 0
	case 1:
		start = 8
	case 2:
		start = 4
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 20, partIdx, newSign)
}

// vargaD24: Chaturvimsamsa. Education.
// Odd signs: from Leo. Even signs: from Cancer.
func vargaD24(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 1.25)
	if partIdx > 23 {
		partIdx = 23
	}
	start := 4 // Leo
	if signIdx%2 == 1 {
		start = 3 // Cancer
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 24, partIdx, newSign)
}

// vargaD27: Bhamsa / Saptavimsamsa. Strengths and weaknesses.
// Fire signs (Ar/Le/Sg): from Aries. Earth (Ta/Vi/Cp): from Cancer.
// Air (Ge/Li/Aq): from Libra. Water (Cn/Sc/Pi): from Capricorn.
func vargaD27(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / (30.0 / 27.0))
	if partIdx > 26 {
		partIdx = 26
	}
	element := signIdx % 4 // 0=fire, 1=earth, 2=air, 3=water (matches signIdx%4 mapping for Aries..Pisces)
	starts := [4]int{0, 3, 6, 9}
	newSign := (starts[element] + partIdx) % 12
	return remap(lon, 27, partIdx, newSign)
}

// vargaD30: Trimsamsa. Misfortunes / sins. Special rule: degrees, not equal divisions.
// Odd signs: 0-5° Mars (Aries), 5-10° Saturn (Aquarius), 10-18° Jupiter (Sagittarius),
// 18-25° Mercury (Gemini), 25-30° Venus (Libra).
// Even signs: 0-5° Venus (Taurus), 5-12° Mercury (Virgo), 12-20° Jupiter (Pisces),
// 20-25° Saturn (Capricorn), 25-30° Mars (Scorpio).
func vargaD30(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	odd := signIdx%2 == 0
	var newSign int
	var partIdx int
	if odd {
		switch {
		case deg < 5:
			newSign = 0 // Aries (Mars)
			partIdx = 0
		case deg < 10:
			newSign = 10 // Aquarius (Saturn)
			partIdx = 1
		case deg < 18:
			newSign = 8 // Sagittarius (Jupiter)
			partIdx = 2
		case deg < 25:
			newSign = 2 // Gemini (Mercury)
			partIdx = 3
		default:
			newSign = 6 // Libra (Venus)
			partIdx = 4
		}
	} else {
		switch {
		case deg < 5:
			newSign = 1 // Taurus (Venus)
			partIdx = 0
		case deg < 12:
			newSign = 5 // Virgo (Mercury)
			partIdx = 1
		case deg < 20:
			newSign = 11 // Pisces (Jupiter)
			partIdx = 2
		case deg < 25:
			newSign = 9 // Capricorn (Saturn)
			partIdx = 3
		default:
			newSign = 7 // Scorpio (Mars)
			partIdx = 4
		}
	}
	return remap(lon, 30, partIdx, newSign)
}

// vargaD40: Khavedamsa. Maternal legacy. Each part is 0.75°.
// Odd signs: from Aries. Even signs: from Libra.
func vargaD40(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 0.75)
	if partIdx > 39 {
		partIdx = 39
	}
	start := 0
	if signIdx%2 == 1 {
		start = 6 // Libra
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 40, partIdx, newSign)
}

// vargaD45: Akshavedamsa. Paternal legacy. Each part is ~0.667°.
// Movable: from Aries. Fixed: from Leo. Dual: from Sagittarius.
func vargaD45(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / (30.0 / 45.0))
	if partIdx > 44 {
		partIdx = 44
	}
	var start int
	switch signIdx % 3 {
	case 0:
		start = 0
	case 1:
		start = 4
	case 2:
		start = 8
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 45, partIdx, newSign)
}

// vargaD60: Shashtiamsa. Past karma / general purpose. Each part is 0.5°.
// Counting: from same sign for odd, from 12th sign (one before) for even.
// (Some traditions use a more complex 60-deity rule; we use the standard
// sign-mapping which is sufficient for the chart layout.)
func vargaD60(lon float64) float64 {
	signIdx := signOf(lon)
	deg := degreeInSign(lon)
	partIdx := int(deg / 0.5)
	if partIdx > 59 {
		partIdx = 59
	}
	start := signIdx
	if signIdx%2 == 1 {
		start = (signIdx + 11) % 12
	}
	newSign := (start + partIdx) % 12
	return remap(lon, 60, partIdx, newSign)
}

// GetDivisionalChart computes a Shodashvarga divisional chart for the given
// birth data. divisor must be in {2,3,4,7,9,10,12,16,20,24,27,30,40,45,60}.
// D1 is served by GetVedicChart.
func (c *Client) GetDivisionalChart(
	ctx context.Context,
	birthDate time.Time,
	birthHour, birthMin int,
	lat, lon, tzone float64,
	ayanamsa, divisor int,
) (*domain.VedicChart, error) {
	if err := c.Init(); err != nil {
		return nil, fmt.Errorf("swisseph init: %w", err)
	}
	mapper, ok := vargaMappers[divisor]
	if !ok {
		return nil, fmt.Errorf("unsupported varga divisor: D%d", divisor)
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

	// 1) Compute Rasi (D1) sidereal positions.
	rasiPositions, ayanamsaVal, err := computeSiderealPlanets(jdUT, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("rasi for varga D%d: %w", divisor, err)
	}
	ascLon, err := computeSiderealAscendant(jdUT, lat, lon, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("ascendant for varga D%d: %w", divisor, err)
	}

	// 2) Re-map every position (including Asc) through the varga rule.
	mapped := make([]planetPosition, len(rasiPositions))
	for i, p := range rasiPositions {
		mapped[i] = planetPosition{
			Name:       p.Name,
			Longitude:  mapper(p.Longitude),
			Speed:      p.Speed,
			Retrograde: p.Retrograde,
		}
	}
	mappedAsc := mapper(ascLon)

	return buildVedicChart(mapped, mappedAsc, ayanamsa, ayanamsaVal, divisor), nil
}
