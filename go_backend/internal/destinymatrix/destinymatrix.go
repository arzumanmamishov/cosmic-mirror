// Package destinymatrix implements the Matrix of Destiny (Destiny Matrix) —
// the 22-arcana octagram by Natalia Ladini.
//
// From a birth date it derives nine octagram points (A,B,C,D,E and the four
// diagonal corners TL,TR,BR,BL), each an integer 1..22 corresponding to a
// Major Arcana. Reduction uses the authentic subtract-22 method (NOT a
// digit-sum): values above 22 have 22 subtracted repeatedly until they fall
// in 1..22.
//
// Everything here is pure and deterministic — no clock, no I/O.
package destinymatrix

import "time"

// Result is the raw computed output: the nine octagram points as arcana
// values in 1..22.
type Result struct {
	A  int // left:   Day / Self
	B  int // top:    Month / Talents
	C  int // right:  Year / Ancestry
	D  int // bottom: Purpose / Karma
	E  int // center: Comfort / Core
	TL int // top-left
	TR int // top-right
	BR int // bottom-right
	BL int // bottom-left
}

// PointDef describes one of the nine octagram points: a stable key, its
// octagram position, and its display title.
type PointDef struct {
	Key      string
	Position string
	Title    string
}

// PointDefs is the canonical ordered list of the nine points
// (A,B,C,D,E,TL,TR,BR,BL).
var PointDefs = []PointDef{
	{Key: "A", Position: "left", Title: "Day / Self"},
	{Key: "B", Position: "top", Title: "Month / Talents"},
	{Key: "C", Position: "right", Title: "Year / Ancestry"},
	{Key: "D", Position: "bottom", Title: "Purpose / Karma"},
	{Key: "E", Position: "center", Title: "Comfort / Core"},
	{Key: "TL", Position: "top_left", Title: "Material Root"},
	{Key: "TR", Position: "top_right", Title: "Relationship Root"},
	{Key: "BR", Position: "bottom_right", Title: "Material Outcome"},
	{Key: "BL", Position: "bottom_left", Title: "Relationship Outcome"},
}

// LineDef describes one of the four interpretive lines: a stable key, a
// display title, the ordered point keys it spans, and an interpretive theme.
type LineDef struct {
	Key       string
	Title     string
	PointKeys []string
	Theme     string
}

// LineDefs is the canonical ordered list of the four lines.
var LineDefs = []LineDef{
	{
		Key:       "personal",
		Title:     "Personal",
		PointKeys: []string{"A", "E", "C"},
		Theme:     "The horizontal axis of who you are: how your inborn self meets the world and what your lineage hands you to work with.",
	},
	{
		Key:       "spiritual",
		Title:     "Spiritual",
		PointKeys: []string{"B", "E", "D"},
		Theme:     "The vertical axis of meaning: the talents you carry and the higher purpose or karmic task they are meant to serve.",
	},
	{
		Key:       "money",
		Title:     "Money / Material",
		PointKeys: []string{"TL", "E", "BR"},
		Theme:     "The descending diagonal of resources: your relationship with abundance, work, and the material results you grow toward.",
	},
	{
		Key:       "love",
		Title:     "Love / Relationship",
		PointKeys: []string{"BL", "E", "TR"},
		Theme:     "The ascending diagonal of the heart: how you bond, what you seek in partnership, and the relationships you ripen into.",
	},
}

// Compute runs the authentic Ladini octagram algorithm for a birth date and
// returns the nine arcana points.
func Compute(birthDate time.Time) Result {
	d := birthDate.Day()
	m := int(birthDate.Month())
	y := birthDate.Year()

	a := reduce(d)
	b := reduce(m) // M <= 12, so unchanged
	c := reduce(digitSum(y))
	dd := reduce(a + b + c)
	e := reduce(a + b + c + dd)

	return Result{
		A:  a,
		B:  b,
		C:  c,
		D:  dd,
		E:  e,
		TL: reduce(a + b),
		TR: reduce(b + c),
		BR: reduce(c + dd),
		BL: reduce(dd + a),
	}
}

// Value returns the arcana value for a point key, or 0 for an unknown key.
func (r Result) Value(key string) int {
	switch key {
	case "A":
		return r.A
	case "B":
		return r.B
	case "C":
		return r.C
	case "D":
		return r.D
	case "E":
		return r.E
	case "TL":
		return r.TL
	case "TR":
		return r.TR
	case "BR":
		return r.BR
	case "BL":
		return r.BL
	default:
		return 0
	}
}

// reduce folds n into the range 1..22 using the subtract-22 method: for n>22
// subtract 22 repeatedly until n<=22 (22 stays 22). Implemented in closed
// form as ((n-1) % 22) + 1 for n>=1.
func reduce(n int) int {
	if n < 1 {
		// Unreachable from Compute (day/month/digitSum are all >= 1), but
		// guard so reduce always yields a valid arcana 1..22.
		return 1
	}
	return ((n - 1) % 22) + 1
}

// digitSum returns the sum of the decimal digits of abs(n), e.g. 1987 -> 25.
func digitSum(n int) int {
	if n < 0 {
		n = -n
	}
	s := 0
	for n > 0 {
		s += n % 10
		n /= 10
	}
	return s
}
