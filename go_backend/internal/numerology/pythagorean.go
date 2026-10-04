// Package numerology computes Pythagorean numerology profiles + cycles +
// karmic patterns + two-person compatibility. Pure Go, no DB, no cgo.
package numerology

import (
	"strings"
	"unicode"
)

// letterValue maps each Latin letter to its Pythagorean digit.
//
//	A=1, B=2, ..., I=9, J=1, ..., R=9, S=1, T=2, ..., Z=8.
//
// Reduce-by-9 is the canonical Pythagorean assignment.
var letterValue = map[rune]int{
	'A': 1, 'J': 1, 'S': 1,
	'B': 2, 'K': 2, 'T': 2,
	'C': 3, 'L': 3, 'U': 3,
	'D': 4, 'M': 4, 'V': 4,
	'E': 5, 'N': 5, 'W': 5,
	'F': 6, 'O': 6, 'X': 6,
	'G': 7, 'P': 7, 'Y': 7,
	'H': 8, 'Q': 8, 'Z': 8,
	'I': 9, 'R': 9,
}

// vowels is the standard set. Y is treated as a consonant in this
// implementation (a common modern Pythagorean convention).
var vowels = map[rune]bool{
	'A': true, 'E': true, 'I': true, 'O': true, 'U': true,
}

// letterFolds maps upper-case accented / non-English Latin letters to the
// A–Z letter they're numbered as. Turkish (Ç Ğ İ I Ö Ş Ü — dotless ı
// upper-cases to plain I) and Azerbaijani (Ə, which romanises to A as in
// Məmmədov → Mammadov) come first, then common Western/Central European
// accents. Without this, "Gökçe Şahin" silently lost ö, ç and ş and got
// different numbers from "Gokce Sahin".
var letterFolds = map[rune]rune{
	// Turkish / Azerbaijani
	'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U', 'Ə': 'A',
	// A
	'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A', 'Ā': 'A', 'Ă': 'A', 'Ą': 'A',
	// C D
	'Ć': 'C', 'Ĉ': 'C', 'Ċ': 'C', 'Č': 'C', 'Ď': 'D', 'Đ': 'D', 'Ð': 'D',
	// E
	'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ĕ': 'E', 'Ė': 'E', 'Ę': 'E', 'Ě': 'E',
	// G H
	'Ĝ': 'G', 'Ġ': 'G', 'Ģ': 'G', 'Ĥ': 'H', 'Ħ': 'H',
	// I J K
	'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ĩ': 'I', 'Ī': 'I', 'Ĭ': 'I', 'Į': 'I', 'Ĵ': 'J', 'Ķ': 'K',
	// L N
	'Ĺ': 'L', 'Ļ': 'L', 'Ľ': 'L', 'Ŀ': 'L', 'Ł': 'L', 'Ñ': 'N', 'Ń': 'N', 'Ņ': 'N', 'Ň': 'N',
	// O
	'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ø': 'O', 'Ō': 'O', 'Ŏ': 'O', 'Ő': 'O',
	// R S T
	'Ŕ': 'R', 'Ŗ': 'R', 'Ř': 'R', 'Ś': 'S', 'Ŝ': 'S', 'Š': 'S', 'Ș': 'S',
	'Ţ': 'T', 'Ť': 'T', 'Ŧ': 'T', 'Ț': 'T',
	// U W Y Z
	'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ũ': 'U', 'Ū': 'U', 'Ŭ': 'U', 'Ů': 'U', 'Ű': 'U', 'Ų': 'U',
	'Ŵ': 'W', 'Ý': 'Y', 'Ÿ': 'Y', 'Ŷ': 'Y', 'Ź': 'Z', 'Ż': 'Z', 'Ž': 'Z',
}

// Folded letters inherit the value and vowel-ness of their base letter, so
// every lookup (including KarmicLessons / HiddenPassion) handles them.
// Ö and Ü therefore count as vowels.
func init() {
	for folded, base := range letterFolds {
		letterValue[folded] = letterValue[base]
		if vowels[base] {
			vowels[folded] = true
		}
	}
}

// ligatures are letters that romanise to two letters.
var ligatures = strings.NewReplacer("ß", "SS", "ẞ", "SS", "Æ", "AE", "æ", "AE", "Œ", "OE", "œ", "OE")

// turkicOnly are letters that only occur in Turkish / Azerbaijani names.
// Their presence switches upper-casing to Turkish rules (i → İ), which
// keeps the per-letter breakdown readable ("ŞAHİN", not "ŞAHIN"); values
// are identical either way because İ and I both fold to I.
const turkicOnly = "ğĞıİşŞəƏ"

// upperName upper-cases a name for numerology, expanding ligatures.
func upperName(s string) string {
	s = ligatures.Replace(s)
	if strings.ContainsAny(s, turkicOnly) {
		return strings.ToUpperSpecial(unicode.TurkishCase, s)
	}
	return strings.ToUpper(s)
}

// Number is the result of any numerology calculation. RawSum is the value
// before final reduction (so the UI can show "29/11/2"). IsMaster /
// IsKarmicDebt flags signal special meanings.
type Number struct {
	Value        int  // 1..9 OR master 11/22/33
	RawSum       int  // pre-reduction sum (e.g. 29 → 11 → 2 means RawSum=29, Value=11 master)
	IsMaster     bool // 11, 22, 33
	IsKarmicDebt bool // any intermediate sum was 13, 14, 16, or 19
}

// karmicDebtNumbers are the four "debt" sums in Pythagorean numerology;
// when a number reduces *through* one of these, it carries karmic weight.
var karmicDebtNumbers = map[int]bool{13: true, 14: true, 16: true, 19: true}

// reduce sums digits until a single digit, master (11/22/33), or 0. It
// records whether the path passed through a karmic-debt number.
func reduce(n int) Number {
	if n < 0 {
		n = -n
	}
	raw := n
	hadDebt := false
	for {
		if karmicDebtNumbers[n] {
			hadDebt = true
		}
		if n < 10 {
			return Number{Value: n, RawSum: raw, IsKarmicDebt: hadDebt}
		}
		if n == 11 || n == 22 || n == 33 {
			return Number{Value: n, RawSum: raw, IsMaster: true, IsKarmicDebt: hadDebt}
		}
		// Sum digits and loop.
		next := 0
		for n > 0 {
			next += n % 10
			n /= 10
		}
		n = next
	}
}

// reduceFinal is reduce + collapse master through to single digit. Used for
// internal arithmetic where masters shouldn't propagate (e.g. computing
// challenge cycles).
func reduceFinal(n int) int {
	r := reduce(n)
	if r.IsMaster {
		// 11→2, 22→4, 33→6
		v := r.Value
		out := 0
		for v > 0 {
			out += v % 10
			v /= 10
		}
		return out
	}
	return r.Value
}

// sumLetters maps each character of s to its Pythagorean digit, summing them.
// Non-letters are ignored. The result is the unreduced sum.
func sumLetters(s string, predicate func(rune) bool) int {
	total := 0
	for _, r := range upperName(s) {
		if !unicode.IsLetter(r) {
			continue
		}
		if predicate != nil && !predicate(r) {
			continue
		}
		if v, ok := letterValue[r]; ok {
			total += v
		}
	}
	return total
}

// allLetters predicate — every letter counts.
func allLetters(rune) bool { return true }

// onlyVowels predicate — only A/E/I/O/U (and their folded forms).
func onlyVowels(r rune) bool { return vowels[r] }

// onlyConsonants predicate — letters that are NOT vowels.
func onlyConsonants(r rune) bool { return !vowels[r] }

// LetterBreakdown is one entry in a name's letter-by-letter decomposition.
// Used by the standalone Name Calculator UI to show users HOW the totals
// were assembled (Expression / SoulUrge / Personality).
type LetterBreakdown struct {
	Letter  rune
	Value   int
	IsVowel bool
}

// LettersOf returns the per-letter decomposition of fullName, skipping
// non-letters. Order is preserved so the UI can render the original
// spacing/word breaks by re-walking the input string.
func LettersOf(fullName string) []LetterBreakdown {
	out := make([]LetterBreakdown, 0, len(fullName))
	for _, r := range upperName(fullName) {
		if !unicode.IsLetter(r) {
			continue
		}
		v, ok := letterValue[r]
		if !ok {
			continue
		}
		out = append(out, LetterBreakdown{
			Letter:  r,
			Value:   v,
			IsVowel: vowels[r],
		})
	}
	return out
}
