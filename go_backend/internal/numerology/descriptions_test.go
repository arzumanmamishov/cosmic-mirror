package numerology

import "testing"

// TestTurkishCompleteness asserts every English description has a non-empty
// Turkish counterpart, so new English entries can't silently fall back.
func TestTurkishCompleteness(t *testing.T) {
	for v, en := range masterDesc {
		if en != "" && masterDescTR[v] == "" {
			t.Errorf("masterDescTR[%d] missing", v)
		}
	}
	for kind, table := range descTables {
		trTable, ok := descTablesTR[kind]
		if !ok {
			t.Errorf("descTablesTR[%q] missing", kind)
			continue
		}
		for v, en := range table {
			if en != "" && trTable[v] == "" {
				t.Errorf("descTablesTR[%q][%d] missing", kind, v)
			}
		}
	}
	for kind := range descTablesTR {
		if _, ok := descTables[kind]; !ok {
			t.Errorf("descTablesTR has extra kind %q", kind)
		}
	}
	for i, en := range compatSummaries {
		if en != "" && compatSummariesTR[i] == "" {
			t.Errorf("compatSummariesTR[%d] missing", i)
		}
	}
}

func TestDescriptionLanguage(t *testing.T) {
	n := Number{Value: 7}
	en := Description("en", "life_path", n)
	tr := Description("tr", "life_path", n)
	if en == "" || tr == "" || en == tr {
		t.Errorf("life_path 7 en/tr = %q / %q", en, tr)
	}
	if got := Description("xx", "life_path", n); got != en {
		t.Errorf("unknown lang should fall back to en, got %q", got)
	}
	m := Number{Value: 22, IsMaster: true}
	if got := Description("tr", "expression", m); got != masterDescTR[22] {
		t.Errorf("master 22 tr = %q", got)
	}
	if got := Description("en", "expression", m); got != masterDesc[22] {
		t.Errorf("master 22 en = %q", got)
	}
	if got := Description("tr", "unknown_kind", n); got != "" {
		t.Errorf("unknown kind should be empty, got %q", got)
	}
}

func TestCompatibilitySummaryLanguage(t *testing.T) {
	for _, total := range []int{90, 75, 60, 40} {
		en, tr := CompatibilitySummary("en", total), CompatibilitySummary("tr", total)
		if en == "" || tr == "" || en == tr {
			t.Errorf("summary(%d) en/tr = %q / %q", total, en, tr)
		}
	}
	if got := CompatibilitySummary("en", 90); got != "Strong, mutually-supportive resonance." {
		t.Errorf("english summary changed: %q", got)
	}
	r := Compatibility("tr", Number{Value: 1}, Number{Value: 1}, Number{Value: 1}, Number{Value: 3}, Number{Value: 3}, Number{Value: 3})
	if r.Summary != CompatibilitySummary("tr", r.Score) {
		t.Errorf("Compatibility(tr) summary = %q", r.Summary)
	}
}
