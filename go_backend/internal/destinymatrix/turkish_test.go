package destinymatrix

import "testing"

// TestTurkishCompleteness asserts every English text entry has a non-empty
// Turkish counterpart, so new English entries can't silently fall back.
func TestTurkishCompleteness(t *testing.T) {
	for n, en := range arcana {
		tr, ok := arcanaTR[n]
		if !ok {
			t.Errorf("arcanaTR[%d] missing", n)
			continue
		}
		if en.name != "" && tr.name == "" {
			t.Errorf("arcanaTR[%d].name missing", n)
		}
		if en.meaning != "" && tr.meaning == "" {
			t.Errorf("arcanaTR[%d].meaning missing", n)
		}
	}
	for n := range arcanaTR {
		if _, ok := arcana[n]; !ok {
			t.Errorf("arcanaTR has extra key %d", n)
		}
	}
	for _, pd := range PointDefs {
		if pd.Title != "" && pointTitlesTR[pd.Key] == "" {
			t.Errorf("pointTitlesTR[%q] missing", pd.Key)
		}
	}
	for _, ld := range LineDefs {
		tr := lineTextTR[ld.Key]
		if ld.Title != "" && tr.title == "" {
			t.Errorf("lineTextTR[%q].title missing", ld.Key)
		}
		if ld.Theme != "" && tr.theme == "" {
			t.Errorf("lineTextTR[%q].theme missing", ld.Key)
		}
	}
}

func TestLocalizedLookups(t *testing.T) {
	if name, _ := Arcana("tr", 1); name != "Büyücü" {
		t.Errorf("Arcana(tr,1) name = %q", name)
	}
	if name, _ := Arcana("xx", 1); name != "The Magician" {
		t.Errorf("unknown lang should fall back to en, got %q", name)
	}
	if name, meaning := Arcana("tr", 0); name != "" || meaning != "" {
		t.Errorf("Arcana(tr,0) = (%q,%q), want empty", name, meaning)
	}
	if ArcanaName("tr", 22) != "Deli" || ArcanaMeaning("en", 22) == ArcanaMeaning("tr", 22) {
		t.Errorf("ArcanaName/ArcanaMeaning not localized")
	}
	for _, pd := range PointDefs {
		if got := PointTitle("en", pd.Key); got != pd.Title {
			t.Errorf("PointTitle(en,%q) = %q, want %q", pd.Key, got, pd.Title)
		}
		if got := PointTitle("tr", pd.Key); got == "" || got == pd.Title {
			t.Errorf("PointTitle(tr,%q) = %q", pd.Key, got)
		}
	}
	for _, ld := range LineDefs {
		if LineTitle("en", ld.Key) != ld.Title || LineTheme("en", ld.Key) != ld.Theme {
			t.Errorf("english line text changed for %q", ld.Key)
		}
		if LineTitle("tr", ld.Key) == ld.Title || LineTheme("tr", ld.Key) == ld.Theme {
			t.Errorf("line %q not translated", ld.Key)
		}
	}
	if PointTitle("tr", "nope") != "" || LineTitle("en", "nope") != "" || LineTheme("tr", "nope") != "" {
		t.Errorf("unknown keys should return empty")
	}
}
