package otp

import (
	"strings"
	"testing"
)

func TestRenderEmailLanguages(t *testing.T) {
	for _, p := range []Purpose{PurposeRegister, PurposeLogin, PurposePasswordReset, Purpose("other")} {
		subj, text, html := RenderEmail(p, "123456", "tr")
		if !strings.HasSuffix(subj, ": 123 456") || !strings.Contains(text, "Kodun: 123456") ||
			!strings.Contains(html, `lang="tr"`) || !strings.Contains(html, "123456") {
			t.Fatalf("tr %s: unexpected output %q / %q", p, subj, text)
		}
		enSubj, enText, _ := RenderEmail(p, "123456", "en")
		if enSubj == subj || !strings.Contains(enText, "Your code: 123456") {
			t.Fatalf("en %s: unexpected output %q", p, enSubj)
		}
	}
	// Unknown language falls back to English.
	got, _, _ := RenderEmail(PurposeLogin, "123456", "de")
	want, _, _ := RenderEmail(PurposeLogin, "123456", "en")
	if got != want {
		t.Fatalf("fallback: got %q want %q", got, want)
	}
}
