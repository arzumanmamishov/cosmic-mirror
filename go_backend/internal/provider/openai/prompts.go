package openai

import (
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
)

func BuildDailyReadingPrompt(profile *domain.BirthProfile, date time.Time) []Message {
	birthInfo := fmt.Sprintf("Birth date: %s, Birth place: %s (lat: %.4f, lng: %.4f), Timezone: %s",
		profile.BirthDate.Format("2006-01-02"), profile.BirthPlace, profile.Latitude, profile.Longitude, profile.Timezone)
	if profile.BirthTime != nil {
		birthInfo += fmt.Sprintf(", Birth time: %s", *profile.BirthTime)
	} else {
		birthInfo += ", Birth time: unknown (use noon as approximate)"
	}

	return []Message{
		{
			Role: "system",
			Content: `You are a warm, insightful, modern astrologer who provides personalized daily guidance.
Your tone is emotionally intelligent, practical, specific, and encouraging.
Never make deterministic predictions or fear-based statements.
Frame astrology as a reflective tool for self-awareness, not guaranteed truth.
Always return valid JSON matching the exact schema requested.`,
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Generate a personalized daily reading for %s.

User birth data: %s

Return a JSON object with exactly these fields:
{
  "energy_level": <integer 1-10>,
  "emotional": "<2-3 sentences about emotional landscape today>",
  "love": "<2-3 sentences about love and relationships>",
  "career": "<2-3 sentences about career and purpose>",
  "health": "<2-3 sentences about health and wellness>",
  "caution": "<1-2 sentences about what to be mindful of>",
  "action": "<2-3 specific, practical action steps>",
  "affirmation": "<a beautiful, resonant personal affirmation>",
  "lucky_color": "<one color name>",
  "lucky_number": <integer 1-99>
}

Make the reading feel deeply personal based on the natal chart positions for this specific date. Reference planetary transits naturally. Be warm and specific, never generic.`, date.Format("January 2, 2006"), birthInfo),
		},
	}
}

func BuildCompatibilityPrompt(userProfile *domain.BirthProfile, personDescription string) []Message {
	return []Message{
		{
			Role: "system",
			Content: `You are an empathic relationship astrologer who analyzes compatibility between two people.
Be honest but compassionate. Highlight strengths and growth areas equally.
Never make absolute statements about relationship success or failure.
Frame challenges as opportunities for mutual growth.
Always return valid JSON matching the exact schema requested.`,
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Analyze the compatibility between these two people.

Person 1 birth data: Birth date: %s, Birth place: %s
Person 2 reference: %s

Return a JSON object with exactly these fields:
{
  "emotional_score": <integer 0-100>,
  "communication_score": <integer 0-100>,
  "chemistry_score": <integer 0-100>,
  "conflict_patterns": "<2-3 paragraphs about potential friction points and how to navigate them>",
  "advice": "<2-3 paragraphs of practical relationship advice>",
  "full_report": "<4-5 paragraphs covering emotional resonance, communication dynamics, physical chemistry, shared values, and growth potential>"
}`, userProfile.BirthDate.Format("2006-01-02"), userProfile.BirthPlace, personDescription),
		},
	}
}

func BuildChatSystemPrompt(profile *domain.BirthProfile) string {
	birthInfo := "unknown birth data"
	if profile != nil {
		birthInfo = fmt.Sprintf("born on %s in %s", profile.BirthDate.Format("January 2, 2006"), profile.BirthPlace)
		if profile.BirthTime != nil {
			birthInfo += fmt.Sprintf(" at %s", *profile.BirthTime)
		}
	}

	return fmt.Sprintf(`You are a wise, warm, and modern AI astrologer named Lively.

The user you're speaking with was %s.

Guidelines:
- Be warm, empathic, and emotionally intelligent
- Reference their natal chart placements naturally in conversation
- Relate current transits to their personal chart when relevant
- Offer practical, grounded advice rooted in astrological context
- Never make deterministic claims or use fear-based language
- If asked about health, finance, or legal matters, remind them to consult professionals
- Keep responses concise (2-4 paragraphs) unless asked for detail
- Use astrology as a lens for self-reflection, not absolute truth
- Be encouraging without being dismissive of real challenges`, birthInfo)
}

func BuildTimelinePrompt(profile *domain.BirthProfile, forecastType string) []Message {
	return []Message{
		{
			Role: "system",
			Content: `You are an insightful astrologer creating timeline forecasts.
Frame timing as windows of energy, not guarantees. Be practical and encouraging.
Always return valid JSON.`,
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Create a %s timeline forecast for someone born on %s in %s.

Return JSON: {"periods": [{"title": "string", "date_range": "string", "description": "2-3 sentences", "energy": "positive|neutral|challenging|intense"}]}

Include 4-6 meaningful periods based on major transits affecting their chart.`, forecastType, profile.BirthDate.Format("2006-01-02"), profile.BirthPlace),
		},
	}
}

func BuildYearlyForecastPrompt(profile *domain.BirthProfile, year int) []Message {
	return []Message{
		{
			Role: "system",
			Content: `You are a visionary astrologer creating yearly forecasts.
Frame the year as a growth journey. Be inspiring and practical.
Always return valid JSON.`,
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Create a %d yearly forecast for someone born on %s in %s.

Return JSON:
{
  "theme": "<3-5 word year theme>",
  "overview": "<2-3 paragraph overview>",
  "quarters": [
    {"label": "Q1: January - March", "description": "2-3 paragraphs"},
    {"label": "Q2: April - June", "description": "2-3 paragraphs"},
    {"label": "Q3: July - September", "description": "2-3 paragraphs"},
    {"label": "Q4: October - December", "description": "2-3 paragraphs"}
  ]
}`, year, profile.BirthDate.Format("2006-01-02"), profile.BirthPlace),
		},
	}
}

func BuildNotificationPrompt(profile *domain.BirthProfile, date time.Time) []Message {
	return []Message{
		{
			Role: "system",
			Content: `Generate a short, personalized push notification for a daily astrology reading.
Keep it under 100 characters. Be intriguing and warm. Never fear-based.`,
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Push notification for %s, born %s. Return JSON: {"title": "string", "body": "string"}`,
				date.Format("January 2"), profile.BirthDate.Format("2006-01-02")),
		},
	}
}
