package service

import "unicode/utf8"

// truncateRunes shortens s to at most maxRunes runes, appending the ellipsis
// when it had to cut. Slicing by byte (s[:n]) can split a multibyte UTF-8
// rune and produce a garbled trailing character — this counts runes instead
// so notification snippets and auto-titles stay valid UTF-8.
func truncateRunes(s string, maxRunes int, ellipsis string) string {
	if utf8.RuneCountInString(s) <= maxRunes {
		return s
	}
	count := 0
	for i := range s {
		if count == maxRunes {
			return s[:i] + ellipsis
		}
		count++
	}
	return s + ellipsis
}
