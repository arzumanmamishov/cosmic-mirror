package otp

import (
	"fmt"
	"strings"
)

// RenderEmail returns (subject, textBody, htmlBody) for a given purpose +
// 6-digit code. Two parts so clients that strip HTML still get a usable
// message. Copy is short, warm, and tuned for the Lively app.
func RenderEmail(p Purpose, code string) (subject, text, html string) {
	var headline, lead string
	switch p {
	case PurposeRegister:
		headline = "Welcome to Lively — confirm your email"
		lead = "Use this code to finish creating your Lively account."
	case PurposeLogin:
		headline = "Sign-in code"
		lead = "Use this code to finish signing in to Lively."
	case PurposePasswordReset:
		headline = "Reset your password"
		lead = "Use this code to choose a new password for your Lively account."
	default:
		headline = "Your verification code"
		lead = "Use this code to continue."
	}
	subject = fmt.Sprintf("%s: %s", headline, spacedCode(code))

	text = strings.Join([]string{
		headline,
		"",
		lead,
		"",
		"Your code: " + code,
		"",
		"This code expires in 10 minutes and can only be used once.",
		"If you didn't ask for this, you can safely ignore the email — no action is needed.",
		"",
		"— Lively",
	}, "\n")

	html = strings.Join([]string{
		`<!doctype html><html><body style="margin:0;padding:0;background:#0A0E27;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#EDECFF;">`,
		`<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:32px 0;"><tr><td align="center">`,
		`<table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background:#141838;border-radius:18px;box-shadow:0 12px 32px rgba(0,0,0,0.4);overflow:hidden;">`,
		`<tr><td style="background:linear-gradient(135deg,#7B61FF,#F07C82);padding:26px 28px 22px 28px;color:#fff;">`,
		`<div style="font-size:13px;font-weight:700;letter-spacing:1.6px;text-transform:uppercase;opacity:0.9;">Lively</div>`,
		fmt.Sprintf(`<div style="font-size:22px;font-weight:800;letter-spacing:-0.3px;margin-top:6px;">%s</div>`, headline),
		`</td></tr>`,
		`<tr><td style="padding:26px 28px 8px 28px;">`,
		fmt.Sprintf(`<p style="margin:0 0 18px 0;font-size:14px;line-height:1.55;color:#B5AECC;">%s</p>`, lead),
		fmt.Sprintf(`<div style="margin:8px auto 22px auto;padding:18px 22px;background:#1E2447;border:1px solid rgba(123,97,255,0.35);border-radius:14px;text-align:center;font-family:Menlo,Consolas,monospace;font-size:32px;font-weight:800;letter-spacing:10px;color:#B497FF;">%s</div>`, code),
		`<p style="margin:0 0 8px 0;font-size:12.5px;line-height:1.55;color:#8E86AA;">This code expires in 10 minutes and can only be used once.</p>`,
		`<p style="margin:0 0 18px 0;font-size:12.5px;line-height:1.55;color:#8E86AA;">If you didn't ask for this, you can safely ignore the email — no action is needed.</p>`,
		`</td></tr>`,
		`<tr><td style="padding:16px 28px 22px 28px;border-top:1px solid rgba(255,255,255,0.06);font-size:11.5px;color:#8E86AA;">`,
		`Sent by Lively · This is an automated message.`,
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
