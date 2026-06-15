package domain

// DestinyPoint is one octagram point (see internal/destinymatrix). Arcana is
// the Major Arcana value 1..22 at that position.
type DestinyPoint struct {
	Key        string `json:"key"`      // "day","month","tl","center","heaven","arm_left_1","diag_tl_1",...
	Position   string `json:"position"` // "left","top","center","top_left","arm_left","diag_tl",...
	Title      string `json:"title"`    // e.g. "Day / Self"
	Arcana     int    `json:"arcana"`   // 1..22
	ArcanaName string `json:"arcana_name"`
	Meaning    string `json:"meaning"`
}

// DestinyLine is one interpretive line spanning an ordered list of points.
type DestinyLine struct {
	Key       string   `json:"key"`        // "personal","spiritual","money","love","maleGeneration","femaleGeneration"
	Title     string   `json:"title"`      // e.g. "Money / Material"
	PointKeys []string `json:"point_keys"` // e.g. ["br","diag_br_1","diag_br_2","diag_br_3","center"]
	Theme     string   `json:"theme"`
}

// AgeArcana is one rung of the perimeter age-ladder: a (possibly fractional)
// age, a readable label for it, and the arcana that rules it.
type AgeArcana struct {
	Age    float64 `json:"age"`    // 0..78.75
	Label  string  `json:"label"`  // e.g. "0", "1.25"
	Arcana int     `json:"arcana"` // 1..22
}

// DestinyMatrixReading is the full response for GET /api/v1/destiny-matrix.
type DestinyMatrixReading struct {
	BirthDate string         `json:"birth_date"` // YYYY-MM-DD
	Points    []DestinyPoint `json:"points"`
	Lines     []DestinyLine  `json:"lines"`
	AgeLadder []AgeArcana    `json:"age_ladder"`
}
