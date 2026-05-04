package numerology

// CompatibilityReport scores two numerology profiles 0..100 across the three
// most relationship-relevant numbers, plus a one-line summary.
type CompatibilityReport struct {
	Score           int
	LifePathScore   int
	ExpressionScore int
	SoulUrgeScore   int
	Summary         string
}

// classicCompat is a symmetric scoring table for Life Path pairings.
// Values follow the long-established Pythagorean compatibility chart
// (1-3 high, 1-7 high, 2-4 high, 2-8 medium, 3-6 high, 4-7 medium, 5-7 high
// for adventurous types, 6-9 high, 8-22 high, etc.). Master numbers (11,
// 22, 33) are treated as their reduced form (2, 4, 6) for scoring.
var classicCompat = map[[2]int]int{
	// 1 (Leader) — clashes with another 1, harmonious with 3, 5, 6, 7, 9
	{1, 1}: 55, {1, 2}: 50, {1, 3}: 85, {1, 4}: 50, {1, 5}: 80,
	{1, 6}: 75, {1, 7}: 80, {1, 8}: 60, {1, 9}: 80,
	// 2 (Diplomat) — bonds with 4, 6, 8, 9
	{2, 2}: 80, {2, 3}: 65, {2, 4}: 85, {2, 5}: 50, {2, 6}: 90,
	{2, 7}: 70, {2, 8}: 85, {2, 9}: 80,
	// 3 (Communicator)
	{3, 3}: 75, {3, 4}: 50, {3, 5}: 80, {3, 6}: 85, {3, 7}: 60,
	{3, 8}: 55, {3, 9}: 80,
	// 4 (Builder)
	{4, 4}: 70, {4, 5}: 50, {4, 6}: 75, {4, 7}: 85, {4, 8}: 90, {4, 9}: 65,
	// 5 (Adventurer)
	{5, 5}: 75, {5, 6}: 60, {5, 7}: 85, {5, 8}: 65, {5, 9}: 75,
	// 6 (Caretaker)
	{6, 6}: 80, {6, 7}: 65, {6, 8}: 70, {6, 9}: 90,
	// 7 (Seeker)
	{7, 7}: 65, {7, 8}: 60, {7, 9}: 75,
	// 8 (Powerhouse)
	{8, 8}: 75, {8, 9}: 70,
	// 9 (Humanitarian)
	{9, 9}: 80,
}

func compatScore(a, b int) int {
	a = reduceMaster(a)
	b = reduceMaster(b)
	if a > b {
		a, b = b, a
	}
	if v, ok := classicCompat[[2]int{a, b}]; ok {
		return v
	}
	return 60 // neutral fallback
}

func reduceMaster(v int) int {
	if v == 11 {
		return 2
	}
	if v == 22 {
		return 4
	}
	if v == 33 {
		return 6
	}
	return v
}

// Compatibility weights Life Path 50 %, Expression 30 %, Soul Urge 20 %.
func Compatibility(aLife, aExpr, aSoul, bLife, bExpr, bSoul Number) CompatibilityReport {
	lp := compatScore(aLife.Value, bLife.Value)
	ex := compatScore(aExpr.Value, bExpr.Value)
	su := compatScore(aSoul.Value, bSoul.Value)
	total := (lp*50 + ex*30 + su*20) / 100

	summary := ""
	switch {
	case total >= 85:
		summary = "Strong, mutually-supportive resonance."
	case total >= 70:
		summary = "Good chemistry with healthy growth-edges."
	case total >= 55:
		summary = "Workable; differences sharpen each other."
	default:
		summary = "Significant differences — conscious effort needed."
	}

	return CompatibilityReport{
		Score:           total,
		LifePathScore:   lp,
		ExpressionScore: ex,
		SoulUrgeScore:   su,
		Summary:         summary,
	}
}
