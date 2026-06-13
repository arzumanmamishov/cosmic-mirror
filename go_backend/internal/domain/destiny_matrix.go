package domain

// DestinyPoint is one of the nine octagram points (see internal/destinymatrix).
// Arcana is the Major Arcana value 1..22 at that position.
type DestinyPoint struct {
	Key        string `json:"key"`      // "A","B","C","D","E","TL","TR","BR","BL"
	Position   string `json:"position"` // "left","top","right","bottom","center","top_left",...
	Title      string `json:"title"`    // e.g. "Day / Self"
	Arcana     int    `json:"arcana"`   // 1..22
	ArcanaName string `json:"arcana_name"`
	Meaning    string `json:"meaning"`
}

// DestinyLine is one of the four interpretive lines spanning three points.
type DestinyLine struct {
	Key       string   `json:"key"`        // "personal","spiritual","money","love"
	Title     string   `json:"title"`      // e.g. "Money / Material"
	PointKeys []string `json:"point_keys"` // e.g. ["TL","E","BR"]
	Theme     string   `json:"theme"`
}

// AgeArcana is one rung of the perimeter age-ladder: the year of life and
// the arcana that rules it.
type AgeArcana struct {
	Age    int `json:"age"`    // 1..80
	Arcana int `json:"arcana"` // 1..22
}

// DestinyMatrixReading is the full response for GET /api/v1/destiny-matrix.
// Points always holds 15 entries (the 9 outer + 4 inner + 2 chakras);
// Lines holds 4; AgeLadder holds 80 rungs (ages 1..80).
type DestinyMatrixReading struct {
	BirthDate string         `json:"birth_date"` // YYYY-MM-DD
	Points    []DestinyPoint `json:"points"`
	Lines     []DestinyLine  `json:"lines"`
	AgeLadder []AgeArcana    `json:"age_ladder"`
}
