package numerology

import "time"

// PersonalYear: birthMonth + birthDay + currentYear, reduced.
// Triggers each year on the user's birthday (technically Jan 1 in some
// schools — we use the birthday-trigger convention here).
func PersonalYear(birthDate, now time.Time) Number {
	m := reduceFinal(int(birthDate.Month()))
	d := reduceFinal(birthDate.Day())
	// The "current personal year" depends on whether the user's birthday has
	// already occurred this year — if not, we're still in last year's
	// personal year. Simplification: use the current calendar year.
	y := reduceFinal(now.Year())
	return reduce(m + d + y)
}

// PersonalMonth: PersonalYear + currentMonth, reduced.
func PersonalMonth(personalYear Number, now time.Time) Number {
	return reduce(personalYear.Value + reduceFinal(int(now.Month())))
}

// PersonalDay: PersonalMonth + currentDay, reduced.
func PersonalDay(personalMonth Number, now time.Time) Number {
	return reduce(personalMonth.Value + reduceFinal(now.Day()))
}

// PinnacleCycle is one of the four lifelong life-themes.
type PinnacleCycle struct {
	Index    int
	StartAge int // 0 for the first
	EndAge   int // -1 for "rest of life"
	Number   Number
	IsActive bool
}

// ChallengeCycle parallels Pinnacles but expresses growth-areas (computed
// as absolute differences instead of sums). Same age windows as the pinnacles.
type ChallengeCycle struct {
	Index    int
	StartAge int
	EndAge   int
	Number   Number
	IsActive bool
}

// Pinnacles: 4 lifelong cycles with values derived from the birth date.
// Age windows depend on the Life Path number per Pythagorean convention.
//
//   P1: birth → (36 - life path) reduced
//   P2: 9 years
//   P3: 9 years
//   P4: rest of life
func Pinnacles(birthDate time.Time, lifePath Number, currentAge int) [4]PinnacleCycle {
	m := reduceFinal(int(birthDate.Month()))
	d := reduceFinal(birthDate.Day())
	y := reduceFinal(birthDate.Year())

	p1Number := reduce(m + d)
	p2Number := reduce(d + y)
	p3Number := reduce(p1Number.Value + p2Number.Value)
	p4Number := reduce(m + y)

	// P1 ends at age (36 - life-path-base), where life-path-base reduces masters.
	lifeBase := lifePath.Value
	if lifePath.IsMaster {
		lifeBase = reduceFinal(lifeBase)
	}
	p1End := 36 - lifeBase
	if p1End < 27 {
		p1End = 27 // clamp; canonical range
	}

	out := [4]PinnacleCycle{
		{Index: 1, StartAge: 0, EndAge: p1End, Number: p1Number},
		{Index: 2, StartAge: p1End + 1, EndAge: p1End + 9, Number: p2Number},
		{Index: 3, StartAge: p1End + 10, EndAge: p1End + 18, Number: p3Number},
		{Index: 4, StartAge: p1End + 19, EndAge: -1, Number: p4Number},
	}
	for i := range out {
		out[i].IsActive = ageInRange(currentAge, out[i].StartAge, out[i].EndAge)
	}
	return out
}

// Challenges: same windows as Pinnacles, values are absolute differences.
func Challenges(birthDate time.Time, lifePath Number, currentAge int) [4]ChallengeCycle {
	m := reduceFinal(int(birthDate.Month()))
	d := reduceFinal(birthDate.Day())
	y := reduceFinal(birthDate.Year())

	c1 := reduce(absInt(m - d))
	c2 := reduce(absInt(d - y))
	c3 := reduce(absInt(c1.Value - c2.Value))
	c4 := reduce(absInt(m - y))

	lifeBase := lifePath.Value
	if lifePath.IsMaster {
		lifeBase = reduceFinal(lifeBase)
	}
	p1End := 36 - lifeBase
	if p1End < 27 {
		p1End = 27
	}

	out := [4]ChallengeCycle{
		{Index: 1, StartAge: 0, EndAge: p1End, Number: c1},
		{Index: 2, StartAge: p1End + 1, EndAge: p1End + 9, Number: c2},
		{Index: 3, StartAge: p1End + 10, EndAge: p1End + 18, Number: c3},
		{Index: 4, StartAge: p1End + 19, EndAge: -1, Number: c4},
	}
	for i := range out {
		out[i].IsActive = ageInRange(currentAge, out[i].StartAge, out[i].EndAge)
	}
	return out
}

func absInt(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func ageInRange(age, start, end int) bool {
	if age < start {
		return false
	}
	if end == -1 {
		return true
	}
	return age <= end
}

// AgeAt returns the user's age (in completed years) at `now` given a birth date.
func AgeAt(birthDate, now time.Time) int {
	years := now.Year() - birthDate.Year()
	if now.Month() < birthDate.Month() ||
		(now.Month() == birthDate.Month() && now.Day() < birthDate.Day()) {
		years--
	}
	if years < 0 {
		return 0
	}
	return years
}
