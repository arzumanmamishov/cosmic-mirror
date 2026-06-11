package psychomatrix

import (
	"testing"
	"time"
)

func date(y, m, d int) time.Time {
	return time.Date(y, time.Month(m), d, 0, 0, 0, 0, time.UTC)
}

// computeCase is a full expected snapshot of a Compute() result, verified by
// hand against the canonical Alexandrov algorithm.
type computeCase struct {
	name           string
	y, m, d        int
	w1, w2, w3, w4 int
	// counts is the expected count for digits 1..9 (index 0 ignored).
	counts [10]int
}

func TestCompute_Fixtures(t *testing.T) {
	cases := []computeCase{
		// ---- Canonical acceptance fixtures (hand-verified) ----
		{
			name: "A_1985-07-05",
			y:    1985, m: 7, d: 5,
			w1: 35, w2: 8, w3: 25, w4: 7,
			// 1:1 2:1 3:1 4:0 5:4 6:0 7:2 8:2 9:1
			counts: [10]int{0, 1, 1, 1, 0, 4, 0, 2, 2, 1},
		},
		{
			name: "B_1971-05-20",
			y:    1971, m: 5, d: 20,
			w1: 25, w2: 7, w3: 21, w4: 3,
			// 1:3 2:3 3:1 4:0 5:2 6:0 7:2 8:0 9:1
			counts: [10]int{0, 3, 3, 1, 0, 2, 0, 2, 0, 1},
		},

		// ---- Edge: single-digit day, 2000+ year, leading-zero month/day ----
		{
			// D=1 M=1 Y=2000 -> dateDigits 1,1,2 ; W1=4 W2=4 W3=4-2=2 W4=2
			// pool: 1,1,2, 4, 4, 2, 2 -> 1:2 2:3 4:2
			name: "single_digit_2000-01-01",
			y:    2000, m: 1, d: 1,
			w1: 4, w2: 4, w3: 2, w4: 2,
			counts: [10]int{0, 2, 3, 0, 2, 0, 0, 0, 0, 0},
		},

		// ---- Edge: W3 == 0 ----
		{
			// D=8 M=3 Y=2003 -> dateDigits 8,3,2,3 ; W1=16 W2=7
			// firstDigit(8)=8 -> W3 = 16-16 = 0 ; W4 = dr(0) = 0
			// pool: 8,3,2,3, 1,6 (W1=16), 7 (W2), (W3=0 -> none), (W4=0 -> none)
			// -> 1:1 2:1 3:2 6:1 7:1 8:1
			name: "w3_zero_2003-03-08",
			y:    2003, m: 3, d: 8,
			w1: 16, w2: 7, w3: 0, w4: 0,
			counts: [10]int{0, 1, 1, 2, 0, 0, 1, 1, 1, 0},
		},

		// ---- Edge: W3 negative (firstDigitOfDay large, W1 small) ----
		{
			// D=9 M=1 Y=2000 -> dateDigits 9,1,2 ; W1=12 W2=dr(12)=3
			// firstDigit(9)=9 -> W3 = 12-18 = -6 (signed) ; W4 = dr(6) = 6
			// pool: 9,1,2, 1,2 (W1=12), 3 (W2), 6 (abs W3=6), 6 (W4)
			// -> 1:2 2:2 3:1 6:2 9:1
			name: "w3_negative_2000-01-09",
			y:    2000, m: 1, d: 9,
			w1: 12, w2: 3, w3: -6, w4: 6,
			counts: [10]int{0, 2, 2, 1, 0, 0, 2, 0, 0, 1},
		},

		// ---- Edge: day 31 -> firstDigitOfDay == 3 ; many repeats ----
		{
			// D=31 M=12 Y=1999 -> dateDigits 3,1,1,2,1,9,9,9
			// W1=3+1+1+2+1+9+9+9=35 ; W2=dr(35)=8
			// firstDigit(31)=3 -> W3 = 35-6 = 29 ; W4 = dr(29) = 2
			// pool: 3,1,1,2,1,9,9,9, 3,5 (W1=35), 8 (W2), 2,9 (W3=29), 2 (W4)
			// -> 1:3 2:3 3:2 5:1 8:1 9:4
			name: "day31_many_repeats_1999-12-31",
			y:    1999, m: 12, d: 31,
			w1: 35, w2: 8, w3: 29, w4: 2,
			counts: [10]int{0, 3, 3, 2, 0, 1, 0, 0, 1, 4},
		},

		// ---- Edge: day 30 -> firstDigitOfDay == 3 ----
		{
			// D=30 M=6 Y=1990 -> dateDigits 3,0,6,1,9,9,0
			// W1=3+0+6+1+9+9+0=28 ; W2=dr(28)=1
			// firstDigit(30)=3 -> W3 = 28-6 = 22 ; W4 = dr(22) = 4
			// pool (0s dropped): 3,6,1,9,9, 2,8 (W1=28), 1 (W2), 2,2 (W3=22), 4 (W4)
			// -> 1:2 2:3 3:1 4:1 6:1 8:1 9:2
			name: "day30_1990-06-30",
			y:    1990, m: 6, d: 30,
			w1: 28, w2: 1, w3: 22, w4: 4,
			counts: [10]int{0, 2, 3, 1, 1, 0, 1, 0, 1, 2},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := Compute(date(tc.y, tc.m, tc.d))
			if got.W1 != tc.w1 {
				t.Errorf("W1 = %d, want %d", got.W1, tc.w1)
			}
			if got.W2 != tc.w2 {
				t.Errorf("W2 = %d, want %d", got.W2, tc.w2)
			}
			if got.W3 != tc.w3 {
				t.Errorf("W3 = %d, want %d", got.W3, tc.w3)
			}
			if got.W4 != tc.w4 {
				t.Errorf("W4 = %d, want %d", got.W4, tc.w4)
			}
			for d := 1; d <= 9; d++ {
				if got.Counts[d] != tc.counts[d] {
					t.Errorf("Counts[%d] = %d, want %d (full got=%v want=%v)",
						d, got.Counts[d], tc.counts[d], got.Counts, tc.counts)
				}
			}
			// Sanity: index 0 must never be populated.
			if got.Counts[0] != 0 {
				t.Errorf("Counts[0] = %d, want 0 (zeros must be excluded)", got.Counts[0])
			}
		})
	}
}

// TestCompute_LineStrengths verifies line-strength sums against the canonical
// counts for the two acceptance fixtures.
func TestCompute_LineStrengths(t *testing.T) {
	// Fixture A: 1985-07-05. counts 1:1 2:1 3:1 4:0 5:4 6:0 7:2 8:2 9:1
	// row_147 = 1+0+2 = 3 ; row_258 = 1+4+2 = 7 ; row_369 = 1+0+1 = 2
	// col_123 = 1+1+1 = 3 ; col_456 = 0+4+0 = 4 ; col_789 = 2+2+1 = 5
	// diag_159 = 1+4+1 = 6 ; diag_357 = 1+4+2 = 7
	a := Compute(date(1985, 7, 5))
	wantA := map[string]int{
		"row_147": 3, "row_258": 7, "row_369": 2,
		"col_123": 3, "col_456": 4, "col_789": 5,
		"diag_159": 6, "diag_357": 7,
	}
	for k, want := range wantA {
		if a.Lines[k] != want {
			t.Errorf("A Lines[%q] = %d, want %d", k, a.Lines[k], want)
		}
	}

	// Fixture B: 1971-05-20. counts 1:3 2:3 3:1 4:0 5:2 6:0 7:2 8:0 9:1
	// row_147 = 3+0+2 = 5 ; row_258 = 3+2+0 = 5 ; row_369 = 1+0+1 = 2
	// col_123 = 3+3+1 = 7 ; col_456 = 0+2+0 = 2 ; col_789 = 2+0+1 = 3
	// diag_159 = 3+2+1 = 6 ; diag_357 = 1+2+2 = 5
	b := Compute(date(1971, 5, 20))
	wantB := map[string]int{
		"row_147": 5, "row_258": 5, "row_369": 2,
		"col_123": 7, "col_456": 2, "col_789": 3,
		"diag_159": 6, "diag_357": 5,
	}
	for k, want := range wantB {
		if b.Lines[k] != want {
			t.Errorf("B Lines[%q] = %d, want %d", k, b.Lines[k], want)
		}
	}

	// Every line must be present and equal to the sum of its three cells.
	for _, ld := range LineDefs {
		want := b.Counts[ld.Cells[0]] + b.Counts[ld.Cells[1]] + b.Counts[ld.Cells[2]]
		if b.Lines[ld.Key] != want {
			t.Errorf("Lines[%q] = %d, want sum of cells %v = %d",
				ld.Key, b.Lines[ld.Key], ld.Cells, want)
		}
	}
	if len(b.Lines) != 8 {
		t.Errorf("len(Lines) = %d, want 8", len(b.Lines))
	}
}

func TestDigitalRoot(t *testing.T) {
	cases := []struct{ in, want int }{
		{0, 0},
		{5, 5},
		{9, 9},   // 9 stays 9 (not 0) — no master numbers, but a single 9 is a digital root
		{10, 1},  // 1+0
		{18, 9},  // 1+8 = 9
		{19, 1},  // 1+9=10 -> 1
		{27, 9},  // multiple of 9 -> 9
		{99, 9},  // 9+9=18 -> 9
		{35, 8},  // 3+5
		{100, 1}, // 1+0+0
		{-6, 6},  // abs handling
		{-18, 9},
	}
	for _, c := range cases {
		if got := digitalRoot(c.in); got != c.want {
			t.Errorf("digitalRoot(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

func TestFirstDigitOfDay(t *testing.T) {
	cases := []struct{ in, want int }{
		// 1..9 -> itself
		{1, 1}, {2, 2}, {5, 5}, {9, 9},
		// 10..19 -> 1
		{10, 1}, {15, 1}, {19, 1},
		// 20..29 -> 2
		{20, 2}, {25, 2}, {29, 2},
		// 30..31 -> 3
		{30, 3}, {31, 3},
	}
	for _, c := range cases {
		if got := firstDigitOfDay(c.in); got != c.want {
			t.Errorf("firstDigitOfDay(%d) = %d, want %d", c.in, got, c.want)
		}
	}
}

func TestDigitsOf(t *testing.T) {
	cases := []struct {
		in   int
		want []int
	}{
		{0, nil},
		{5, []int{5}},
		{20, []int{2, 0}}, // zero IS a digit here (contributes 0 to W1, dropped from pool by Compute)
		{35, []int{3, 5}},
		{1985, []int{1, 9, 8, 5}},
		{2000, []int{2, 0, 0, 0}},
		{-29, []int{2, 9}}, // abs handling, most-significant-first
	}
	for _, c := range cases {
		got := digitsOf(c.in)
		if len(got) != len(c.want) {
			t.Errorf("digitsOf(%d) = %v, want %v", c.in, got, c.want)
			continue
		}
		for i := range got {
			if got[i] != c.want[i] {
				t.Errorf("digitsOf(%d) = %v, want %v", c.in, got, c.want)
				break
			}
		}
	}
}

// TestCompute_DoesNotPanic guards against panics across a broad sweep of dates,
// including all day values 1..31 and leap day.
func TestCompute_DoesNotPanic(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("Compute panicked: %v", r)
		}
	}()
	for d := 1; d <= 31; d++ {
		// Use a month/year that admits the day; January always has 31 days.
		_ = Compute(date(2024, 1, d))
	}
	_ = Compute(date(2024, 2, 29)) // leap day
	_ = Compute(date(1, 1, 1))     // year 1
}
