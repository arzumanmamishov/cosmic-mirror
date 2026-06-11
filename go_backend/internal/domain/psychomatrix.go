package domain

// PsychomatrixWorkingNumbers holds the four derived working numbers of the
// Alexandrov method (see internal/psychomatrix).
type PsychomatrixWorkingNumbers struct {
	First  int `json:"first"`  // W1: sum of all date digits
	Second int `json:"second"` // W2: digital root of W1
	Third  int `json:"third"`  // W3: W1 - 2*firstDigitOfDay
	Fourth int `json:"fourth"` // W4: digital root of abs(W3)
}

// PsychomatrixCell is one of the nine grid cells (digit 1..9). Count is how
// many times the digit appears in the pool; Repeated is the digit rendered
// Count times (e.g. "111") or "" when absent.
type PsychomatrixCell struct {
	Digit    int    `json:"digit"`
	Count    int    `json:"count"`
	Repeated string `json:"repeated"`
	Title    string `json:"title"`
	Meaning  string `json:"meaning"`
}

// PsychomatrixLine is one of the eight lines (rows, columns, diagonals).
// Strength is the total digit count across its three cells.
type PsychomatrixLine struct {
	Key      string `json:"key"`
	Title    string `json:"title"`
	Cells    []int  `json:"cells"`
	Strength int    `json:"strength"`
	Meaning  string `json:"meaning"`
}

// PsychomatrixReading is the full response for GET /api/v1/psychomatrix.
// Cells always holds 9 entries (digit 1..9 in order); Lines always holds 8.
type PsychomatrixReading struct {
	BirthDate      string                     `json:"birth_date"` // YYYY-MM-DD
	WorkingNumbers PsychomatrixWorkingNumbers `json:"working_numbers"`
	Cells          []PsychomatrixCell         `json:"cells"`
	Lines          []PsychomatrixLine         `json:"lines"`
}
