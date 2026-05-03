package swisseph

// signSanskrit maps each of the 12 zodiac signs to its Sanskrit (rashi) name.
// Index matches signFromLongitude / the `signs` array (0=Aries..11=Pisces).
var signSanskrit = [12]string{
	"Mesha",     // Aries
	"Vrishabha", // Taurus
	"Mithuna",   // Gemini
	"Karka",     // Cancer
	"Simha",     // Leo
	"Kanya",     // Virgo
	"Tula",      // Libra
	"Vrishchika", // Scorpio
	"Dhanu",     // Sagittarius
	"Makara",    // Capricorn
	"Kumbha",    // Aquarius
	"Meena",     // Pisces
}

// signLord returns the classical (Vedic) ruling planet of each sign.
// Mars rules Aries+Scorpio, Venus rules Taurus+Libra, Mercury rules Gemini+Virgo,
// Moon rules Cancer, Sun rules Leo, Jupiter rules Sagittarius+Pisces,
// Saturn rules Capricorn+Aquarius. Outer planets are not used.
var signLord = map[string]string{
	"Aries":       "Mars",
	"Taurus":      "Venus",
	"Gemini":      "Mercury",
	"Cancer":      "Moon",
	"Leo":         "Sun",
	"Virgo":       "Mercury",
	"Libra":       "Venus",
	"Scorpio":     "Mars",
	"Sagittarius": "Jupiter",
	"Capricorn":   "Saturn",
	"Aquarius":    "Saturn",
	"Pisces":      "Jupiter",
}

// grahaSanskrit maps the English graha name to its Sanskrit equivalent.
var grahaSanskrit = map[string]string{
	"Sun":     "Surya",
	"Moon":    "Chandra",
	"Mars":    "Mangala",
	"Mercury": "Budha",
	"Jupiter": "Guru",
	"Venus":   "Shukra",
	"Saturn":  "Shani",
	"Rahu":    "Rahu",
	"Ketu":    "Ketu",
}

// bhavaSignifications gives the canonical meanings of each of the 12 Bhavas
// (houses) in Vedic astrology. Used by the Bhavas tab in the UI.
var bhavaSignifications = [13]string{
	"", // index 0 unused
	"Self, body, personality (Tanu Bhava)",
	"Wealth, family, speech (Dhana Bhava)",
	"Siblings, courage, communication (Sahaja Bhava)",
	"Home, mother, comforts (Sukha Bhava)",
	"Children, intellect, dharma (Putra Bhava)",
	"Enemies, debts, illness (Ari Bhava)",
	"Spouse, partnerships (Yuvati Bhava)",
	"Longevity, transformation, occult (Ayur Bhava)",
	"Fortune, dharma, father (Dharma Bhava)",
	"Career, status, action (Karma Bhava)",
	"Gains, friends, aspirations (Labha Bhava)",
	"Loss, liberation, foreign lands (Vyaya Bhava)",
}

// ayanamsaLabel turns a swephgo SE_SIDM_* constant into a human label.
func ayanamsaLabel(mode int) string {
	switch mode {
	case 0:
		return "Fagan-Bradley"
	case 1:
		return "Lahiri"
	case 3:
		return "Raman"
	case 5:
		return "Krishnamurti"
	default:
		return "Custom"
	}
}

// ayanamsaFromString converts an API query string to a swephgo SE_SIDM_*
// constant. Falls back to Lahiri (the modern Vedic standard) on unknown input.
func ayanamsaFromString(s string) int {
	switch s {
	case "fagan", "fagan-bradley", "fagan_bradley":
		return 0 // SeSidmFaganBradley
	case "raman":
		return 3 // SeSidmRaman
	case "krishnamurti", "kp":
		return 5 // SeSidmKrishnamurti
	case "", "lahiri":
		return 1 // SeSidmLahiri
	default:
		return 1
	}
}
