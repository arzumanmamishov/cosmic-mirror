package numerology

import "testing"

func TestDiacriticsFoldToBaseLetters(t *testing.T) {
	pairs := [][2]string{
		{"Gökçe Şahin", "Gokce Sahin"},
		{"GÖKÇE ŞAHİN", "GOKCE SAHIN"},
		{"Işıl Ağaoğlu", "Isil Agaoglu"},
		{"Ümit Özdağ", "Umit Ozdag"},
		{"Məmmədov", "Mammadov"},
		{"José Müller", "Jose Muller"},
		{"Straße", "Strasse"},
	}
	for _, p := range pairs {
		a, b := p[0], p[1]
		if Expression(a) != Expression(b) {
			t.Errorf("Expression(%q)=%v != Expression(%q)=%v", a, Expression(a), b, Expression(b))
		}
		if SoulUrge(a) != SoulUrge(b) {
			t.Errorf("SoulUrge(%q)=%v != SoulUrge(%q)=%v", a, SoulUrge(a), b, SoulUrge(b))
		}
		if Personality(a) != Personality(b) {
			t.Errorf("Personality(%q)=%v != Personality(%q)=%v", a, Personality(a), b, Personality(b))
		}
		if len(LettersOf(a)) != len(LettersOf(b)) {
			t.Errorf("LettersOf(%q) has %d letters, %q has %d", a, len(LettersOf(a)), b, len(LettersOf(b)))
		}
		if HiddenPassion(a) != HiddenPassion(b) {
			t.Errorf("HiddenPassion differs for %q / %q", a, b)
		}
	}
}

func TestTurkishVowels(t *testing.T) {
	for _, l := range LettersOf("öüıiÖÜIİ") {
		if !l.IsVowel {
			t.Errorf("%q should be a vowel", l.Letter)
		}
	}
	// Turkish names keep their Turkish capitals in the breakdown.
	if got := string(LettersOf("Şahin")[3].Letter); got != "İ" {
		t.Errorf("want İ in breakdown, got %q", got)
	}
}
