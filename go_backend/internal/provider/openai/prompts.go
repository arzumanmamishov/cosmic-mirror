package openai

import (
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
)

// LangDirective returns the output-language instruction appended to every
// system prompt. Keeping it in one place means adding a new UI language
// is a single-line change.
//
// For unsupported codes we return the same directive as English (empty).
func LangDirective(lang string) string {
	switch strings.ToLower(lang) {
	case "tr":
		return "\n\nIMPORTANT: Respond entirely in Turkish (Türkçe). All prose, narratives, titles, descriptions, and JSON string values must be written in fluent, natural Turkish. Keep the JSON keys exactly as specified (in English)."
	}
	return ""
}

func BuildDailyReadingPrompt(profile *domain.BirthProfile, date time.Time, lang string) []Message {
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
Always return valid JSON matching the exact schema requested.` + LangDirective(lang),
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

func BuildCompatibilityPrompt(userProfile *domain.BirthProfile, personDescription string, lang string) []Message {
	return []Message{
		{
			Role: "system",
			Content: `You are an empathic relationship astrologer who analyzes compatibility between two people.
Be honest but compassionate. Highlight strengths and growth areas equally.
Never make absolute statements about relationship success or failure.
Frame challenges as opportunities for mutual growth.
Always return valid JSON matching the exact schema requested.` + LangDirective(lang),
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
func BuildChatSystemPrompt(profile *domain.BirthProfile, firstName string, lang string) string {
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

If you don't know something, say so. If a question doesn't really have an astrological answer, just answer it like a friend would and gesture at the chart only if it's actually relevant.`, birthInfo, nameLine) + LangDirective(lang)
}

// TransitEventLite is the subset of a Swiss-Ephemeris-computed transit that we
// hand to the LLM. We keep it small + flat so it tokenizes cleanly and the
// model can't get confused by extraneous fields. Defined here (not in the
// swisseph package) so that prompts.go does not import a provider package.
type TransitEventLite struct {
	Date        string // YYYY-MM-DD
	Type        string // ingress | lunation | retrograde | aspect
	Body        string
	NatalPoint  string // for aspects
	Aspect      string // for aspects
	Sign        string // for ingresses + lunations
	Phase       string // for retrogrades + lunations
	Description string
}

func formatTransitEvents(events []TransitEventLite) string {
	if len(events) == 0 {
		return "(no major transits in this window — focus on the natal chart's standing pattern)"
	}
	var b strings.Builder
	for _, e := range events {
		b.WriteString("- ")
		b.WriteString(e.Date)
		b.WriteString(": ")
		b.WriteString(e.Description)
		b.WriteByte('\n')
	}
	return b.String()
}

func BuildTimelinePrompt(profile *domain.BirthProfile, forecastType string, events []TransitEventLite, start, end time.Time, lang string) []Message {
	return []Message{
		{
			Role: "system",
			Content: `You are an insightful astrologer creating timeline forecasts.
Frame timing as windows of energy, not guarantees. Be practical and encouraging.

CRITICAL: You will be given a list of REAL transit events computed from the Swiss Ephemeris.
- Do NOT invent dates, planets, or aspects. Only narrate around the events provided.
- If two events are close in time, you may group them into a single period.
- Each period's "date_range" must use real dates from the events list.
- If the events list is empty, return 1-2 periods describing the steady background energy of the chart, without inventing transits.
Always return valid JSON.` + LangDirective(lang),
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Create a %s timeline forecast for someone born on %s in %s.

Window: %s → %s

REAL TRANSIT EVENTS (Swiss Ephemeris ground truth — narrate AROUND these only):
%s

Return JSON: {"periods": [{"title": "string", "date_range": "Mon D – Mon D, YYYY", "description": "2-3 sentences in warm second-person voice", "energy": "positive|neutral|challenging|intense"}]}

Group the events into 3-6 meaningful periods. Each period must reference real transits from the list. Tie the energy honestly to the aspect (squares/oppositions/Saturn = challenging or intense; trines/sextiles/Jupiter = positive; ingresses = neutral unless to a personal point).`,
				forecastType,
				profile.BirthDate.Format("2006-01-02"),
				profile.BirthPlace,
				start.Format("January 2, 2006"),
				end.Format("January 2, 2006"),
				formatTransitEvents(events),
			),
		},
	}
}

func BuildYearlyForecastPrompt(profile *domain.BirthProfile, year int, events []TransitEventLite, lang string) []Message {
	q1End := time.Date(year, 4, 1, 0, 0, 0, 0, time.UTC)
	q2End := time.Date(year, 7, 1, 0, 0, 0, 0, time.UTC)
	q3End := time.Date(year, 10, 1, 0, 0, 0, 0, time.UTC)
	yearEnd := time.Date(year+1, 1, 1, 0, 0, 0, 0, time.UTC)

	q1, q2, q3, q4 := splitEventsByQuarters(events, q1End, q2End, q3End, yearEnd)

	return []Message{
		{
			Role: "system",
			Content: `You are a visionary astrologer creating yearly forecasts.
Frame the year as a growth journey. Be inspiring and practical.

CRITICAL: You will receive REAL transit events computed from the Swiss Ephemeris, pre-bucketed by quarter.
- Do NOT invent dates, planets, or aspects. Each quarter description must reference the actual transits given for that quarter.
- The theme + overview can be looser/poetic but must still be grounded in the year's overall pattern of transits.
- If a quarter has no major transits, write a description focused on the standing chart energy without inventing transits.
Always return valid JSON.` + LangDirective(lang),
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Create a %d yearly forecast for someone born on %s in %s.

REAL TRANSIT EVENTS BY QUARTER (Swiss Ephemeris ground truth — use ONLY these):

Q1 (Jan–Mar):
%s

Q2 (Apr–Jun):
%s

Q3 (Jul–Sep):
%s

Q4 (Oct–Dec):
%s

Return JSON:
{
  "theme": "<3-5 word year theme>",
  "overview": "<2-3 paragraph overview synthesizing the year's biggest transits>",
  "quarters": [
    {"label": "Q1: January - March", "description": "2-3 paragraphs referencing the Q1 transits above"},
    {"label": "Q2: April - June", "description": "2-3 paragraphs referencing the Q2 transits above"},
    {"label": "Q3: July - September", "description": "2-3 paragraphs referencing the Q3 transits above"},
    {"label": "Q4: October - December", "description": "2-3 paragraphs referencing the Q4 transits above"}
  ]
}`,
				year,
				profile.BirthDate.Format("2006-01-02"),
				profile.BirthPlace,
				formatTransitEvents(q1),
				formatTransitEvents(q2),
				formatTransitEvents(q3),
				formatTransitEvents(q4),
			),
		},
	}
}

// splitEventsByQuarters slots events into four quarter buckets by their date.
// Events outside the year window are dropped.
func splitEventsByQuarters(events []TransitEventLite, q1End, q2End, q3End, yearEnd time.Time) (q1, q2, q3, q4 []TransitEventLite) {
	for _, e := range events {
		t, err := time.Parse("2006-01-02", e.Date)
		if err != nil {
			continue
		}
		switch {
		case t.Before(q1End):
			q1 = append(q1, e)
		case t.Before(q2End):
			q2 = append(q2, e)
		case t.Before(q3End):
			q3 = append(q3, e)
		case t.Before(yearEnd):
			q4 = append(q4, e)
		}
	}
	return
}

func BuildNotificationPrompt(profile *domain.BirthProfile, date time.Time, lang string) []Message {
	return []Message{
		{
			Role: "system",
			Content: `Generate a short, personalized push notification for a daily astrology reading.
Keep it under 100 characters. Be intriguing and warm. Never fear-based.` + LangDirective(lang),
		},
		{
			Role: "user",
			Content: fmt.Sprintf(`Push notification for %s, born %s. Return JSON: {"title": "string", "body": "string"}`,
				date.Format("January 2"), profile.BirthDate.Format("2006-01-02")),
		},
	}
}
