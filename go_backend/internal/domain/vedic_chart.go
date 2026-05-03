package domain

import "time"

// VedicChart is the full Jyotish (Vedic) natal chart. It is computed in the
// sidereal zodiac and carries Sanskrit names alongside Western labels so the
// front end can render either.
type VedicChart struct {
	Ayanamsa      string                 `json:"ayanamsa"`       // human label: Lahiri / Raman / Krishnamurti / FaganBradley
	AyanamsaValue float64                `json:"ayanamsa_value"` // current ayanamsa offset in degrees at birth
	Lagna         VedicLagna             `json:"lagna"`          // ascendant details
	Planets       []VedicPlanetPlacement `json:"planets"`
	Bhavas        []VedicBhava           `json:"bhavas"`     // 12 houses (Whole Sign)
	Aspects       []VedicAspect          `json:"aspects"`    // graha drishti
	AtmaKaraka    string                 `json:"atma_karaka"` // planet with highest degree-in-sign (soul significator)
	Varga         int                    `json:"varga"`      // 1 = Rasi (D1), 9 = Navamsa, etc.
	VargaName     string                 `json:"varga_name"` // "Rasi", "Navamsa", ...
}

// VedicLagna captures the rising sign with its Sanskrit equivalents and the
// nakshatra+pada that the ascendant degree falls in.
type VedicLagna struct {
	Sign         string         `json:"sign"`          // English (Aries..Pisces)
	SignSanskrit string         `json:"sign_sanskrit"` // Mesha..Meena
	Degree       float64        `json:"degree"`        // 0..30 within sign
	Longitude    float64        `json:"longitude"`     // 0..360 absolute
	Lord         string         `json:"lord"`          // ruling graha
	Nakshatra    VedicNakshatra `json:"nakshatra"`
	Pada         int            `json:"pada"` // 1..4
}

// VedicPlanetPlacement is one graha (planet) in the Vedic chart.
type VedicPlanetPlacement struct {
	Name         string         `json:"name"`          // English: Sun, Moon, ..., Rahu, Ketu
	Sanskrit     string         `json:"sanskrit"`      // Surya, Chandra, ..., Rahu, Ketu
	Sign         string         `json:"sign"`          // English
	SignSanskrit string         `json:"sign_sanskrit"` // Mesha..Meena
	Degree       float64        `json:"degree"`        // 0..30 within sign
	Longitude    float64        `json:"longitude"`     // 0..360 absolute
	House        int            `json:"house"`         // 1..12 bhava
	Retrograde   bool           `json:"retrograde"`
	Combust      bool           `json:"combust"`
	Nakshatra    VedicNakshatra `json:"nakshatra"`
	Pada         int            `json:"pada"`   // 1..4
	Dignity      string         `json:"dignity"` // exalted | debilitated | own | mooltrikona | friend | enemy | neutral
}

// VedicBhava is one of the 12 houses.
type VedicBhava struct {
	Number       int      `json:"number"`         // 1..12
	Sign         string   `json:"sign"`           // English
	SignSanskrit string   `json:"sign_sanskrit"`  // Sanskrit
	Lord         string   `json:"lord"`           // English ruler
	Description  string   `json:"description"`    // significations: self, wealth, ...
	Planets      []string `json:"planets"`        // names of planets currently in this bhava
}

// VedicNakshatra is one of the 27 lunar mansions plus per-instance pada info.
type VedicNakshatra struct {
	Index    int    `json:"index"`     // 1..27
	Name     string `json:"name"`      // Ashwini..Revati
	Ruler    string `json:"ruler"`     // ruling graha (English)
	Deity    string `json:"deity"`
	Symbol   string `json:"symbol"`
	Gana     string `json:"gana"`     // Deva | Manushya | Rakshasa
	Nadi     string `json:"nadi"`     // Adi | Madhya | Antya
	Varna    string `json:"varna"`    // Brahmin | Kshatriya | Vaishya | Shudra
	Animal   string `json:"animal"`
	Gender   string `json:"gender"`   // male | female
	Caste    string `json:"caste"`
}

// VedicAspect is a graha drishti (sign-based aspect). Type is the house-distance
// aspect ("7th", "4th", "8th", "5th", "9th", "3rd", "10th") and Strength is the
// classical fractional weight (1.0 = full, 0.75/0.5/0.25 partial).
type VedicAspect struct {
	From         string  `json:"from"`           // graha name
	FromSanskrit string  `json:"from_sanskrit"`
	To           string  `json:"to"`             // graha name OR "House N"
	ToHouse      int     `json:"to_house"`       // 1..12 if To is a house
	Type         string  `json:"type"`           // "7th" | "4th" | "8th" | "5th" | "9th" | "3rd" | "10th"
	Strength     float64 `json:"strength"`       // 0..1
}

// ===== Phase B: divisional chart helpers =====

// VedicVargaSet bundles the Rasi (D1) chart with any number of computed
// divisional charts (D2..D60). Use this when the API returns multiple vargas
// in a single response.
type VedicVargaSet struct {
	Rasi        VedicChart           `json:"rasi"`
	Divisionals map[string]VedicChart `json:"divisionals"` // keyed "D9", "D10", ...
}

// ===== Phase C: Vimshottari Dasha =====

// DashaPeriod is one node in the dasha tree. Sub may be empty for leaf periods.
type DashaPeriod struct {
	Lord      string        `json:"lord"`       // Sun..Ketu
	Level     int           `json:"level"`      // 1=maha, 2=antar, 3=pratyantar
	StartDate time.Time     `json:"start_date"`
	EndDate   time.Time     `json:"end_date"`
	Sub       []DashaPeriod `json:"sub,omitempty"`
}

// DashaPath identifies the active maha/antar/pratyantar at a specific moment.
type DashaPath struct {
	Maha       string    `json:"maha"`
	Antar      string    `json:"antar"`
	Pratyantar string    `json:"pratyantar"`
	At         time.Time `json:"at"`
}

// DashaTree is the full Vimshottari output for a chart.
type DashaTree struct {
	System     string        `json:"system"` // "Vimshottari"
	Levels     int           `json:"levels"` // 1, 2, or 3
	Current    DashaPath     `json:"current"`
	Mahadashas []DashaPeriod `json:"mahadashas"` // 9 periods spanning 120 years from birth
}

// ===== Phase D: Yoga / Shadbala / Ashtakavarga =====

// VedicYoga is a classical planetary combination present in the chart.
type VedicYoga struct {
	Name        string  `json:"name"`        // English/standard name
	Sanskrit    string  `json:"sanskrit"`
	Category    string  `json:"category"`    // Pancha Mahapurusha | Raja | Dhana | Nabhasha | ...
	Description string  `json:"description"` // plain-English meaning
	Active      bool    `json:"active"`
	Strength    float64 `json:"strength"`    // 0..1
	Planets     []string `json:"planets"`    // planets that form this yoga
}

// ShadbalaBreakdown is the six-fold strength of a single graha (in Virupas).
type ShadbalaBreakdown struct {
	Sthana     float64 `json:"sthana"`     // positional
	Dig        float64 `json:"dig"`        // directional
	Kala       float64 `json:"kala"`       // temporal
	Chesta     float64 `json:"chesta"`     // motional
	Naisargika float64 `json:"naisargika"` // natural
	Drik       float64 `json:"drik"`       // aspectual
	Total      float64 `json:"total"`      // sum
	Required   float64 `json:"required"`   // classical threshold
	Sufficient bool    `json:"sufficient"` // total >= required
}

// Ashtakavarga is the bindu (benefic point) accumulation system.
type Ashtakavarga struct {
	Sarva [12]int            `json:"sarva"` // sum over 7 planets per sign (0..56)
	Bhinn map[string][12]int `json:"bhinn"` // per-planet bindu arrays
}
