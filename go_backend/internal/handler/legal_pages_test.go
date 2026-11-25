package handler

import (
	"crypto/sha256"
	"encoding/base64"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLegalPagesRender(t *testing.T) {
	sum := sha256.Sum256([]byte(legalPageCSS))
	styleHash := "'sha256-" + base64.StdEncoding.EncodeToString(sum[:]) + "'"

	pages := []struct {
		path string
		h    http.HandlerFunc
		want []string
	}{
		{"/", HomePage, []string{"Lively", `href="/privacy"`}},
		{"/privacy", PrivacyPage, []string{"PRIVACY POLICY", "1. DATA WE COLLECT", "<li>Account data:", legalContactEmail}},
		{"/terms", TermsPage, []string{"TERMS OF SERVICE", "Federal Republic of Germany", legalContactEmail}},
		{"/support", SupportPage, []string{"IMPRESSUM", "§ 5 DDG", legalContactEmail, `href="/delete-account"`}},
		{"/delete-account", DeleteAccountPage, []string{"Delete Account", "within 30 days", legalContactEmail}},
	}
	for _, p := range pages {
		rec := httptest.NewRecorder()
		p.h(rec, httptest.NewRequest(http.MethodGet, p.path, nil))
		if rec.Code != http.StatusOK {
			t.Fatalf("GET %s = %d", p.path, rec.Code)
		}
		if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "text/html") {
			t.Errorf("GET %s Content-Type = %q", p.path, ct)
		}
		csp := rec.Header().Get("Content-Security-Policy")
		if !strings.Contains(csp, styleHash) || strings.Contains(csp, "script-src") {
			t.Errorf("GET %s CSP = %q, want only the page style allowed", p.path, csp)
		}
		body := rec.Body.String()
		for _, w := range p.want {
			if !strings.Contains(body, w) {
				t.Errorf("GET %s: body missing %q", p.path, w)
			}
		}
		if strings.Contains(body, "{{") {
			t.Errorf("GET %s: unreplaced template token", p.path)
		}
	}
}

func TestLegalDocumentReflowsText(t *testing.T) {
	text := "TITLE\nEffective: today\n\n1. FIRST\nA paragraph that\nwraps.\n• One item\n  continues here.\n• Two\nAfter the list.\n\nClosing words."
	heading, meta, blocks := legalDocument(text)
	if heading != "TITLE" || meta != "Effective: today" {
		t.Fatalf("heading/meta = %q / %q", heading, meta)
	}
	want := []legalBlock{
		{Kind: "h2", Text: "1. FIRST"},
		{Kind: "p", Text: "A paragraph that wraps."},
		{Kind: "ul", Items: []string{"One item continues here.", "Two"}},
		{Kind: "p", Text: "After the list."},
		{Kind: "p", Text: "Closing words."},
	}
	if len(blocks) != len(want) {
		t.Fatalf("blocks = %+v", blocks)
	}
	for i := range want {
		if blocks[i].Kind != want[i].Kind || blocks[i].Text != want[i].Text ||
			strings.Join(blocks[i].Items, "|") != strings.Join(want[i].Items, "|") {
			t.Errorf("block %d = %+v, want %+v", i, blocks[i], want[i])
		}
	}
}
