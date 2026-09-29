package domain

import (
	"errors"
	"fmt"
	"net/url"
	"strings"
	"unicode/utf8"
)

// ErrInvalidInput wraps every community input-validation failure so
// handlers can map it to 400.
var ErrInvalidInput = errors.New("invalid input")

// Length caps for user-generated community content. Unbounded text lets a
// single client fill the database and bloat every feed response.
const (
	MaxPostRunes       = 5000
	MaxCommentRunes    = 2000
	MaxSpaceNameRunes  = 80
	MaxSpaceDescRunes  = 500
	MaxURLLength       = 2048
	MaxHashtagsPerPost = 20
)

func tooLong(field string, max int) error {
	return fmt.Errorf("%w: %s must be at most %d characters", ErrInvalidInput, field, max)
}

func checkRunes(field, s string, max int) error {
	if utf8.RuneCountInString(s) > max {
		return tooLong(field, max)
	}
	return nil
}

// ValidateHTTPSURL accepts only absolute https:// URLs (no javascript:,
// data:, or plain-http links rendered to other users).
func ValidateHTTPSURL(field string, raw *string) error {
	if raw == nil || strings.TrimSpace(*raw) == "" {
		return nil
	}
	if len(*raw) > MaxURLLength {
		return tooLong(field, MaxURLLength)
	}
	u, err := url.Parse(strings.TrimSpace(*raw))
	if err != nil || u.Scheme != "https" || u.Host == "" {
		return fmt.Errorf("%w: %s must be an https:// URL", ErrInvalidInput, field)
	}
	return nil
}

func (in CreatePostInput) Validate() error {
	if err := checkRunes("content", in.Content, MaxPostRunes); err != nil {
		return err
	}
	return ValidateHTTPSURL("link_url", in.LinkURL)
}

func (in UpdatePostInput) Validate() error {
	if in.Content != nil {
		if err := checkRunes("content", *in.Content, MaxPostRunes); err != nil {
			return err
		}
	}
	return ValidateHTTPSURL("link_url", in.LinkURL)
}

func (in CreateCommentInput) Validate() error {
	return checkRunes("content", in.Content, MaxCommentRunes)
}

func (in UpdateCommentInput) Validate() error {
	if in.Content == nil {
		return nil
	}
	return checkRunes("content", *in.Content, MaxCommentRunes)
}

func (in CreateSpaceInput) Validate() error {
	if err := checkRunes("name", in.Name, MaxSpaceNameRunes); err != nil {
		return err
	}
	if in.Description != nil {
		if err := checkRunes("description", *in.Description, MaxSpaceDescRunes); err != nil {
			return err
		}
	}
	return ValidateHTTPSURL("avatar_url", in.AvatarURL)
}

func (in UpdateSpaceInput) Validate() error {
	if in.Name != nil {
		if err := checkRunes("name", *in.Name, MaxSpaceNameRunes); err != nil {
			return err
		}
	}
	if in.Description != nil {
		if err := checkRunes("description", *in.Description, MaxSpaceDescRunes); err != nil {
			return err
		}
	}
	return ValidateHTTPSURL("avatar_url", in.AvatarURL)
}
