package otp

import (
	"fmt"
	"strings"
)

// emailCopy is every user-visible string in the OTP email for one language.
type emailCopy struct {
	headlines map[Purpose]string
	leads     map[Purpose]string
	fallbackHeadline,
	fallbackLead,
	codeLabel,
	expiry,
	ignore,
	footer string
}

var emailCopies = map[string]emailCopy{
	"en": {
		headlines: map[Purpose]string{
			PurposeRegister:      "Welcome to Lively — confirm your email",
			PurposeLogin:         "Sign-in code",
			PurposePasswordReset: "Reset your password",
		},
		leads: map[Purpose]string{
			PurposeRegister:      "Use this code to finish creating your Lively account.",
			PurposeLogin:         "Use this code to finish signing in to Lively.",
			PurposePasswordReset: "Use this code to choose a new password for your Lively account.",
		},
		fallbackHeadline: "Your verification code",
		fallbackLead:     "Use this code to continue.",
		codeLabel:        "Your code: ",
		expiry:           "This code expires in 10 minutes and can only be used once.",
		ignore:           "If you didn't ask for this, you can safely ignore the email — no action is needed.",
		footer:           "Sent by Lively · This is an automated message.",
	},
	// Informal "sen" register and a warm tone, matching the app's Turkish UI.
	"tr": {
		headlines: map[Purpose]string{
			PurposeRegister:      "Lively'ye hoş geldin — e-postanı doğrula",
			PurposeLogin:         "Giriş kodun",
			PurposePasswordReset: "Şifreni sıfırla",
		},
		leads: map[Purpose]string{
			PurposeRegister:      "Lively hesabını oluşturmayı tamamlamak için bu kodu kullan.",
			PurposeLogin:         "Lively'ye girişini tamamlamak için bu kodu kullan.",
			PurposePasswordReset: "Lively hesabın için yeni bir şifre belirlemek üzere bu kodu kullan.",
		},
		fallbackHeadline: "Doğrulama kodun",
		fallbackLead:     "Devam etmek için bu kodu kullan.",
		codeLabel:        "Kodun: ",
		expiry:           "Bu kod 10 dakika geçerli ve yalnızca bir kez kullanılabilir.",
		ignore:           "Bu isteği sen yapmadıysan bu e-postayı görmezden gelebilirsin — başka bir şey yapmana gerek yok.",
		footer:           "Lively tarafından gönderildi · Bu otomatik bir mesajdır.",
	},
}

// RenderEmail returns (subject, textBody, htmlBody) for a given purpose +
// 6-digit code in [lang] ("en" or "tr"; anything else falls back to
// English). Two parts so clients that strip HTML still get a usable
// message. Copy is short, warm, and tuned for the Lively app.
func RenderEmail(p Purpose, code, lang string) (subject, text, html string) {
	c, ok := emailCopies[lang]
	if !ok {
		lang = "en"
		c = emailCopies[lang]
	}
	headline, ok := c.headlines[p]
	if !ok {
		headline = c.fallbackHeadline
	}
	lead, ok := c.leads[p]
	if !ok {
		lead = c.fallbackLead
	}
	subject = fmt.Sprintf("%s: %s", headline, spacedCode(code))

	text = strings.Join([]string{
		headline,
		"",
		lead,
		"",
		c.codeLabel + code,
		"",
		c.expiry,
		c.ignore,
		"",
		"— Lively",
	}, "\n")

	html = strings.Join([]string{
		fmt.Sprintf(`<!doctype html><html lang="%s"><head><meta charset="utf-8"></head><body style="margin:0;padding:0;background:#0A0E27;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#EDECFF;">`, lang),
		`<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:32px 0;"><tr><td align="center">`,
		`<table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background:#141838;border-radius:18px;box-shadow:0 12px 32px rgba(0,0,0,0.4);overflow:hidden;">`,
		`<tr><td style="background:linear-gradient(135deg,#7B61FF,#F07C82);padding:26px 28px 22px 28px;color:#fff;">`,
		`<div style="font-size:13px;font-weight:700;letter-spacing:1.6px;text-transform:uppercase;opacity:0.9;">Lively</div>`,
		fmt.Sprintf(`<div style="font-size:22px;font-weight:800;letter-spacing:-0.3px;margin-top:6px;">%s</div>`, headline),
		`</td></tr>`,
		`<tr><td style="padding:26px 28px 8px 28px;">`,
		fmt.Sprintf(`<p style="margin:0 0 18px 0;font-size:14px;line-height:1.55;color:#B5AECC;">%s</p>`, lead),
		fmt.Sprintf(`<div style="margin:8px auto 22px auto;padding:18px 22px;background:#1E2447;border:1px solid rgba(123,97,255,0.35);border-radius:14px;text-align:center;font-family:Menlo,Consolas,monospace;font-size:32px;font-weight:800;letter-spacing:10px;color:#B497FF;">%s</div>`, code),
		fmt.Sprintf(`<p style="margin:0 0 8px 0;font-size:12.5px;line-height:1.55;color:#8E86AA;">%s</p>`, c.expiry),
		fmt.Sprintf(`<p style="margin:0 0 18px 0;font-size:12.5px;line-height:1.55;color:#8E86AA;">%s</p>`, c.ignore),
		`</td></tr>`,
		`<tr><td style="padding:16px 28px 22px 28px;border-top:1px solid rgba(255,255,255,0.06);font-size:11.5px;color:#8E86AA;">`,
		c.footer,
		`</td></tr>`,
		`</table></td></tr></table></body></html>`,
	}, "")
	return
}

// spacedCode renders "123456" as "123 456" for the subject preview line —
// much easier to scan in the notification tray.
func spacedCode(s string) string {
	if len(s) != 6 {
		return s
	}
	return s[:3] + " " + s[3:]
}
