package domain

import "time"

// NumerologyNumber is one calculated number with full provenance — the
// final reduced value, the raw pre-reduction sum, master/karmic flags, and
// a canned description for the front end.
type NumerologyNumber struct {
	Value        int    `json:"value"`           // 1..9 OR 11/22/33
	Display      string `json:"display"`         // "11/2" or "5"
	RawSum       int    `json:"raw_sum"`
	IsMaster     bool   `json:"is_master"`
	IsKarmicDebt bool   `json:"is_karmic_debt"`
	Description  string `json:"description"`
}

// NumerologyProfile is the lifelong-static portion (changes only if the
// user's name changes; otherwise computed once).
type NumerologyProfile struct {
	LifePath      NumerologyNumber `json:"life_path"`
	Expression    NumerologyNumber `json:"expression"`
	SoulUrge      NumerologyNumber `json:"soul_urge"`
	Personality   NumerologyNumber `json:"personality"`
	Maturity      NumerologyNumber `json:"maturity"`
	Birthday      NumerologyNumber `json:"birthday"`
	KarmicLessons []int            `json:"karmic_lessons"`
	HiddenPassion int              `json:"hidden_passion"`
	FullName      string           `json:"full_name"`
	BirthDate     time.Time        `json:"birth_date"`
}

// NumerologyCycles is the time-varying part — recomputed on demand.
type NumerologyCycles struct {
	PersonalYear  NumerologyNumber          `json:"personal_year"`
	PersonalMonth NumerologyNumber          `json:"personal_month"`
	PersonalDay   NumerologyNumber          `json:"personal_day"`
	Pinnacles     [4]NumerologyPinnacle     `json:"pinnacles"`
	Challenges    [4]NumerologyChallenge    `json:"challenges"`
	CurrentAge    int                       `json:"current_age"`
}

type NumerologyPinnacle struct {
	Index    int              `json:"index"`
	StartAge int              `json:"start_age"`
	EndAge   int              `json:"end_age"` // -1 = rest of life
	Number   NumerologyNumber `json:"number"`
	IsActive bool             `json:"is_active"`
}

type NumerologyChallenge struct {
	Index    int              `json:"index"`
	StartAge int              `json:"start_age"`
	EndAge   int              `json:"end_age"`
	Number   NumerologyNumber `json:"number"`
	IsActive bool             `json:"is_active"`
}

// NumerologyReading bundles profile + cycles for one /api/v1/numerology call.
type NumerologyReading struct {
	Profile NumerologyProfile `json:"profile"`
	Cycles  NumerologyCycles  `json:"cycles"`
}

// NumerologyCompatibilityRequest is the body of POST /numerology/compatibility.
type NumerologyCompatibilityRequest struct {
	FullName  string `json:"full_name"`
	BirthDate string `json:"birth_date"` // YYYY-MM-DD
}

// NumerologyCompatibility is the response shape.
type NumerologyCompatibility struct {
	Score           int    `json:"score"`             // 0..100
	LifePathScore   int    `json:"life_path_score"`
	ExpressionScore int    `json:"expression_score"`
	SoulUrgeScore   int    `json:"soul_urge_score"`
	Summary         string `json:"summary"`
	OtherProfile    NumerologyProfile `json:"other_profile"` // for display
}
