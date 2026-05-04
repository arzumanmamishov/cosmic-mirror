package numerology

import "time"

// LifePath: sum month + day + year, reducing each part separately first
// (the canonical method that preserves master numbers through partial sums).
func LifePath(birthDate time.Time) Number {
	m := reduceFinal(int(birthDate.Month()))
	d := reduceFinal(birthDate.Day())
	y := reduceFinal(birthDate.Year())
	return reduce(m + d + y + 0) // +0 to keep raw sum tracking happy
}

// Expression / Destiny: sum every letter of the full birth name, reduce.
func Expression(fullName string) Number {
	return reduce(sumLetters(fullName, allLetters))
}

// SoulUrge / Heart's Desire: sum vowels of full name, reduce.
func SoulUrge(fullName string) Number {
	return reduce(sumLetters(fullName, onlyVowels))
}

// Personality: sum consonants of full name, reduce.
func Personality(fullName string) Number {
	return reduce(sumLetters(fullName, onlyConsonants))
}

// Maturity: Life Path + Expression, reduce.
func Maturity(life, expr Number) Number {
	return reduce(life.Value + expr.Value)
}

// Birthday: just the day-of-month with master-number preservation.
// Day 11 / 22 stay as master; day 33 doesn't occur in calendars.
func Birthday(birthDate time.Time) Number {
	return reduce(birthDate.Day())
}
