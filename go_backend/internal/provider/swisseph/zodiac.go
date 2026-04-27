package swisseph

// signs in zodiac order (0 = Aries, 11 = Pisces)
var signs = [12]string{
	"Aries", "Taurus", "Gemini", "Cancer",
	"Leo", "Virgo", "Libra", "Scorpio",
	"Sagittarius", "Capricorn", "Aquarius", "Pisces",
}

// signElements maps each sign to its classical element.
var signElements = map[string]string{
	"Aries": "fire", "Leo": "fire", "Sagittarius": "fire",
	"Taurus": "earth", "Virgo": "earth", "Capricorn": "earth",
	"Gemini": "air", "Libra": "air", "Aquarius": "air",
	"Cancer": "water", "Scorpio": "water", "Pisces": "water",
}

// signFromLongitude returns the zodiac sign for a 0..360 longitude.
func signFromLongitude(longitude float64) string {
	idx := int(normalize360(longitude) / 30)
	if idx < 0 || idx > 11 {
		return ""
	}
	return signs[idx]
}

// degreeInSign returns the degree (0..30) within the sign.
func degreeInSign(longitude float64) float64 {
	lon := normalize360(longitude)
	return lon - float64(int(lon/30))*30
}

// normalize360 wraps a longitude into the [0, 360) range.
func normalize360(lon float64) float64 {
	for lon < 0 {
		lon += 360
	}
	for lon >= 360 {
		lon -= 360
	}
	return lon
}

// houseForLongitude returns the house number (1..12) that contains the given
// ecliptic longitude. cusps[1..12] are the 12 house cusps as longitudes.
//
// A planet sits in house N if its longitude is between cusp[N] and cusp[N+1]
// (where cusp[13] wraps to cusp[1]). The comparison must handle the 360°/0° wrap.
func houseForLongitude(longitude float64, cusps [13]float64) int {
	lon := normalize360(longitude)
	for i := 1; i <= 12; i++ {
		start := normalize360(cusps[i])
		end := normalize360(cusps[(i%12)+1])
		if start <= end {
			if lon >= start && lon < end {
				return i
			}
		} else {
			// Wraps over 0°
			if lon >= start || lon < end {
				return i
			}
		}
	}
	return 1
}
