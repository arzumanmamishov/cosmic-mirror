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

// TestComputeFixtures asserts all nine octagram point values against the
// hand-verified acceptance fixtures from the canonical Ladini algorithm.
func TestComputeFixtures(t *testing.T) {
	tests := []struct {
		name                          string
		y, m, d                       int
		a, b, c, dd, e, tl, tr, br, bl int
	}{
		{
			name: "Ex1 1987-01-07",
			y:    1987, m: 1, d: 7,
			a: 7, b: 1, c: 3, dd: 11, e: 22, tl: 8, tr: 4, br: 14, bl: 18,
		},
		{
			name: "Ex2 1990-05-20",
			y:    1990, m: 5, d: 20,
			a: 20, b: 5, c: 19, dd: 22, e: 22, tl: 3, tr: 2, br: 19, bl: 20,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := Compute(date(tc.y, tc.m, tc.d))
			checks := []struct {
				label    string
				got, want int
			}{
				{"A", got.A, tc.a},
				{"B", got.B, tc.b},
				{"C", got.C, tc.c},
				{"D", got.D, tc.dd},
				{"E", got.E, tc.e},
				{"TL", got.TL, tc.tl},
				{"TR", got.TR, tc.tr},
				{"BR", got.BR, tc.br},
				{"BL", got.BL, tc.bl},
			}
			for _, ch := range checks {
				if ch.got != ch.want {
					t.Errorf("%s: %s = %d, want %d", tc.name, ch.label, ch.got, ch.want)
				}
			}
		})
	}
}

// TestReduceKnownValues asserts the subtract-22 reduction on specific inputs.
func TestReduceKnownValues(t *testing.T) {
	cases := []struct{ in, want int }{
		{1, 1},
		{22, 22},
		{23, 1},
		{44, 22},
		{45, 1},
		{66, 22},
		{25, 3},
		{29, 7},
		{31, 9},
		{19, 19},
	}
	for _, c := range cases {
		if got := reduce(c.in); got != c.want {
			t.Errorf("reduce(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

// TestReduceRangeInvariant asserts reduce never produces 0, a negative, or a
// value > 22 for any input 1..200.
func TestReduceRangeInvariant(t *testing.T) {
	for n := 1; n <= 200; n++ {
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
		{2026, 10},
	}
	for _, c := range cases {
		if got := digitSum(c.in); got != c.want {
			t.Errorf("digitSum(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

// TestComputeEdgeDates covers boundary day/month/year values and a leap date.
func TestComputeEdgeDates(t *testing.T) {
	cases := []struct {
		name        string
		y, m, d     int
		check       string // point key to assert
		want        int
	}{
		{"day 22 -> A=22", 1990, 6, 22, "A", 22},
		{"day 31 -> A=9", 1990, 12, 31, "A", 9},
		{"day 29 -> A=7", 2000, 2, 29, "A", 7}, // leap date, also year 2000
		{"year 2000 -> C=2", 2000, 2, 29, "C", 2},
		{"month 12 -> B=12", 1990, 12, 1, "B", 12},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := Compute(date(c.y, c.m, c.d)).Value(c.check)
			if got != c.want {
				t.Errorf("%s: %s = %d, want %d", c.name, c.check, got, c.want)
			}
		})
	}

	// year 1900: digitSum(1900)=10 -> C=10. Sanity that an early year works.
	if got := Compute(date(1900, 1, 1)).C; got != 10 {
		t.Errorf("year 1900: C = %d, want 10", got)
	}
}

// TestDeterminism asserts the same date always yields the same result.
func TestDeterminism(t *testing.T) {
	d := date(1987, 1, 7)
	first := Compute(d)
	for i := 0; i < 100; i++ {
		if !reflect.DeepEqual(Compute(d), first) {
			t.Fatalf("Compute is not deterministic for %v", d)
		}
	}
}

// TestSweepRangeInvariant computes a large sweep of dates and asserts every
// one of the nine points lands in 1..22. This catches any reduce edge that
// could emit 0 or 23.
func TestSweepRangeInvariant(t *testing.T) {
	years := []int{1900, 1987, 1999, 2000, 2024, 2026}
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

// TestAgeLadderShape asserts every birthdate yields exactly 80 rungs whose
// ages walk 1..80 in order and whose arcana stay in 1..22. The boundary
// rungs (ages 10/20/.../70) must also match the corresponding corner
// arcana so the perimeter visually matches the corners.
func TestAgeLadderShape(t *testing.T) {
	years := []int{1900, 1987, 1999, 2000, 2024, 2026}
	for _, y := range years {
		for m := 1; m <= 12; m++ {
			for d := 1; d <= 28; d++ {
				res := Compute(date(y, m, d))
				ladder := res.AgeLadder
				if len(ladder) != 80 {
					t.Fatalf("%04d-%02d-%02d ladder has %d rungs, want 80",
						y, m, d, len(ladder))
				}
				for i, rung := range ladder {
					if rung.Age != i+1 {
						t.Errorf("%04d-%02d-%02d ladder[%d].Age = %d, want %d",
							y, m, d, i, rung.Age, i+1)
					}
					if rung.Arcana < 1 || rung.Arcana > 22 {
						t.Errorf("%04d-%02d-%02d ladder[age %d] arcana = %d, out of range 1..22",
							y, m, d, rung.Age, rung.Arcana)
					}
				}
				// Decade boundaries: age 10 should match TL, age 20 → B, …
				boundaries := map[int]int{
					10: res.TL, 20: res.B, 30: res.TR,
					40: res.C, 50: res.BR, 60: res.D, 70: res.BL,
				}
				// Age 80 wraps back to the starting corner A.
				boundaries[80] = res.A
				for age, want := range boundaries {
					got := ladder[age-1].Arcana
					if got != want {
						t.Errorf("%04d-%02d-%02d ladder[age %d] = %d, want corner %d",
							y, m, d, age, got, want)
					}
				}
			}
		}
	}
}

// TestArcanaLookup asserts every value 1..22 resolves to a non-empty name and
// meaning, that boundary values 1 and 22 work, and out-of-range returns empty.
func TestArcanaLookup(t *testing.T) {
	for n := 1; n <= 22; n++ {
		name, meaning := Arcana(n)
		if name == "" {
			t.Errorf("Arcana(%d) name is empty", n)
		}
		if meaning == "" {
			t.Errorf("Arcana(%d) meaning is empty", n)
		}
		if ArcanaName(n) == "" {
			t.Errorf("ArcanaName(%d) is empty", n)
		}
		if ArcanaMeaning(n) == "" {
			t.Errorf("ArcanaMeaning(%d) is empty", n)
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
	r := Compute(date(1987, 1, 7))
	if got := r.Value("ZZ"); got != 0 {
		t.Errorf("Value(\"ZZ\") = %d, want 0", got)
	}
}
