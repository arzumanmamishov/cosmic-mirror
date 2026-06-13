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

// Result is the raw computed output: every arcana position on the octagram.
//
// The nine "outer" positions (A,B,C,D,E + the four diagonals TL,TR,BR,BL)
// come from the authentic Ladini reductions. The six "inner" positions
// (four inner-diamond corners + the heart and money chakras) are second-
// generation reductions on top of those — they sit visually inside the
// octagram and let consumers paint the full classical Matrix layout.
type Result struct {
	A  int // left:   Day / Self  (age 0)
	B  int // top:    Month / Talents (age 20)
	C  int // right:  Year / Ancestry (age 40)
	D  int // bottom: Purpose / Karma (age 60)
	E  int // center: Comfort / Core (destiny number)
	TL int // top-left  (age 10) — material root
	TR int // top-right (age 30) — relationship root
	BR int // bottom-right (age 50) — material outcome
	BL int // bottom-left  (age 70) — relationship outcome

	// Inner diamond corners — second-generation karmic teachers. Each is
	// the reduction of its outer diagonal corner with the center, so the
	// reading inherits both the corner's theme and the destiny core.
	ITL int // inner top-left:  reduce(TL + E)
	ITR int // inner top-right: reduce(TR + E)
	IBR int // inner bottom-right: reduce(BR + E)
	IBL int // inner bottom-left:  reduce(BL + E)

	// Chakra centers sitting on the two main diagonals.
	Heart int // reduce(BL + TR) — balance of the love/relationship diagonal
	Money int // reduce(TL + BR) — balance of the money/material diagonal

	// AgeLadder is the per-year karmic arcana for ages 1..80, walking the
	// octagram perimeter clockwise from corner A (age 0) through TL (10),
	// B (20), TR (30), C (40), BR (50), D (60), BL (70) and back. See
	// AgeLadder() for the reduction formula.
	AgeLadder []AgeArcana
}

// AgeArcana is one rung of the age-ladder: the year and its arcana.
type AgeArcana struct {
	Age    int `json:"age"`    // 1..80
	Arcana int `json:"arcana"` // 1..22
}

// PointDef describes one of the nine octagram points: a stable key, its
// octagram position, and its display title.
type PointDef struct {
	Key      string
	Position string
	Title    string
}

// PointDefs is the canonical ordered list of every point — the nine outer
// positions first (A,B,C,D,E,TL,TR,BR,BL), then the four inner-diamond
// corners (ITL,ITR,IBR,IBL), then the two chakra centers (Heart,Money).
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
	{Key: "ITL", Position: "inner_top_left", Title: "Material Teacher"},
	{Key: "ITR", Position: "inner_top_right", Title: "Relationship Teacher"},
	{Key: "IBR", Position: "inner_bottom_right", Title: "Material Lesson"},
	{Key: "IBL", Position: "inner_bottom_left", Title: "Relationship Lesson"},
	{Key: "Heart", Position: "heart", Title: "Heart Chakra"},
	{Key: "Money", Position: "money", Title: "Money Chakra"},
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

	tl := reduce(a + b)
	tr := reduce(b + c)
	br := reduce(c + dd)
	bl := reduce(dd + a)

	return Result{
		A:  a,
		B:  b,
		C:  c,
		D:  dd,
		E:  e,
		TL: tl,
		TR: tr,
		BR: br,
		BL: bl,
		// Inner diamond = corner + destiny core, folded back into 1..22.
		ITL: reduce(tl + e),
		ITR: reduce(tr + e),
		IBR: reduce(br + e),
		IBL: reduce(bl + e),
		// Chakras sit at the midpoint of each main diagonal: the love
		// diagonal connects BL ↔ TR, the money diagonal connects TL ↔ BR.
		Heart:     reduce(bl + tr),
		Money:     reduce(tl + br),
		AgeLadder: ageLadder(a, tl, b, tr, c, br, dd, bl),
	}
}

// ageLadder builds the 80-year karmic ladder around the octagram. The eight
// corner arcana arrive in clockwise order (A → TL → B → TR → C → BR → D → BL,
// i.e. ages 0,10,20,30,40,50,60,70).
//
// Each decade is split into ten one-year rungs. The arcana for age `decade*10+i`
// (1 ≤ i ≤ 10) is an integer linear interpolation between the decade's start
// and end corners, then folded back into 1..22:
//
//	rung(age) = reduce( (start*(10-i) + end*i) / 10 )
//
// The integer division is deliberate — it makes the i=10 rung land on
// `end` exactly, so the karma at age 10/20/.../80 equals the corner arcana
// sitting at that age. Mid-decade rungs get rounded toward the start
// corner, which gives a smooth visual transition along each edge.
//
// This is a Ladini-style approximation: schools differ on the exact per-year
// formula and several keep the arithmetic private. We document the chosen
// reduction here so downstream consumers can swap it out without having to
// reverse-engineer.
func ageLadder(corners ...int) []AgeArcana {
	if len(corners) != 8 {
		return nil
	}
	out := make([]AgeArcana, 0, 80)
	for d := 0; d < 8; d++ {
		start := corners[d]
		end := corners[(d+1)%8]
		for i := 1; i <= 10; i++ {
			val := reduce((start*(10-i) + end*i) / 10)
			out = append(out, AgeArcana{Age: d*10 + i, Arcana: val})
		}
	}
	return out
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
	case "ITL":
		return r.ITL
	case "ITR":
		return r.ITR
	case "IBR":
		return r.IBR
	case "IBL":
		return r.IBL
	case "Heart":
		return r.Heart
	case "Money":
		return r.Money
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
