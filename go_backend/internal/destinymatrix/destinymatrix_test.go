package destinymatrix

import (
	"reflect"
	"testing"
	"time"
)

// date is a small helper to build a UTC birth date.
func date(y, m, d int) time.Time {
	return time.Date(y, time.Month(m), d, 0, 0, 0, 0, time.UTC)
}

// TestComputeFixture asserts the full acceptance fixture for 2003-10-02 from
// the reference octagram image. Every derived value must match exactly.
func TestComputeFixture(t *testing.T) {
	r := Compute(date(2003, 10, 2))

	checkInt := func(label string, got, want int) {
		t.Helper()
		if got != want {
			t.Errorf("%s = %d, want %d", label, got, want)
		}
	}
	checkTriple := func(label string, got Triple, want [3]int) {
		t.Helper()
		if got.NearP != want[0] || got.Mid != want[1] || got.NearCenter != want[2] {
			t.Errorf("%s = [%d %d %d], want %v",
				label, got.NearP, got.Mid, got.NearCenter, want)
		}
	}

	checkInt("Day", r.Day, 2)
	checkInt("Month", r.Month, 10)
	checkInt("Year", r.Year, 5)
	checkInt("Sum", r.Sum, 17)
	checkInt("Center", r.Center, 7)

	checkInt("TL", r.TL, 12)
	checkInt("TR", r.TR, 15)
	checkInt("BR", r.BR, 22)
	checkInt("BL", r.BL, 19)

	checkInt("Heaven", r.Heaven, 9)
	checkInt("Earth", r.Earth, 7)
	checkInt("Personal", r.Personal, 16)

	checkTriple("leftArm", r.LeftArm, [3]int{11, 9, 16})
	checkTriple("topArm", r.TopArm, [3]int{9, 17, 6})
	checkTriple("rightArm", r.RightArm, [3]int{17, 12, 19})
	checkTriple("bottomArm", r.BottomArm, [3]int{5, 6, 13})

	checkTriple("tlDiag", r.TLDiag, [3]int{4, 19, 8})
	checkTriple("trDiag", r.TRDiag, [3]int{10, 22, 11})
	checkTriple("brDiag", r.BRDiag, [3]int{6, 11, 18})
	checkTriple("blDiag", r.BLDiag, [3]int{9, 8, 15})
}

// TestAgeLadderFirstEdge asserts the perimeter ticks on the Day(2)->TL(12)
// edge match the documented binary subdivision exactly.
func TestAgeLadderFirstEdge(t *testing.T) {
	r := Compute(date(2003, 10, 2))
	want := []int{18, 16, 3, 14, 22, 8, 20}

	// The ladder starts with the Day corner (age 0) then the 7 ticks
	// (ages 1.25..8.75) before the TL corner (age 10).
	if len(r.AgeLadder) < 9 {
		t.Fatalf("ladder too short: %d", len(r.AgeLadder))
	}
	if got := r.AgeLadder[0].Arcana; got != 2 {
		t.Errorf("ladder[0] (Day corner) = %d, want 2", got)
	}
	if got := r.AgeLadder[0].Age; got != 0 {
		t.Errorf("ladder[0].Age = %v, want 0", got)
	}
	for i, w := range want {
		rung := r.AgeLadder[i+1]
		if rung.Arcana != w {
			t.Errorf("tick %d arcana = %d, want %d", i, rung.Arcana, w)
		}
		wantAge := 1.25 * float64(i+1)
		if rung.Age != wantAge {
			t.Errorf("tick %d age = %v, want %v", i, rung.Age, wantAge)
		}
	}
	// The 8th anchor must be TL=12 at age 10.
	if got := r.AgeLadder[8].Arcana; got != 12 {
		t.Errorf("ladder[8] (TL corner) = %d, want 12", got)
	}
	if got := r.AgeLadder[8].Age; got != 10 {
		t.Errorf("ladder[8].Age = %v, want 10", got)
	}
}

// TestAgeLadderAllEdges pins every one of the eight perimeter edges for the
// 2003-10-02 fixture. The corner age order is clockwise:
//
//	Day(2)@0, TL(12)@10, Month(10)@20, TR(15)@30, Year(5)@40, BR(22)@50,
//	Sum(17)@60, BL(19)@70, and the 8th edge wraps BL(19) back to Day(2).
//
// Each edge's 7 ticks come from the documented binary subdivision
// (v4=reduce(S+E); v2=reduce(S+v4); v6=reduce(v4+E); v1,v3,v5,v7 between).
// The values below were hand-derived independently from the reference rule;
// in particular edges 0 (Day->TL), 1 (TL->Month), 5 (BR->Sum, the "22 stays
// 22" corner) and 7 (BL->Day, the wrap edge) were verified by hand.
func TestAgeLadderAllEdges(t *testing.T) {
	r := Compute(date(2003, 10, 2))
	if len(r.AgeLadder) != 64 {
		t.Fatalf("ladder has %d rungs, want 64", len(r.AgeLadder))
	}

	edges := []struct {
		name   string
		corner int    // expected corner arcana at the start of the edge
		ticks  [7]int // expected 7 intermediate ticks
	}{
		{"Day(2)->TL(12)", 2, [7]int{18, 16, 3, 14, 22, 8, 20}},    // hand-verified (reference)
		{"TL(12)->Month(10)", 12, [7]int{19, 7, 11, 22, 9, 5, 15}}, // hand-verified
		{"Month(10)->TR(15)", 10, [7]int{9, 17, 6, 7, 11, 22, 10}}, // code cross-check
		{"TR(15)->Year(5)", 15, [7]int{5, 8, 10, 20, 9, 7, 12}},    // code cross-check
		{"Year(5)->BR(22)", 5, [7]int{19, 14, 5, 9, 13, 4, 8}},     // code cross-check
		{"BR(22)->Sum(17)", 22, [7]int{11, 7, 19, 12, 5, 11, 10}},  // hand-verified ("22 stays 22")
		{"Sum(17)->BL(19)", 17, [7]int{7, 8, 17, 9, 19, 10, 11}},   // code cross-check
		{"BL(19)->Day(2)", 19, [7]int{5, 4, 7, 21, 8, 5, 7}},       // hand-verified (wrap edge)
	}

	for e, edge := range edges {
		base := e * 8
		startAge := float64(e) * 10
		if got := r.AgeLadder[base].Arcana; got != edge.corner {
			t.Errorf("edge %d (%s) corner arcana = %d, want %d",
				e, edge.name, got, edge.corner)
		}
		if got := r.AgeLadder[base].Age; got != startAge {
			t.Errorf("edge %d (%s) corner age = %v, want %v",
				e, edge.name, got, startAge)
		}
		for i, w := range edge.ticks {
			rung := r.AgeLadder[base+1+i]
			if rung.Arcana != w {
				t.Errorf("edge %d (%s) tick %d arcana = %d, want %d",
					e, edge.name, i, rung.Arcana, w)
			}
			wantAge := startAge + 1.25*float64(i+1)
			if rung.Age != wantAge {
				t.Errorf("edge %d (%s) tick %d age = %v, want %v",
					e, edge.name, i, rung.Age, wantAge)
			}
		}
	}
}

// TestSubdivideContract asserts subdivide returns [NearP, Mid, NearCenter] with
// Mid=reduce(p+center), NearP=reduce(p+Mid), NearCenter=reduce(Mid+center) for
// a sweep of inputs (independent of Compute wiring).
func TestSubdivideContract(t *testing.T) {
	for center := 1; center <= 22; center++ {
		for p := 1; p <= 22; p++ {
			tr := subdivide(p, center)
			mid := reduce(p + center)
			if tr.Mid != mid {
				t.Errorf("subdivide(%d,%d).Mid = %d, want %d", p, center, tr.Mid, mid)
			}
			if want := reduce(p + mid); tr.NearP != want {
				t.Errorf("subdivide(%d,%d).NearP = %d, want %d", p, center, tr.NearP, want)
			}
			if want := reduce(mid + center); tr.NearCenter != want {
				t.Errorf("subdivide(%d,%d).NearCenter = %d, want %d", p, center, tr.NearCenter, want)
			}
			for _, v := range []int{tr.NearP, tr.Mid, tr.NearCenter} {
				if v < 1 || v > 22 {
					t.Errorf("subdivide(%d,%d) produced %d, out of range 1..22", p, center, v)
				}
			}
		}
	}
}

// TestArmsAndDiagonalsRange asserts every arm and diagonal value is in 1..22
// across a date sweep.
func TestArmsAndDiagonalsRange(t *testing.T) {
	years := []int{1900, 1987, 2000, 2003, 2026}
	for _, y := range years {
		for m := 1; m <= 12; m++ {
			for d := 1; d <= 28; d++ {
				res := Compute(date(y, m, d))
				triples := map[string]Triple{
					"LeftArm": res.LeftArm, "TopArm": res.TopArm,
					"RightArm": res.RightArm, "BottomArm": res.BottomArm,
					"TLDiag": res.TLDiag, "TRDiag": res.TRDiag,
					"BRDiag": res.BRDiag, "BLDiag": res.BLDiag,
				}
				for name, tr := range triples {
					for _, v := range []int{tr.NearP, tr.Mid, tr.NearCenter} {
						if v < 1 || v > 22 {
							t.Errorf("%04d-%02d-%02d %s value %d out of range 1..22",
								y, m, d, name, v)
						}
					}
				}
				cardinals := map[string]int{
					"Day": res.Day, "Month": res.Month, "Year": res.Year, "Sum": res.Sum,
					"TL": res.TL, "TR": res.TR, "BR": res.BR, "BL": res.BL,
					"Center": res.Center, "Heaven": res.Heaven,
					"Earth": res.Earth, "Personal": res.Personal,
				}
				for name, v := range cardinals {
					if v < 1 || v > 22 {
						t.Errorf("%04d-%02d-%02d %s = %d out of range 1..22", y, m, d, name, v)
					}
				}
			}
		}
	}
}

// TestReduceNeverZeroOrNegative asserts reduce never returns 0, a negative, or
// a value > 22 for inputs 1..500 (the explicit invariant from the spec).
func TestReduceNeverZeroOrNegative(t *testing.T) {
	for n := 1; n <= 500; n++ {
		got := reduce(n)
		if got <= 0 {
			t.Errorf("reduce(%d) = %d, must be > 0", n, got)
		}
		if got > 22 {
			t.Errorf("reduce(%d) = %d, must be <= 22", n, got)
		}
	}
}

// TestReduceIsDigitSumNotSubtract22 guards against the subtract-22 regression:
// reduce(34) must be 7 (3+4), NOT 12 (34-22); reduce(26) must be 8, NOT 4.
func TestReduceIsDigitSumNotSubtract22(t *testing.T) {
	cases := []struct {
		in, digitSum, subtract22 int
	}{
		{34, 7, 12},
		{26, 8, 4},
		{27, 9, 5},
		{29, 11, 7},
		{40, 4, 18},
	}
	for _, c := range cases {
		got := reduce(c.in)
		if got != c.digitSum {
			t.Errorf("reduce(%d) = %d, want digit-sum %d", c.in, got, c.digitSum)
		}
		if got == c.subtract22 {
			t.Errorf("reduce(%d) = %d looks like subtract-22 (should be digit-sum %d)",
				c.in, got, c.digitSum)
		}
	}
}

// TestReduceDigitSum asserts the digit-sum reduction on the documented inputs.
func TestReduceDigitSum(t *testing.T) {
	cases := []struct{ in, want int }{
		{34, 7},
		{27, 9},
		{26, 8},
		{29, 11},
		{24, 6},
		{31, 4},
		{22, 22},
		{1, 1},
		{19, 19},
		{10, 10},
	}
	for _, c := range cases {
		if got := reduce(c.in); got != c.want {
			t.Errorf("reduce(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

// TestReduceRangeInvariant asserts reduce always lands in 1..22.
func TestReduceRangeInvariant(t *testing.T) {
	for n := 1; n <= 500; n++ {
		got := reduce(n)
		if got < 1 || got > 22 {
			t.Errorf("reduce(%d) = %d, out of range 1..22", n, got)
		}
	}
}

// TestDigitSum asserts the decimal digit sum.
func TestDigitSum(t *testing.T) {
	cases := []struct{ in, want int }{
		{1987, 25},
		{2000, 2},
		{1999, 28},
		{2003, 5},
		{2026, 10},
	}
	for _, c := range cases {
		if got := digitSum(c.in); got != c.want {
			t.Errorf("digitSum(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

// TestAgeLadderShape asserts every birthdate yields 64 rungs (8 corners + 56
// ticks), all arcana in 1..22, the eight corner anchors land on the right
// arcana, and the ages step correctly.
func TestAgeLadderShape(t *testing.T) {
	years := []int{1900, 1987, 1999, 2000, 2003, 2024, 2026}
	for _, y := range years {
		for m := 1; m <= 12; m++ {
			for d := 1; d <= 28; d++ {
				res := Compute(date(y, m, d))
				ladder := res.AgeLadder
				if len(ladder) != 64 {
					t.Fatalf("%04d-%02d-%02d ladder has %d rungs, want 64",
						y, m, d, len(ladder))
				}
				for _, rung := range ladder {
					if rung.Arcana < 1 || rung.Arcana > 22 {
						t.Errorf("%04d-%02d-%02d arcana %d out of range 1..22",
							y, m, d, rung.Arcana)
					}
				}
				corners := map[int]int{
					0: res.Day, 8: res.TL, 16: res.Month, 24: res.TR,
					32: res.Year, 40: res.BR, 48: res.Sum, 56: res.BL,
				}
				for idx, want := range corners {
					if got := ladder[idx].Arcana; got != want {
						t.Errorf("%04d-%02d-%02d ladder[%d] = %d, want corner %d",
							y, m, d, idx, got, want)
					}
					wantAge := float64(idx/8) * 10
					if got := ladder[idx].Age; got != wantAge {
						t.Errorf("%04d-%02d-%02d ladder[%d].Age = %v, want %v",
							y, m, d, idx, got, wantAge)
					}
				}
			}
		}
	}
}

// TestPointDefsResolve asserts every PointDef key resolves to a value in 1..22
// for a sweep of dates (catches a typo in Value or PointDefs).
func TestPointDefsResolve(t *testing.T) {
	years := []int{1900, 1987, 2000, 2003, 2026}
	for _, y := range years {
		for m := 1; m <= 12; m++ {
			for d := 1; d <= 28; d++ {
				res := Compute(date(y, m, d))
				for _, pd := range PointDefs {
					v := res.Value(pd.Key)
					if v < 1 || v > 22 {
						t.Errorf("%04d-%02d-%02d point %s = %d, out of range 1..22",
							y, m, d, pd.Key, v)
					}
				}
			}
		}
	}
}

// TestLineDefsResolve asserts every line's point keys resolve to known points.
func TestLineDefsResolve(t *testing.T) {
	res := Compute(date(2003, 10, 2))
	for _, ld := range LineDefs {
		for _, key := range ld.PointKeys {
			if res.Value(key) == 0 {
				t.Errorf("line %s references unknown point key %q", ld.Key, key)
			}
		}
	}
}

// TestFormatAge asserts the readable age labels.
func TestFormatAge(t *testing.T) {
	cases := []struct {
		in   float64
		want string
	}{
		{0, "0"},
		{10, "10"},
		{1.25, "1.25"},
		{8.75, "8.75"},
		{3.75, "3.75"},
		{70, "70"},
	}
	for _, c := range cases {
		if got := formatAge(c.in); got != c.want {
			t.Errorf("formatAge(%v) = %q, want %q", c.in, got, c.want)
		}
	}
}

// TestDeterminism asserts the same date always yields the same result.
func TestDeterminism(t *testing.T) {
	d := date(2003, 10, 2)
	first := Compute(d)
	for i := 0; i < 50; i++ {
		if !reflect.DeepEqual(Compute(d), first) {
			t.Fatalf("Compute is not deterministic for %v", d)
		}
	}
}

// TestArcanaLookup asserts every value 1..22 resolves to a non-empty name and
// meaning and out-of-range returns empty.
func TestArcanaLookup(t *testing.T) {
	for n := 1; n <= 22; n++ {
		name, meaning := Arcana(n)
		if name == "" || meaning == "" {
			t.Errorf("Arcana(%d) = (%q,%q), want non-empty", n, name, meaning)
		}
	}
	if n, _ := Arcana(1); n != "The Magician" {
		t.Errorf("Arcana(1) name = %q, want \"The Magician\"", n)
	}
	if n, _ := Arcana(22); n != "The Fool" {
		t.Errorf("Arcana(22) name = %q, want \"The Fool\"", n)
	}
	for _, bad := range []int{0, 23, -1, 100} {
		if name, meaning := Arcana(bad); name != "" || meaning != "" {
			t.Errorf("Arcana(%d) = (%q,%q), want empty", bad, name, meaning)
		}
	}
}

// TestValueUnknownKey asserts Result.Value returns 0 for an unknown key.
func TestValueUnknownKey(t *testing.T) {
	r := Compute(date(2003, 10, 2))
	if got := r.Value("zz"); got != 0 {
		t.Errorf("Value(\"zz\") = %d, want 0", got)
	}
}
