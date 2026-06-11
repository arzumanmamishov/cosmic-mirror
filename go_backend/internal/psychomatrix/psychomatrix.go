// Package psychomatrix implements the Pythagoras Square (Psychomatrix)
// calculator using the canonical Alexandrov method.
//
// The algorithm derives four "working numbers" from a birth date and then
// pools all the digits (date digits + working-number digits, ignoring zeros)
// to count how many times each digit 1..9 appears. Those counts populate a
// 3x3 grid (column-major) whose cells and lines carry interpretive meaning.
//
// Everything here is pure and deterministic — no clock, no I/O.
package psychomatrix

import "time"

// Result is the raw computed output: the four working numbers, the nine
// digit counts (indexed 1..9; index 0 is unused), and the eight line
// strengths keyed by their stable Key.
type Result struct {
	W1     int // first working number: sum of all date digits
	W2     int // second working number: digital root of W1
	W3     int // third working number: W1 - 2*firstDigitOfDay (signed)
	W4     int // fourth working number: digital root of abs(W3)
	Counts [10]int
	Lines  map[string]int
}

// LineDef describes one of the eight lines (rows, columns, diagonals) of the
// grid: a stable key and the three cells it spans.
type LineDef struct {
	Key   string
	Cells [3]int
}

// LineDefs is the canonical ordered list of the eight lines.
var LineDefs = []LineDef{
	{Key: "row_147", Cells: [3]int{1, 4, 7}},
	{Key: "row_258", Cells: [3]int{2, 5, 8}},
	{Key: "row_369", Cells: [3]int{3, 6, 9}},
	{Key: "col_123", Cells: [3]int{1, 2, 3}},
	{Key: "col_456", Cells: [3]int{4, 5, 6}},
	{Key: "col_789", Cells: [3]int{7, 8, 9}},
	{Key: "diag_159", Cells: [3]int{1, 5, 9}},
	{Key: "diag_357", Cells: [3]int{3, 5, 7}},
}

// Compute runs the canonical Alexandrov psychomatrix algorithm for a birth
// date and returns the working numbers, digit counts, and line strengths.
func Compute(birthDate time.Time) Result {
	d := birthDate.Day()
	m := int(birthDate.Month())
	y := birthDate.Year()

	// Step 1: collect the decimal digits of D, M, Y (leading zeros add nothing).
	dateDigits := make([]int, 0, 12)
	dateDigits = append(dateDigits, digitsOf(d)...)
	dateDigits = append(dateDigits, digitsOf(m)...)
	dateDigits = append(dateDigits, digitsOf(y)...)

	// Step 2: W1 = sum of all date digits.
	w1 := 0
	for _, dg := range dateDigits {
		w1 += dg
	}

	// Step 3: W2 = digital root of W1.
	w2 := digitalRoot(w1)

	// Step 4 & 5: W3 = W1 - 2*firstDigitOfDay (kept signed).
	w3 := w1 - 2*firstDigitOfDay(d)

	// Step 6: W4 = digital root of abs(W3).
	w4 := digitalRoot(abs(w3))

	// Step 7: build the digit pool, ignoring zeros.
	pool := make([]int, 0, 24)
	pool = append(pool, dateDigits...)
	pool = append(pool, digitsOf(w1)...)
	pool = append(pool, digitsOf(w2)...)
	pool = append(pool, digitsOf(abs(w3))...)
	pool = append(pool, digitsOf(w4)...)

	// Step 8: count occurrences of each digit 1..9.
	var counts [10]int
	for _, dg := range pool {
		if dg >= 1 && dg <= 9 {
			counts[dg]++
		}
	}

	// Step 9 (line strengths): sum the counts of each line's three cells.
	lines := make(map[string]int, len(LineDefs))
	for _, ld := range LineDefs {
		lines[ld.Key] = counts[ld.Cells[0]] + counts[ld.Cells[1]] + counts[ld.Cells[2]]
	}

	return Result{
		W1:     w1,
		W2:     w2,
		W3:     w3,
		W4:     w4,
		Counts: counts,
		Lines:  lines,
	}
}

// digitsOf returns the decimal digits of abs(n) in most-significant order.
// digitsOf(0) returns nil (a lone zero contributes no non-zero digits, and
// in the pool zeros are ignored anyway).
func digitsOf(n int) []int {
	n = abs(n)
	if n == 0 {
		return nil
	}
	var rev []int
	for n > 0 {
		rev = append(rev, n%10)
		n /= 10
	}
	// reverse into most-significant-first order
	out := make([]int, len(rev))
	for i, v := range rev {
		out[len(rev)-1-i] = v
	}
	return out
}

// digitalRoot repeatedly sums the digits of abs(n) until a single digit
// remains. It does NOT preserve master numbers. digitalRoot(0) == 0.
func digitalRoot(n int) int {
	n = abs(n)
	for n >= 10 {
		s := 0
		for n > 0 {
			s += n % 10
			n /= 10
		}
		n = s
	}
	return n
}

// firstDigitOfDay returns the most-significant (first non-zero) digit of the
// day-of-month. For D in 1..9 it is D; 10..19 -> 1; 20..29 -> 2; 30..31 -> 3.
func firstDigitOfDay(d int) int {
	d = abs(d)
	if d == 0 {
		return 0
	}
	for d >= 10 {
		d /= 10
	}
	return d
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}
