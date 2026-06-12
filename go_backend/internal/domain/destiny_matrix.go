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

// DestinyMatrixReading is the full response for GET /api/v1/destiny-matrix.
// Points always holds 9 entries (A,B,C,D,E,TL,TR,BR,BL in order); Lines
// always holds 4.
type DestinyMatrixReading struct {
	BirthDate string         `json:"birth_date"` // YYYY-MM-DD
	Points    []DestinyPoint `json:"points"`
	Lines     []DestinyLine  `json:"lines"`
}
