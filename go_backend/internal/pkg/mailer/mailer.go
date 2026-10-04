// Package mailer is the backend's outbound-email surface. Every module
// that needs to send mail (auth OTP, email verification, password
// reset, …) talks to this small interface instead of reaching for
// SMTP / SendGrid / SES directly.
//
// The SMTP implementation uses the stdlib net/smtp client (no extra
// dep). It speaks STARTTLS when the operator sets SMTP_USE_TLS=true,
// or implicit TLS for port 465. Port 587 with STARTTLS is the default
// path matching what most consumer SMTP relays (Gmail, Postmark,
// SendGrid SMTP, your own postfix) expect.
//
// When SMTPHost is empty, New() returns a Noop mailer that only logs
// the message body — dev machines see the OTP code in the API logs
// without needing a real SMTP account.
package mailer

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"mime"
	"mime/quotedprintable"
	"net"
	"net/mail"
	"net/smtp"
	"strconv"
	"strings"
	"time"
)

// Message is a single outbound email. Either TextBody, HTMLBody, or
// both must be non-empty. When both are present we send a
// multipart/alternative body so clients pick the right one.
type Message struct {
	To       string
	Subject  string
	TextBody string
	HTMLBody string
	// ReplyTo is optional. When empty the From address is reused.
	ReplyTo string
	// Inlines are images embedded in the message and referenced from the
	// HTML body via `<img src="cid:CID">`. They render in Gmail/Outlook
	// without a public URL (sent as a multipart/related body).
	Inlines []InlineImage
}

// InlineImage is a CID-referenced inline image (e.g. a brand logo).
type InlineImage struct {
	CID      string // matches the cid: reference in the HTML (no angle brackets)
	MIMEType string // e.g. "image/png"
	Data     []byte
}

// Mailer is the interface every caller depends on.
type Mailer interface {
	Send(ctx context.Context, m Message) error
}

// Config is the SMTP transport config. When Host is empty New() returns
// a Noop mailer that only logs — handy for unit tests and for local
// dev before the operator wires up a real SMTP relay.
type Config struct {
	Host      string
	Port      int
	Username  string
	Password  string
	FromEmail string
	FromName  string
	// UseTLS toggles STARTTLS on the connection (port 587 default).
	// Port 465 implies implicit TLS regardless of this flag.
	UseTLS bool
}

// New returns the right Mailer for the supplied config. Empty Host
// → noopMailer (dev). Otherwise an smtpMailer.
func New(cfg Config) Mailer {
	if strings.TrimSpace(cfg.Host) == "" {
		slog.Warn("SMTP_HOST empty — email delivery disabled; OTP codes only visible in logs")
		return &noopMailer{}
	}
	if cfg.Port == 0 {
		cfg.Port = 587
	}
	if cfg.FromEmail == "" {
		cfg.FromEmail = "no-reply@livelyapp.co"
	}
	if cfg.FromName == "" {
		cfg.FromName = "Lively"
	}
	return &smtpMailer{cfg: cfg}
}

// ----------------------------------------------------------------------------
// smtpMailer — stdlib net/smtp implementation.
// ----------------------------------------------------------------------------

type smtpMailer struct {
	cfg Config
}

func (s *smtpMailer) Send(ctx context.Context, m Message) error {
	if strings.TrimSpace(m.To) == "" {
		return errors.New("mailer: empty recipient")
	}
	if m.TextBody == "" && m.HTMLBody == "" {
		return errors.New("mailer: empty body")
	}

	from := formatAddr(s.cfg.FromName, s.cfg.FromEmail)
	replyTo := m.ReplyTo
	if replyTo == "" {
		replyTo = s.cfg.FromEmail
	}

	body := buildMIME(from, m.To, replyTo, m.Subject, m.TextBody, m.HTMLBody, m.Inlines, messageID(s.cfg.FromEmail))

	// net/smtp wants Auth nil-able. Empty username = anonymous relay.
	var auth smtp.Auth
	if s.cfg.Username != "" {
		auth = smtp.PlainAuth("", s.cfg.Username, s.cfg.Password, s.cfg.Host)
	}

	// Run the actual send on a goroutine so ctx cancellation aborts
	// promptly even if the SMTP server is hung. The connection also gets
	// its own dial timeout + overall deadline, so a hung server can't
	// leak the goroutine and its socket forever after ctx gives up.
	done := make(chan error, 1)
	go func() {
		done <- s.send(ctx, auth, []string{m.To}, body)
	}()

	select {
	case <-ctx.Done():
		return ctx.Err()
	case err := <-done:
		if err != nil {
			// Never log the subject/body — OTP codes live there.
			slog.Error("smtp send failed",
				"error", err,
				"to", m.To,
			)
			return fmt.Errorf("mailer: smtp send: %w", err)
		}
		slog.Info("email sent", "to", m.To)
		return nil
	}
}

const (
	// smtpDialTimeout bounds the TCP (+TLS for port 465) connect.
	smtpDialTimeout = 10 * time.Second
	// smtpSessionTimeout bounds the whole SMTP conversation once connected.
	smtpSessionTimeout = 30 * time.Second
)

// send dials the relay and runs one SMTP transaction:
//   - port 465: implicit TLS from the first byte;
//   - UseTLS: plain connect, then mandatory STARTTLS;
//   - otherwise: STARTTLS when the server offers it (what smtp.SendMail
//     does), plain text only if it doesn't.
func (s *smtpMailer) send(ctx context.Context, auth smtp.Auth, to []string, body []byte) error {
	addr := net.JoinHostPort(s.cfg.Host, strconv.Itoa(s.cfg.Port))
	tlsCfg := &tls.Config{ServerName: s.cfg.Host, MinVersion: tls.VersionTLS12}
	dialer := &net.Dialer{Timeout: smtpDialTimeout}

	var conn net.Conn
	var err error
	if s.cfg.Port == 465 {
		conn, err = (&tls.Dialer{NetDialer: dialer, Config: tlsCfg}).DialContext(ctx, "tcp", addr)
		if err != nil {
			return fmt.Errorf("tls dial: %w", err)
		}
	} else {
		conn, err = dialer.DialContext(ctx, "tcp", addr)
		if err != nil {
			return fmt.Errorf("smtp dial: %w", err)
		}
	}
	defer conn.Close()

	deadline := time.Now().Add(smtpSessionTimeout)
	if d, ok := ctx.Deadline(); ok && d.Before(deadline) {
		deadline = d
	}
	if err := conn.SetDeadline(deadline); err != nil {
		return fmt.Errorf("smtp deadline: %w", err)
	}

	c, err := smtp.NewClient(conn, s.cfg.Host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer c.Close()

	if s.cfg.Port != 465 {
		hasStartTLS, _ := c.Extension("STARTTLS")
		if s.cfg.UseTLS || hasStartTLS {
			if err := c.StartTLS(tlsCfg); err != nil {
				return fmt.Errorf("starttls: %w", err)
			}
		}
	}
	return runSMTP(c, auth, s.cfg.FromEmail, to, body)
}

func runSMTP(c *smtp.Client, auth smtp.Auth, from string, to []string, body []byte) error {
	if auth != nil {
		if err := c.Auth(auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}
	if err := c.Mail(from); err != nil {
		return fmt.Errorf("smtp mail: %w", err)
	}
	for _, r := range to {
		if err := c.Rcpt(r); err != nil {
			return fmt.Errorf("smtp rcpt: %w", err)
		}
	}
	w, err := c.Data()
	if err != nil {
		return fmt.Errorf("smtp data: %w", err)
	}
	if _, err := w.Write(body); err != nil {
		return fmt.Errorf("smtp write: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("smtp close: %w", err)
	}
	return c.Quit()
}

// ----------------------------------------------------------------------------
// noopMailer — silently consumes messages and logs them for local dev.
// ----------------------------------------------------------------------------

type noopMailer struct{}

func (n *noopMailer) Send(_ context.Context, m Message) error {
	slog.Info("email NOT SENT (SMTP disabled) — copy code from log body",
		"to", m.To,
		"subject", m.Subject,
		"body_preview", preview(m.TextBody, 400),
	)
	return nil
}

func preview(s string, n int) string {
	s = strings.ReplaceAll(s, "\n", " ")
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

// ----------------------------------------------------------------------------
// MIME builder — RFC 5322 + multipart/alternative when both parts exist.
// ----------------------------------------------------------------------------

// formatAddr renders an RFC 5322 address; a non-ASCII display name is
// RFC 2047-encoded, an ASCII one quoted when needed.
func formatAddr(name, email string) string {
	if name == "" {
		return email
	}
	return (&mail.Address{Name: name, Address: email}).String()
}

// messageID returns a unique RFC 5322 Message-ID on the sender's domain.
// Some spam filters penalise mail that arrives without one.
func messageID(fromEmail string) string {
	domain := "localhost"
	if at := strings.LastIndexByte(fromEmail, '@'); at >= 0 && at < len(fromEmail)-1 {
		domain = fromEmail[at+1:]
	}
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return fmt.Sprintf("<%d@%s>", time.Now().UnixNano(), domain)
	}
	return fmt.Sprintf("<%s.%d@%s>", hex.EncodeToString(b[:]), time.Now().Unix(), domain)
}

func buildMIME(from, to, replyTo, subject, text, html string, inlines []InlineImage, msgID string) []byte {
	var b strings.Builder
	b.WriteString("From: ")
	b.WriteString(from)
	b.WriteString("\r\n")
	b.WriteString("To: ")
	b.WriteString(to)
	b.WriteString("\r\n")
	if replyTo != "" {
		b.WriteString("Reply-To: ")
		b.WriteString(replyTo)
		b.WriteString("\r\n")
	}
	// Non-ASCII subjects (the OTP subject has an em dash; Turkish copy has
	// ş/ğ/ı…) must be RFC 2047-encoded; Q-encoding is a no-op for ASCII.
	b.WriteString("Subject: ")
	b.WriteString(mime.QEncoding.Encode("utf-8", subject))
	b.WriteString("\r\n")
	b.WriteString("Date: ")
	b.WriteString(time.Now().UTC().Format(time.RFC1123Z))
	b.WriteString("\r\n")
	if msgID != "" {
		b.WriteString("Message-ID: ")
		b.WriteString(msgID)
		b.WriteString("\r\n")
	}
	b.WriteString("MIME-Version: 1.0\r\n")

	// With inline images, wrap the text/html body in multipart/related so the
	// HTML can reference each image by `cid:` and clients render it inline
	// (no public URL needed).
	if len(inlines) > 0 {
		rel := fmt.Sprintf("=_rel_%d", time.Now().UnixNano())
		b.WriteString("Content-Type: multipart/related; boundary=\"")
		b.WriteString(rel)
		b.WriteString("\"\r\n\r\n")
		b.WriteString("--")
		b.WriteString(rel)
		b.WriteString("\r\n")
		writeBodyPart(&b, text, html)
		for _, im := range inlines {
			b.WriteString("\r\n--")
			b.WriteString(rel)
			b.WriteString("\r\nContent-Type: ")
			b.WriteString(im.MIMEType)
			b.WriteString("\r\nContent-Transfer-Encoding: base64\r\nContent-ID: <")
			b.WriteString(im.CID)
			b.WriteString(">\r\nContent-Disposition: inline; filename=\"")
			b.WriteString(im.CID)
			b.WriteString("\"\r\n\r\n")
			b.WriteString(chunkBase64(im.Data))
		}
		b.WriteString("\r\n--")
		b.WriteString(rel)
		b.WriteString("--\r\n")
		return []byte(b.String())
	}

	writeBodyPart(&b, text, html)
	return []byte(b.String())
}

// writeBodyPart appends the Content-Type header + body: multipart/alternative
// when both text and HTML are present, else a single part. Used both
// standalone and as the first part inside multipart/related.
func writeBodyPart(b *strings.Builder, text, html string) {
	hasText := strings.TrimSpace(text) != ""
	hasHTML := strings.TrimSpace(html) != ""
	switch {
	case hasText && hasHTML:
		boundary := fmt.Sprintf("=_alt_%d", time.Now().UnixNano())
		b.WriteString("Content-Type: multipart/alternative; boundary=\"")
		b.WriteString(boundary)
		b.WriteString("\"\r\n\r\n")
		b.WriteString("--")
		b.WriteString(boundary)
		b.WriteString("\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n")
		b.WriteString(qp(text))
		b.WriteString("\r\n--")
		b.WriteString(boundary)
		b.WriteString("\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n")
		b.WriteString(qp(html))
		b.WriteString("\r\n--")
		b.WriteString(boundary)
		b.WriteString("--\r\n")
	case hasHTML:
		b.WriteString("Content-Type: text/html; charset=UTF-8\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n")
		b.WriteString(qp(html))
	default:
		b.WriteString("Content-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n")
		b.WriteString(qp(text))
	}
}

// qp quoted-printable-encodes a body part. Unlike raw 8bit it keeps every
// line under SMTP's 998-octet limit (the HTML template is one long line)
// and survives relays that aren't 8BITMIME-clean.
func qp(s string) string {
	var buf bytes.Buffer
	w := quotedprintable.NewWriter(&buf)
	_, _ = w.Write([]byte(strings.ReplaceAll(s, "\r\n", "\n")))
	_ = w.Close()
	return buf.String()
}

// chunkBase64 base64-encodes data, wrapped at 76 chars per line (RFC 2045).
func chunkBase64(data []byte) string {
	enc := base64.StdEncoding.EncodeToString(data)
	var b strings.Builder
	for i := 0; i < len(enc); i += 76 {
		end := i + 76
		if end > len(enc) {
			end = len(enc)
		}
		b.WriteString(enc[i:end])
		b.WriteString("\r\n")
	}
	return b.String()
}
