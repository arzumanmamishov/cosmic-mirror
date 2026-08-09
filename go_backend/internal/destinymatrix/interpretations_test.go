package destinymatrix

import "testing"

// Before the generator is run (empty/partial interpretations.json), every
// arcana must still yield usable text by falling back to the short meaning.
func TestDetailedMeaningFallsBackToShort(t *testing.T) {
	for n := 1; n <= 22; n++ {
		got := DetailedMeaning(n)
		if got == "" {
			t.Fatalf("DetailedMeaning(%d) returned empty", n)
		}
		if _, stored := detailedMeanings[n]; !stored {
			if got != ArcanaMeaning(n) {
				t.Fatalf("DetailedMeaning(%d) = %q, want fallback %q",
					n, got, ArcanaMeaning(n))
			}
		}
	}
}

// When a stored entry exists it is preferred over the short meaning.
func TestDetailedMeaningPrefersStored(t *testing.T) {
	const n = 7
	orig, had := detailedMeanings[n]
	detailedMeanings[n] = "STORED DETAIL"
	defer func() {
		if had {
			detailedMeanings[n] = orig
		} else {
			delete(detailedMeanings, n)
		}
	}()

	if got := DetailedMeaning(n); got != "STORED DETAIL" {
		t.Fatalf("DetailedMeaning(%d) = %q, want stored text", n, got)
	}
}
