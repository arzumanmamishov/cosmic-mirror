package service

import "testing"

// TestRepeatedDigit verifies the grid "Repeated" string rendering used to
// populate PsychomatrixCell.Repeated: a digit echoed Count times, "" absent.
func TestRepeatedDigit(t *testing.T) {
	cases := []struct {
		digit, count int
		want         string
	}{
		{1, 0, ""},      // absent
		{5, 0, ""},      // absent (any digit)
		{1, 1, "1"},     // single
		{1, 3, "111"},   // triple
		{9, 4, "9999"},  // abundant
		{7, 2, "77"},    // double
		{3, -1, ""},     // negative guarded -> empty
		{2, 5, "22222"}, // many
	}
	for _, c := range cases {
		if got := repeatedDigit(c.digit, c.count); got != c.want {
			t.Errorf("repeatedDigit(%d, %d) = %q, want %q", c.digit, c.count, got, c.want)
		}
	}
}
