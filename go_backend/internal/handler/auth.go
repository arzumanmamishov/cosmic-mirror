package handler

import (
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type AuthHandler struct {
	userSvc *service.UserService
	subSvc  *service.SubscriptionService
}

func NewAuthHandler(userSvc *service.UserService, subSvc *service.SubscriptionService) *AuthHandler {
	return &AuthHandler{userSvc: userSvc, subSvc: subSvc}
}

func (h *AuthHandler) CreateSession(w http.ResponseWriter, r *http.Request) {
	var input struct {
		FirebaseUID string `json:"firebase_uid"`
		Email       string `json:"email"`
		Name        string `json:"name"`
	}
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}

	user, err := h.userSvc.CreateOrGetUser(r.Context(), input.FirebaseUID, input.Email, input.Name)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "session_error", err.Error())
		return
	}

	hasOnboarding := h.userSvc.HasCompletedOnboarding(r.Context(), user.ID)

	response := map[string]any{
		"user": map[string]any{
			"id":                       user.ID,
			"email":                    user.Email,
			"name":                     user.Name,
			"has_completed_onboarding": hasOnboarding,
		},
	}

	respondSuccess(w, response)
}

func (h *AuthHandler) PrivacyPolicy(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]string{
		"content": privacyPolicyText,
		"version": "1.0",
	})
}

func (h *AuthHandler) TermsOfService(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]string{
		"content": termsOfServiceText,
		"version": "1.0",
	})
}

// Minimal placeholders - replace with real legal text
var _ = middleware.UserIDFromContext

const privacyPolicyText = `Privacy Policy for Lively

Last updated: 2024-01-01

Lively ("we", "our", "us") respects your privacy. This policy explains how we collect, use, and protect your personal data.

Data We Collect:
- Account information (email, name)
- Birth data (date, time, location) for astrological calculations
- App usage data and preferences
- Journal entries and chat messages
- Subscription and payment status (via RevenueCat)

How We Use Your Data:
- Generate personalized astrological readings and insights
- Provide AI-powered chat experiences
- Process subscriptions and in-app purchases
- Send push notifications (with your permission)
- Improve our services and user experience

Data Protection:
- Birth data is encrypted at rest
- We do not sell personal data to third parties
- AI conversations are processed through OpenAI with data handling agreements
- You can request complete data deletion at any time

Your Rights:
- Access your personal data
- Request correction or deletion
- Export your data
- Withdraw consent for data processing

Contact: privacy@livelyapp.co`

const termsOfServiceText = `Terms of Service for Lively

Last updated: 2024-01-01

By using Lively, you agree to these terms.

Service Description:
Lively provides entertainment and self-reflection through astrology-based content and AI-powered guidance. Our content is for informational and entertainment purposes only.

Disclaimer:
Astrological readings and AI-generated content are not substitutes for professional medical, financial, legal, or psychological advice. Always consult qualified professionals for important life decisions.

Subscriptions:
- Premium features require a paid subscription
- Subscriptions auto-renew unless cancelled
- Cancel anytime through your app store account
- No refunds for partial subscription periods

User Conduct:
- You must be 13 or older to use this app
- Do not misuse the AI chat feature
- Do not attempt to manipulate or abuse the service

Intellectual Property:
All content, design, and code are owned by Lively.

Contact: legal@livelyapp.co`
