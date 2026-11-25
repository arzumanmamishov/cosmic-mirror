package handler

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"html/template"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"
)

// Public web pages on the API's own domain: the home page, the privacy
// policy, the terms, support and account deletion. They're the URLs the
// app and the store listings link to (Apple and Google require a privacy
// policy URL, a support URL and — Google — an account-deletion URL), so
// they don't depend on a separate website being deployed. The privacy
// policy and terms render the same text as /api/v1/legal/*.

const legalPageCSS = `:root{color-scheme:light dark;--bg:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--line:rgba(11,11,11,.12);--accent:#2a78d6}
@media (prefers-color-scheme:dark){:root{--bg:#121211;--ink:#f0efec;--ink2:#b9b8b0;--line:rgba(255,255,255,.14);--accent:#5598e7}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent)}
.top{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap;max-width:760px;margin:0 auto;padding:20px 20px 0}
.brand{font-weight:700;font-size:18px;color:var(--ink);text-decoration:none}
nav{display:flex;gap:16px;flex-wrap:wrap}
nav a{color:var(--ink2);text-decoration:none}
nav a:hover{color:var(--ink)}
main{max-width:760px;margin:0 auto;padding:24px 20px 48px}
h1{font-size:30px;line-height:1.2;margin:16px 0 8px}
h2{font-size:15px;letter-spacing:.04em;margin:32px 0 8px}
.meta,.lead{color:var(--ink2)}
.lead{font-size:18px}
ul{padding-left:22px}
li{margin:6px 0}
address{font-style:normal}
footer{max-width:760px;margin:0 auto;padding:20px;border-top:1px solid var(--line);color:var(--ink2);font-size:14px}`

// legalPageCSP allows exactly the page's own inline <style> (by hash) and
// nothing else: no scripts at all.
var legalPageCSP = func() string {
	sum := sha256.Sum256([]byte(legalPageCSS))
	return "default-src 'none'; style-src 'sha256-" + base64.StdEncoding.EncodeToString(sum[:]) +
		"'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
}()

const legalLayout = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{.Title}}</title>
<meta name="description" content="{{.Description}}">
<style>{{.CSS}}</style>
</head>
<body>
<header class="top">
<a class="brand" href="/">Lively</a>
<nav><a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="/support">Support</a></nav>
</header>
<main>
{{block "content" .}}{{end}}
</main>
<footer>© {{.Year}} {{.Operator}} · <a href="mailto:{{.Email}}">{{.Email}}</a></footer>
</body>
</html>`

const legalDocContent = `{{define "content"}}
<h1>{{.Heading}}</h1>
{{if .Meta}}<p class="meta">{{.Meta}}</p>{{end}}
{{range .Blocks}}{{if eq .Kind "h2"}}<h2>{{.Text}}</h2>
{{else if eq .Kind "ul"}}<ul>{{range .Items}}<li>{{.}}</li>{{end}}</ul>
{{else}}<p>{{.Text}}</p>
{{end}}{{end}}
{{end}}`

const homeContent = `{{define "content"}}
<h1>Lively</h1>
<p class="lead">Astrology and self-guidance: your birth chart, daily readings, numerology, Human Design, compatibility and an AI astrologer.</p>
<p><a href="/privacy">Privacy policy</a> · <a href="/terms">Terms of service</a> · <a href="/support">Support</a></p>
{{end}}`

const supportContent = `{{define "content"}}
<h1>Support</h1>
<p class="lead">Questions, problems or feedback? Email us at <a href="mailto:{{.Email}}">{{.Email}}</a>.</p>

<h2>DELETE YOUR ACCOUNT</h2>
<p>In the app, open Profile → Settings → Delete Account. You can also ask us by email. <a href="/delete-account">How account deletion works</a>.</p>

<h2>SUBSCRIPTIONS</h2>
<ul>
<li>Subscriptions bought in the app are billed by Apple (App Store) or Google (Google Play). To change or cancel one, open the subscription settings of your App Store or Google Play account.</li>
<li>Deleting your Lively account does not cancel a store subscription. Cancel it in the store first.</li>
<li>Refunds are handled by Apple or Google under their refund policies.</li>
<li>Bought on our website? Email us to change or cancel it.</li>
</ul>

<h2>REPORT CONTENT OR A USER</h2>
<p>Every post, comment, space and profile in the Community has a Report option. We review reports within 24 hours. You can also email us.</p>

<h2>LEGAL NOTICE (IMPRESSUM)</h2>
<p>Angaben gemäß § 5 DDG</p>
<address>{{.Operator}}{{range .AddressLines}}<br>{{.}}{{end}}<br>E-mail: <a href="mailto:{{.Email}}">{{.Email}}</a></address>
{{end}}`

const deleteAccountContent = `{{define "content"}}
<h1>Delete your Lively account</h1>
<p class="lead">You can delete your account and its data at any time.</p>

<h2>IN THE APP</h2>
<p>Open Profile → Settings → Delete Account and confirm. Your account is deleted right away and you are signed out on every device.</p>

<h2>BY E-MAIL</h2>
<p>Can't open the app? Send a request to <a href="mailto:{{.Email}}?subject=Delete%20my%20account">{{.Email}}</a> from the e-mail address of your account. We confirm and delete the account within 30 days.</p>

<h2>WHAT IS DELETED</h2>
<ul>
<li>Your account, profile and birth data.</li>
<li>Your journal entries, AI chats, saved people, readings and compatibility reports.</li>
<li>Your community posts and comments.</li>
</ul>
<p>The data is removed from the app immediately and erased from our systems within 30 days. Records we must keep by law (for example payment records) are kept for the period the law requires.</p>

<h2>SUBSCRIPTIONS</h2>
<p>A subscription bought on our website is cancelled when you delete your account. App Store and Google Play subscriptions are not: cancel them in your store's subscription settings, or they keep renewing.</p>
{{end}}`

type legalBlock struct {
	Kind  string // h2 | p | ul
	Text  string
	Items []string
}

type legalPageData struct {
	Title, Description string
	Heading, Meta      string
	Blocks             []legalBlock
	Operator, Email    string
	AddressLines       []string
	CSS                template.CSS
	Year               int
}

var legalSectionHeading = regexp.MustCompile(`^\d+\.\s+[A-Z]`)

// legalDocument turns the plain legal text (title line, "Effective" line,
// numbered UPPERCASE section headings, "• " bullets with indented
// continuation lines, hard-wrapped paragraphs) into reflowable blocks.
func legalDocument(text string) (heading, meta string, blocks []legalBlock) {
	for i, chunk := range strings.Split(strings.ReplaceAll(text, "\r\n", "\n"), "\n\n") {
		lines := strings.Split(strings.Trim(chunk, "\n"), "\n")
		if i == 0 {
			heading = strings.TrimSpace(lines[0])
			meta = strings.TrimSpace(strings.Join(lines[1:], " "))
			continue
		}
		if legalSectionHeading.MatchString(lines[0]) {
			blocks = append(blocks, legalBlock{Kind: "h2", Text: strings.TrimSpace(lines[0])})
			lines = lines[1:]
		}
		var para, items []string
		flushPara := func() {
			if len(para) > 0 {
				blocks = append(blocks, legalBlock{Kind: "p", Text: strings.Join(para, " ")})
				para = nil
			}
		}
		flushList := func() {
			if len(items) > 0 {
				blocks = append(blocks, legalBlock{Kind: "ul", Items: items})
				items = nil
			}
		}
		for _, ln := range lines {
			switch {
			case strings.HasPrefix(ln, "• "):
				flushPara()
				items = append(items, strings.TrimSpace(strings.TrimPrefix(ln, "• ")))
			case strings.HasPrefix(ln, "  ") && len(items) > 0:
				items[len(items)-1] += " " + strings.TrimSpace(ln)
			case strings.TrimSpace(ln) == "":
			default:
				flushList()
				para = append(para, strings.TrimSpace(ln))
			}
		}
		flushPara()
		flushList()
	}
	return heading, meta, blocks
}

func mustLegalTemplate(content string) *template.Template {
	t := template.Must(template.New("layout").Parse(legalLayout))
	return template.Must(t.Parse(content))
}

var (
	legalDocTemplate    = mustLegalTemplate(legalDocContent)
	homeTemplate        = mustLegalTemplate(homeContent)
	supportTemplate     = mustLegalTemplate(supportContent)
	deleteAccountTmpl   = mustLegalTemplate(deleteAccountContent)
	legalAddressNewline = regexp.MustCompile(`\s*[\n,]\s*`)
)

func newLegalPageData(title, description string) legalPageData {
	var address []string
	if a := strings.TrimSpace(legalOperatorAddress); a != "" {
		address = legalAddressNewline.Split(a, -1)
	}
	return legalPageData{
		Title:        title,
		Description:  description,
		Operator:     legalOperator,
		Email:        legalContactEmail,
		AddressLines: address,
		CSS:          template.CSS(legalPageCSS),
		Year:         time.Now().Year(),
	}
}

func renderLegalPage(w http.ResponseWriter, t *template.Template, data legalPageData) {
	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		slog.Error("legal page render failed", "error", err)
		http.Error(w, "Something went wrong", http.StatusInternalServerError)
		return
	}
	h := w.Header()
	h.Set("Content-Type", "text/html; charset=utf-8")
	h.Set("Content-Security-Policy", legalPageCSP)
	h.Set("Cache-Control", "public, max-age=3600")
	_, _ = w.Write(buf.Bytes())
}

func legalDocPage(w http.ResponseWriter, title, description, text string) {
	data := newLegalPageData(title, description)
	data.Heading, data.Meta, data.Blocks = legalDocument(text)
	renderLegalPage(w, legalDocTemplate, data)
}

// HomePage — GET /.
func HomePage(w http.ResponseWriter, r *http.Request) {
	renderLegalPage(w, homeTemplate, newLegalPageData("Lively",
		"Lively: astrology and self-guidance app."))
}

// PrivacyPage — GET /privacy.
func PrivacyPage(w http.ResponseWriter, r *http.Request) {
	legalDocPage(w, "Privacy Policy · Lively", "How Lively handles your data.", privacyPolicyText)
}

// TermsPage — GET /terms.
func TermsPage(w http.ResponseWriter, r *http.Request) {
	legalDocPage(w, "Terms of Service · Lively", "The terms for using Lively.", termsOfServiceText)
}

// SupportPage — GET /support (contact, subscriptions, Impressum).
func SupportPage(w http.ResponseWriter, r *http.Request) {
	renderLegalPage(w, supportTemplate, newLegalPageData("Support · Lively",
		"Contact Lively support, manage subscriptions, delete your account."))
}

// DeleteAccountPage — GET /delete-account (Google Play's account-deletion
// URL: how to delete the account in the app or by e-mail, and what is
// deleted).
func DeleteAccountPage(w http.ResponseWriter, r *http.Request) {
	renderLegalPage(w, deleteAccountTmpl, newLegalPageData("Delete your account · Lively",
		"How to delete your Lively account and what happens to your data."))
}
