package numerology

import (
	"strings"
	"unicode"
)

// KarmicLessons returns the digits 1..9 that DO NOT appear among the letters
// of the full name. These are the "lessons" the soul came to learn this life.
func KarmicLessons(fullName string) []int {
	present := make(map[int]bool, 9)
	for _, r := range strings.ToUpper(fullName) {
		if !unicode.IsLetter(r) {
			continue
		}
		if v, ok := letterValue[r]; ok {
			present[v] = true
		}
	}
	out := make([]int, 0, 9)
	for d := 1; d <= 9; d++ {
		if !present[d] {
			out = append(out, d)
		}
	}
	return out
}

// HiddenPassion returns the digit 1..9 that occurs MOST often in the name.
// This is the soul's strongest gift / dominant tendency. Returns 0 if the
// name is empty.
func HiddenPassion(fullName string) int {
	count := make(map[int]int, 9)
	for _, r := range strings.ToUpper(fullName) {
		if !unicode.IsLetter(r) {
			continue
		}
		if v, ok := letterValue[r]; ok {
			count[v]++
		}
	}
	if len(count) == 0 {
		return 0
	}
	bestDigit := 0
	bestCount := -1
	for d := 1; d <= 9; d++ {
		if count[d] > bestCount {
			bestCount = count[d]
			bestDigit = d
		}
	}
	return bestDigit
}
