package swisseph

import "math"

// Classical Vedic planetary dignities. These tables are used to label each
// graha as exalted / debilitated / own-sign / mooltrikona / friend / enemy /
// neutral, and feed into Shadbala (Sthana Bala).

// exaltationSign maps a graha to the sign in which it is exalted.
var exaltationSign = map[string]string{
	"Sun":     "Aries",
	"Moon":    "Taurus",
	"Mars":    "Capricorn",
	"Mercury": "Virgo",
	"Jupiter": "Cancer",
	"Venus":   "Pisces",
	"Saturn":  "Libra",
	"Rahu":    "Taurus", // most schools; some say Gemini/Scorpio
	"Ketu":    "Scorpio",
}

// exaltationDegree is the deepest point of exaltation (the Paramocha) within
// the exaltation sign, in degrees 0..30.
var exaltationDegree = map[string]float64{
	"Sun":     10,
	"Moon":    3,
	"Mars":    28,
	"Mercury": 15,
	"Jupiter": 5,
	"Venus":   27,
	"Saturn":  20,
	"Rahu":    20,
	"Ketu":    20,
}

// debilitationSign is always 180° from exaltation.
var debilitationSign = map[string]string{
	"Sun":     "Libra",
	"Moon":    "Scorpio",
	"Mars":    "Cancer",
	"Mercury": "Pisces",
	"Jupiter": "Capricorn",
	"Venus":   "Virgo",
	"Saturn":  "Aries",
	"Rahu":    "Scorpio",
	"Ketu":    "Taurus",
}

// ownSigns lists every sign each graha rules. Mars/Venus/Mercury/Jupiter/Saturn
// each rule two; Sun/Moon rule one. Rahu/Ketu have no rulership classically.
var ownSigns = map[string][]string{
	"Sun":     {"Leo"},
	"Moon":    {"Cancer"},
	"Mars":    {"Aries", "Scorpio"},
	"Mercury": {"Gemini", "Virgo"},
	"Jupiter": {"Sagittarius", "Pisces"},
	"Venus":   {"Taurus", "Libra"},
	"Saturn":  {"Capricorn", "Aquarius"},
}

// mooltrikonaSign + range: a graha's special "throne" zone within an own sign.
type mooltrikonaSpec struct {
	Sign     string
	StartDeg float64
	EndDeg   float64
}

var mooltrikona = map[string]mooltrikonaSpec{
	"Sun":     {"Leo", 0, 20},
	"Moon":    {"Taurus", 4, 30},
	"Mars":    {"Aries", 0, 12},
	"Mercury": {"Virgo", 16, 20},
	"Jupiter": {"Sagittarius", 0, 10},
	"Venus":   {"Libra", 0, 15},
	"Saturn":  {"Aquarius", 0, 20},
}

// classicalFriends defines naisargika (natural) friendship per the standard
// table from BPHS. Values: "friend", "enemy", "neutral".
var classicalFriends = map[string]map[string]string{
	"Sun": {
		"Moon": "friend", "Mars": "friend", "Jupiter": "friend",
		"Mercury": "neutral", "Venus": "enemy", "Saturn": "enemy",
	},
	"Moon": {
		"Sun": "friend", "Mercury": "friend",
		"Mars": "neutral", "Jupiter": "neutral", "Venus": "neutral", "Saturn": "neutral",
	},
	"Mars": {
		"Sun": "friend", "Moon": "friend", "Jupiter": "friend",
		"Venus": "neutral", "Saturn": "neutral",
		"Mercury": "enemy",
	},
	"Mercury": {
		"Sun": "friend", "Venus": "friend",
		"Mars": "neutral", "Jupiter": "neutral", "Saturn": "neutral",
		"Moon": "enemy",
	},
	"Jupiter": {
		"Sun": "friend", "Moon": "friend", "Mars": "friend",
		"Saturn": "neutral",
		"Mercury": "enemy", "Venus": "enemy",
	},
	"Venus": {
		"Mercury": "friend", "Saturn": "friend",
		"Mars": "neutral", "Jupiter": "neutral",
		"Sun": "enemy", "Moon": "enemy",
	},
	"Saturn": {
		"Mercury": "friend", "Venus": "friend",
		"Jupiter": "neutral",
		"Sun": "enemy", "Moon": "enemy", "Mars": "enemy",
	},
}

// dignityOf classifies the graha's dignity in a sign at a given degree.
// Priority order: exalted > debilitated > mooltrikona > own > friend > enemy > neutral.
// Rahu/Ketu use only exaltation/debilitation/neutral classically.
func dignityOf(planet, sign string, degInSign float64) string {
	if exaltationSign[planet] == sign {
		return "exalted"
	}
	if debilitationSign[planet] == sign {
		return "debilitated"
	}
	if m, ok := mooltrikona[planet]; ok && m.Sign == sign && degInSign >= m.StartDeg && degInSign < m.EndDeg {
		return "mooltrikona"
	}
	for _, ownSign := range ownSigns[planet] {
		if ownSign == sign {
			return "own"
		}
	}
	// For Rahu/Ketu we stop here.
	if planet == "Rahu" || planet == "Ketu" {
		return "neutral"
	}
	signRuler := signLord[sign]
	if signRuler == "" || signRuler == planet {
		return "neutral"
	}
	if rel, ok := classicalFriends[planet][signRuler]; ok {
		return rel
	}
	return "neutral"
}

// combustionOrb is the threshold (in degrees) within which a graha is
// considered combust by the Sun. Standard BPHS values; some schools differ.
var combustionOrb = map[string]float64{
	"Moon":    12,
	"Mars":    17,
	"Mercury": 14, // 12 if retrograde, simplified to 14 here
	"Jupiter": 11,
	"Venus":   10, // 8 if retrograde
	"Saturn":  15,
}

// isCombust returns true if the planet's longitude is within the combustion
// orb of the Sun's longitude. Rahu/Ketu are never combust by tradition.
func isCombust(planet string, planetLongitude, sunLongitude float64) bool {
	if planet == "Sun" || planet == "Rahu" || planet == "Ketu" {
		return false
	}
	orb, ok := combustionOrb[planet]
	if !ok {
		return false
	}
	return math.Abs(angularDistance(planetLongitude, sunLongitude)) <= orb
}
