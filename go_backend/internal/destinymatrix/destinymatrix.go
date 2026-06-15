// Package destinymatrix implements the Matrix of Destiny (Destiny Matrix) —
// the full 22-arcana octagram.
//
// From a birth date it derives the four diamond cardinals (Day/Month/Year/Sum),
// the four square corners (TL/TR/BR/BL), the center, the three purpose values
// (Heaven/Earth/Personal), the three inner arcana along each of the four cross
// arms and each of the four diagonals, and a perimeter age ladder.
//
// Reduction uses the authentic DIGIT-SUM method (NOT subtract-22): while a
// value exceeds 22 it is replaced by the sum of its decimal digits, e.g.
// 34->7, 27->9, 29->11; 22 stays 22; values <=22 are unchanged.
//
// Everything here is pure and deterministic — no clock, no I/O.
package destinymatrix

import "time"

// Triple is an ordered set of three inner arcana along an edge running from an
// outer point P toward the center: [NearP, Mid, NearCenter].
type Triple struct {
	NearP      int `json:"near_p"`      // arcana nearest the outer point
	Mid        int `json:"mid"`         // arcana at the edge midpoint
	NearCenter int `json:"near_center"` // arcana nearest the center
}

// Result is the raw computed output: every arcana position on the octagram.
type Result struct {
	// Diamond cardinals (each is also an age anchor).
	Day   int // left,   age 0
	Month int // top,    age 20
	Year  int // right,  age 40
	Sum   int // bottom, age 60

	// Square corners.
	TL int // top-left,     age 10
	TR int // top-right,    age 30
	BR int // bottom-right, age 50
	BL int // bottom-left,  age 70

	// Destiny core.
	Center int

	// Purpose values.
	Heaven   int // reduce(Month + Sum)  — vertical axis ends
	Earth    int // reduce(Day + Year)   — horizontal axis ends
	Personal int // reduce(Heaven + Earth)

	// Cross arms (cardinal -> center). These are the chakra values.
	LeftArm   Triple // subdivide(Day)
	TopArm    Triple // subdivide(Month)
	RightArm  Triple // subdivide(Year)
	BottomArm Triple // subdivide(Sum)

	// Diagonals (corner -> center). Generation / ancestral lines + inner diamond.
	TLDiag Triple // subdivide(TL) — NearCenter is the paternal upper endpoint
	TRDiag Triple // subdivide(TR) — NearCenter is the maternal upper endpoint
	BRDiag Triple // subdivide(BR) — NearCenter is the paternal lower endpoint
	BLDiag Triple // subdivide(BL) — NearCenter is the maternal lower endpoint

	// AgeLadder walks the octagram perimeter clockwise from age 0 to age 80:
	// the 8 corner ages (0,10,...,70) and the 7 intermediate ticks per edge.
	AgeLadder []AgeArcana
}

// AgeArcana is one rung of the age-ladder: a (possibly fractional) age and its
// arcana. Label carries a readable form of the age, e.g. "0" or "1.25".
type AgeArcana struct {
	Age    float64 `json:"age"`
	Label  string  `json:"label"`
	Arcana int     `json:"arcana"`
}

// PointDef describes one octagram point: a stable key, its octagram position,
// and its display title.
type PointDef struct {
	Key      string
	Position string
	Title    string
}

// PointDefs is the canonical ordered list of every point the painter places:
// the four cardinals, four corners, center, three purpose values, the three
// inner nodes per cross arm, and the three inner nodes per diagonal.
var PointDefs = []PointDef{
	// Cardinals (diamond).
	{Key: "day", Position: "left", Title: "Day / Self"},
	{Key: "month", Position: "top", Title: "Month / Talents"},
	{Key: "year", Position: "right", Title: "Year / Ancestry"},
	{Key: "sum", Position: "bottom", Title: "Purpose / Karma"},

	// Corners (square).
	{Key: "tl", Position: "top_left", Title: "Material Root"},
	{Key: "tr", Position: "top_right", Title: "Relationship Root"},
	{Key: "br", Position: "bottom_right", Title: "Material Outcome"},
	{Key: "bl", Position: "bottom_left", Title: "Relationship Outcome"},

	// Center.
	{Key: "center", Position: "center", Title: "Comfort / Core"},

	// Purpose values.
	{Key: "heaven", Position: "heaven", Title: "Sky Purpose"},
	{Key: "earth", Position: "earth", Title: "Earth Purpose"},
	{Key: "personal", Position: "personal", Title: "Personal Purpose"},

	// Cross arms — order [nearP, mid, nearCenter] from the cardinal inward.
	{Key: "arm_left_1", Position: "arm_left", Title: "Left Chakra (near self)"},
	{Key: "arm_left_2", Position: "arm_left", Title: "Left Chakra (mid)"},
	{Key: "arm_left_3", Position: "arm_left", Title: "Left Chakra (near core)"},
	{Key: "arm_top_1", Position: "arm_top", Title: "Top Chakra (near talents)"},
	{Key: "arm_top_2", Position: "arm_top", Title: "Top Chakra (mid)"},
	{Key: "arm_top_3", Position: "arm_top", Title: "Top Chakra (near core)"},
	{Key: "arm_right_1", Position: "arm_right", Title: "Right Chakra (near ancestry)"},
	{Key: "arm_right_2", Position: "arm_right", Title: "Right Chakra (mid)"},
	{Key: "arm_right_3", Position: "arm_right", Title: "Right Chakra (near core)"},
	{Key: "arm_bottom_1", Position: "arm_bottom", Title: "Bottom Chakra (near purpose)"},
	{Key: "arm_bottom_2", Position: "arm_bottom", Title: "Bottom Chakra (mid)"},
	{Key: "arm_bottom_3", Position: "arm_bottom", Title: "Bottom Chakra (near core)"},

	// Diagonals — order [nearCorner, mid, nearCenter] from the corner inward.
	{Key: "diag_tl_1", Position: "diag_tl", Title: "Paternal Line (near root)"},
	{Key: "diag_tl_2", Position: "diag_tl", Title: "Paternal Line (mid)"},
	{Key: "diag_tl_3", Position: "diag_tl", Title: "Paternal Line (near core)"},
	{Key: "diag_tr_1", Position: "diag_tr", Title: "Maternal Line (near root)"},
	{Key: "diag_tr_2", Position: "diag_tr", Title: "Maternal Line (mid)"},
	{Key: "diag_tr_3", Position: "diag_tr", Title: "Maternal Line (near core)"},
	{Key: "diag_br_1", Position: "diag_br", Title: "Paternal Line (near outcome)"},
	{Key: "diag_br_2", Position: "diag_br", Title: "Paternal Line (mid)"},
	{Key: "diag_br_3", Position: "diag_br", Title: "Paternal Line (near core)"},
	{Key: "diag_bl_1", Position: "diag_bl", Title: "Maternal Line (near outcome)"},
	{Key: "diag_bl_2", Position: "diag_bl", Title: "Maternal Line (mid)"},
	{Key: "diag_bl_3", Position: "diag_bl", Title: "Maternal Line (near core)"},
}

// LineDef describes one interpretive line: a stable key, a display title, the
// ordered point keys it spans, and an interpretive theme.
type LineDef struct {
	Key       string
	Title     string
	PointKeys []string
	Theme     string
}

// LineDefs is the canonical ordered list of the interpretive lines.
var LineDefs = []LineDef{
	{
		Key:       "personal",
		Title:     "Personal",
		PointKeys: []string{"day", "center", "year"},
		Theme:     "The horizontal axis of who you are: how your inborn self meets the world and what your lineage hands you to work with.",
	},
	{
		Key:       "spiritual",
		Title:     "Spiritual",
		PointKeys: []string{"month", "center", "sum"},
		Theme:     "The vertical axis of meaning: the talents you carry and the higher purpose or karmic task they are meant to serve.",
	},
	{
		Key:       "money",
		Title:     "Money / Material",
		PointKeys: []string{"br", "diag_br_1", "diag_br_2", "diag_br_3", "center"},
		Theme:     "The descending diagonal of resources: your relationship with abundance, work, and the material results you grow toward.",
	},
	{
		Key:       "love",
		Title:     "Love / Relationship",
		PointKeys: []string{"bl", "diag_bl_1", "diag_bl_2", "diag_bl_3", "center"},
		Theme:     "The ascending diagonal of the heart: how you bond, what you seek in partnership, and the relationships you ripen into.",
	},
	{
		Key:       "maleGeneration",
		Title:     "Male Generation Line",
		PointKeys: []string{"tl", "diag_tl_1", "diag_tl_2", "diag_tl_3", "center", "diag_br_3", "diag_br_2", "diag_br_1", "br"},
		Theme:     "The paternal diagonal (TL to BR): the talents, debts, and lessons handed down the father's line.",
	},
	{
		Key:       "femaleGeneration",
		Title:     "Female Generation Line",
		PointKeys: []string{"tr", "diag_tr_1", "diag_tr_2", "diag_tr_3", "center", "diag_bl_3", "diag_bl_2", "diag_bl_1", "bl"},
		Theme:     "The maternal diagonal (TR to BL): the gifts, wounds, and karmic patterns carried down the mother's line.",
	},
}

// Compute runs the full octagram algorithm for a birth date.
func Compute(birthDate time.Time) Result {
	d := birthDate.Day()
	m := int(birthDate.Month())
	y := birthDate.Year()

	day := reduce(d)
	month := reduce(m)
	year := reduce(digitSum(y))
	sum := reduce(day + month + year)
	center := reduce(day + month + year + sum)

	tl := reduce(day + month)
	tr := reduce(month + year)
	br := reduce(year + sum)
	bl := reduce(sum + day)

	heaven := reduce(month + sum)
	earth := reduce(day + year)
	personal := reduce(heaven + earth)

	return Result{
		Day:   day,
		Month: month,
		Year:  year,
		Sum:   sum,

		TL: tl,
		TR: tr,
		BR: br,
		BL: bl,

		Center: center,

		Heaven:   heaven,
		Earth:    earth,
		Personal: personal,

		LeftArm:   subdivide(day, center),
		TopArm:    subdivide(month, center),
		RightArm:  subdivide(year, center),
		BottomArm: subdivide(sum, center),

		TLDiag: subdivide(tl, center),
		TRDiag: subdivide(tr, center),
		BRDiag: subdivide(br, center),
		BLDiag: subdivide(bl, center),

		AgeLadder: ageLadder(day, tl, month, tr, year, br, sum, bl),
	}
}

// subdivide returns the three inner arcana on the edge from outer point p to
// the center, ordered [NearP, Mid, NearCenter].
func subdivide(p, center int) Triple {
	mid := reduce(p + center)
	return Triple{
		NearP:      reduce(p + mid),
		Mid:        mid,
		NearCenter: reduce(mid + center),
	}
}

// ageLadder builds the perimeter age ladder. The eight corner arcana arrive in
// clockwise age order: Day(0) -> TL(10) -> Month(20) -> TR(30) -> Year(40) ->
// BR(50) -> Sum(60) -> BL(70), and the edge after BL closes back to Day at 80.
//
// Each edge spans 10 years between consecutive corners. Within an edge the 7
// intermediate ticks at +1.25y steps come from a 3-level binary subdivision:
//
//	v0=S; v8=E;
//	v4=reduce(v0+v8); v2=reduce(v0+v4); v6=reduce(v4+v8);
//	v1=reduce(v0+v2); v3=reduce(v2+v4); v5=reduce(v4+v6); v7=reduce(v6+v8);
//
// The emitted ladder is: corner(age 0), 7 ticks, corner(age 10), 7 ticks, …,
// corner(age 70), 7 ticks for the closing edge, ending just before age 80.
func ageLadder(corners ...int) []AgeArcana {
	if len(corners) != 8 {
		return nil
	}
	out := make([]AgeArcana, 0, 8*8)
	for d := 0; d < 8; d++ {
		startAge := float64(d) * 10
		v0 := corners[d]
		v8 := corners[(d+1)%8]

		// Corner anchor at the start of this edge.
		out = append(out, AgeArcana{
			Age:    startAge,
			Label:  formatAge(startAge),
			Arcana: v0,
		})

		// 7 intermediate ticks at +1.25y steps via binary subdivision.
		v4 := reduce(v0 + v8)
		v2 := reduce(v0 + v4)
		v6 := reduce(v4 + v8)
		ticks := [7]int{
			reduce(v0 + v2), // v1
			v2,
			reduce(v2 + v4), // v3
			v4,
			reduce(v4 + v6), // v5
			v6,
			reduce(v6 + v8), // v7
		}
		for i, arc := range ticks {
			age := startAge + 1.25*float64(i+1)
			out = append(out, AgeArcana{
				Age:    age,
				Label:  formatAge(age),
				Arcana: arc,
			})
		}
	}
	return out
}

// formatAge renders an age as a compact decimal string: whole numbers drop the
// fractional part ("0", "10"), quarters keep two decimals ("1.25", "8.75").
func formatAge(age float64) string {
	whole := int(age)
	if float64(whole) == age {
		return itoa(whole)
	}
	// Fractional part is always a multiple of 0.25 here.
	frac := int((age - float64(whole)) * 100)
	return itoa(whole) + "." + pad2(frac)
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}

func pad2(n int) string {
	if n < 10 {
		return "0" + itoa(n)
	}
	return itoa(n)
}

// Value returns the arcana value for a point key, or 0 for an unknown key.
func (r Result) Value(key string) int {
	switch key {
	case "day":
		return r.Day
	case "month":
		return r.Month
	case "year":
		return r.Year
	case "sum":
		return r.Sum
	case "tl":
		return r.TL
	case "tr":
		return r.TR
	case "br":
		return r.BR
	case "bl":
		return r.BL
	case "center":
		return r.Center
	case "heaven":
		return r.Heaven
	case "earth":
		return r.Earth
	case "personal":
		return r.Personal

	case "arm_left_1":
		return r.LeftArm.NearP
	case "arm_left_2":
		return r.LeftArm.Mid
	case "arm_left_3":
		return r.LeftArm.NearCenter
	case "arm_top_1":
		return r.TopArm.NearP
	case "arm_top_2":
		return r.TopArm.Mid
	case "arm_top_3":
		return r.TopArm.NearCenter
	case "arm_right_1":
		return r.RightArm.NearP
	case "arm_right_2":
		return r.RightArm.Mid
	case "arm_right_3":
		return r.RightArm.NearCenter
	case "arm_bottom_1":
		return r.BottomArm.NearP
	case "arm_bottom_2":
		return r.BottomArm.Mid
	case "arm_bottom_3":
		return r.BottomArm.NearCenter

	case "diag_tl_1":
		return r.TLDiag.NearP
	case "diag_tl_2":
		return r.TLDiag.Mid
	case "diag_tl_3":
		return r.TLDiag.NearCenter
	case "diag_tr_1":
		return r.TRDiag.NearP
	case "diag_tr_2":
		return r.TRDiag.Mid
	case "diag_tr_3":
		return r.TRDiag.NearCenter
	case "diag_br_1":
		return r.BRDiag.NearP
	case "diag_br_2":
		return r.BRDiag.Mid
	case "diag_br_3":
		return r.BRDiag.NearCenter
	case "diag_bl_1":
		return r.BLDiag.NearP
	case "diag_bl_2":
		return r.BLDiag.Mid
	case "diag_bl_3":
		return r.BLDiag.NearCenter

	default:
		return 0
	}
}

// reduce folds n into the range 1..22 using the digit-sum method: while n>22,
// replace n with the sum of its decimal digits (22 stays 22; n<=22 unchanged).
func reduce(n int) int {
	if n < 1 {
		// Unreachable from Compute (all inputs are >= 1), but guard so reduce
		// always yields a valid arcana.
		return 1
	}
	for n > 22 {
		n = digitSum(n)
	}
	return n
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
