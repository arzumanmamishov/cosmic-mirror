// Package otp holds the OTP purpose type + the email template + the DB
// repository. The higher-level "issue + verify" service lives in
// internal/service/otp_service.go so it can compose with the auth service.
package otp

// Purpose is what an OTP code is issued for. Matches the otp_purpose enum
// in migration 010. The verifier MUST reject a code whose purpose doesn't
// match the endpoint the client called — a code minted for "password_reset"
// should not unlock login.
type Purpose string

const (
	PurposeRegister      Purpose = "register"
	PurposeLogin         Purpose = "login"
	PurposePasswordReset Purpose = "password_reset"
)

// Valid reports whether p is one of the allowed enum values.
func (p Purpose) Valid() bool {
	switch p {
	case PurposeRegister, PurposeLogin, PurposePasswordReset:
		return true
	}
	return false
}
