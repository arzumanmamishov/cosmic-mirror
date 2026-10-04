package mailer

import (
	"bytes"
	"context"
	"io"
	"mime"
	"mime/multipart"
	"net"
	"net/mail"
	"strconv"
	"strings"
	"testing"
	"time"
)

func TestBuildMIMEHeadersAndEncoding(t *testing.T) {
	subject := "Lively'ye hoş geldin — e-postanı doğrula: 123 456"
	html := "<p>" + strings.Repeat("ş", 1500) + "</p>" // one very long line
	raw := buildMIME(formatAddr("Lively Ğ", "no-reply@livelyapp.co"), "a@b.co", "no-reply@livelyapp.co",
		subject, "Kodun: 123456", html, nil, messageID("no-reply@livelyapp.co"))

	for _, line := range strings.Split(string(raw), "\r\n") {
		if len(line) > 998 {
			t.Fatalf("line exceeds 998 octets: %d", len(line))
		}
	}
	msg, err := mail.ReadMessage(bytes.NewReader(raw))
	if err != nil {
		t.Fatal(err)
	}
	dec := new(mime.WordDecoder)
	got, err := dec.DecodeHeader(msg.Header.Get("Subject"))
	if err != nil || got != subject {
		t.Fatalf("subject round-trip: %q, %v", got, err)
	}
	if strings.ContainsAny(msg.Header.Get("Subject"), "şğı—") {
		t.Fatal("subject header contains raw non-ASCII")
	}
	if id := msg.Header.Get("Message-ID"); !strings.HasPrefix(id, "<") || !strings.HasSuffix(id, "@livelyapp.co>") {
		t.Fatalf("bad Message-ID %q", id)
	}
	if _, err := msg.Header.Date(); err != nil {
		t.Fatalf("bad Date: %v", err)
	}
	from, err := mail.ParseAddress(msg.Header.Get("From"))
	if err != nil || from.Name != "Lively Ğ" {
		t.Fatalf("from round-trip: %+v %v", from, err)
	}

	_, params, err := mime.ParseMediaType(msg.Header.Get("Content-Type"))
	if err != nil {
		t.Fatal(err)
	}
	mr := multipart.NewReader(msg.Body, params["boundary"])
	var parts []string
	for {
		p, err := mr.NextPart() // decodes quoted-printable transparently
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		b, _ := io.ReadAll(p)
		parts = append(parts, string(b))
	}
	if len(parts) != 2 || parts[0] != "Kodun: 123456" || parts[1] != html {
		t.Fatalf("body parts did not round-trip: %d parts", len(parts))
	}
}

func TestSendTimesOutOnHungServer(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			defer c.Close() // accept, then never send a greeting
		}
	}()
	_, portStr, _ := net.SplitHostPort(ln.Addr().String())
	port, _ := strconv.Atoi(portStr)
	m := &smtpMailer{cfg: Config{Host: "127.0.0.1", Port: port, FromEmail: "x@y.co"}}

	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	start := time.Now()
	if err := m.send(ctx, nil, []string{"a@b.co"}, []byte("x")); err == nil {
		t.Fatal("expected an error from a hung server")
	}
	if time.Since(start) > 3*time.Second {
		t.Fatalf("send did not honour the deadline: %v", time.Since(start))
	}
}
