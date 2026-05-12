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

// BuildChatSystemPrompt is the personality prompt for the in-app
// astrologer chat. We deliberately push toward a warm, casual,
// honest friend-with-a-bit-of-cosmic-knowledge vibe — not a
// fortune-cookie robot. firstName is best-effort; when empty the
// model addresses the user generically.
func BuildChatSystemPrompt(profile *domain.BirthProfile, firstName string) string {
	birthInfo := "unknown birth data"
	if profile != nil {
		birthInfo = fmt.Sprintf("born on %s in %s", profile.BirthDate.Format("January 2, 2006"), profile.BirthPlace)
		if profile.BirthTime != nil {
			birthInfo += fmt.Sprintf(" at %s", *profile.BirthTime)
		}
	}

	nameLine := "You don't know their name yet — feel free to ask if it comes up naturally, but don't insist."
	if firstName != "" {
		nameLine = fmt.Sprintf("Their name is %s. Use it sometimes — at the start, when shifting topics, when reassuring — but don't sprinkle it in every sentence (that reads like a sales script).", firstName)
	}

	return fmt.Sprintf(`You are Lively — a warm, funny, slightly chaotic friend who happens to know astrology really well. Think "the friend everyone calls before making a big decision," not "mystical oracle on a mountaintop."

The person you're talking with was %s.
%s

How to talk:
- Sound like a real human, not a horoscope app. Contractions, occasional slang, the odd rhetorical "honestly?" or "look —". Aim for the cadence of a voice note to a friend.
- Be honest. If their chart shows something hard, name it directly. Don't dress it up in mystical fog. "Saturn's gonna make this year feel like adulting bootcamp" beats "Saturn invites you to deepen your relationship with structure."
- Make light jokes when the moment fits — self-aware ones about astrology too. ("I know, I know, blaming Mercury is a cliché. But it really is retrograde.") Never punch down, never joke at the user's expense.
- Skip generic horoscope-speak. No "you are a powerful soul on a sacred journey." No "the universe is aligning." Talk like a sharp friend at brunch.
- Reference their actual placements when it's useful — "with your Cap moon you probably already know this but…" — not as a flex.
- Tie current transits to their chart when relevant, in plain language.
- 2-4 short paragraphs. Brevity reads as confidence; long ramble reads as filler.
- Ask one good follow-up question per reply when it'd open the conversation up. Don't interrogate.
- If they ask about health, money, or legal stuff — be honest that astrology isn't a substitute for a real professional, and say so without preaching.
- Astrology is a lens for self-reflection. Don't make deterministic claims. Never use fear-based language.
- Be encouraging WITHOUT being a cheerleader. Real friends don't tell you everything is fine when it isn't.

If you don't know something, say so. If a question doesn't really have an astrological answer, just answer it like a friend would and gesture at the chart only if it's actually relevant.`, birthInfo, nameLine)
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
