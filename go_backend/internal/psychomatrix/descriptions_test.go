package psychomatrix

import "testing"

// TestTurkishCompleteness asserts every English text entry has a non-empty
// Turkish counterpart, so new English entries can't silently fall back.
func TestTurkishCompleteness(t *testing.T) {
	for digit, title := range cellTitles {
		if title == "" {
			continue
		}
		if cellTitlesTR[digit] == "" {
			t.Errorf("cellTitlesTR[%d] missing", digit)
		}
	}
	for digit, bands := range cellBands {
		tr := cellBandsTR[digit]
		for i, en := range bands {
			if en != "" && tr[i] == "" {
				t.Errorf("cellBandsTR[%d][%d] missing", digit, i)
			}
		}
	}
	for key, title := range lineTitles {
		if title != "" && lineTitlesTR[key] == "" {
			t.Errorf("lineTitlesTR[%q] missing", key)
		}
	}
	for key, bands := range lineBands {
		tr := lineBandsTR[key]
		for i, en := range bands {
			if en != "" && tr[i] == "" {
				t.Errorf("lineBandsTR[%q][%d] missing", key, i)
			}
		}
	}
	// No stray Turkish keys that English doesn't have.
	for digit := range cellBandsTR {
		if _, ok := cellBands[digit]; !ok {
			t.Errorf("cellBandsTR has extra key %d", digit)
		}
	}
	for key := range lineBandsTR {
		if _, ok := lineBands[key]; !ok {
			t.Errorf("lineBandsTR has extra key %q", key)
		}
	}
}

func TestLanguageSelection(t *testing.T) {
	if got := CellTitle("en", 1); got != "Character" {
		t.Errorf("CellTitle(en,1) = %q", got)
	}
	if got := CellTitle("tr", 1); got != "Karakter" {
		t.Errorf("CellTitle(tr,1) = %q", got)
	}
	if got := CellTitle("de", 1); got != "Character" {
		t.Errorf("unknown lang should fall back to en, got %q", got)
	}
	if en, tr := CellMeaning("en", 2, 2), CellMeaning("tr", 2, 2); en == "" || tr == "" || en == tr {
		t.Errorf("CellMeaning en/tr = %q / %q", en, tr)
	}
	for _, ld := range LineDefs {
		for _, s := range []int{0, 3, 7} {
			en, tr := LineMeaning("en", ld.Key, s), LineMeaning("tr", ld.Key, s)
			if en == "" || tr == "" || en == tr {
				t.Errorf("LineMeaning(%s,%d) en/tr = %q / %q", ld.Key, s, en, tr)
			}
		}
		if LineTitle("tr", ld.Key) == LineTitle("en", ld.Key) {
			t.Errorf("LineTitle(%s) not translated", ld.Key)
		}
	}
}
