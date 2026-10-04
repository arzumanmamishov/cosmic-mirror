package numerology

// Description returns a short canned meaning for a given number context in
// the requested language ("en" or "tr"; anything else is treated as "en").
// `kind` is one of "life_path", "expression", "soul_urge", "personality",
// "maturity", "birthday", "personal_year", "personal_month", "personal_day".
//
// Master numbers and karmic-debt numbers get distinct descriptions where
// they apply. A missing Turkish entry falls back to English.
func Description(lang string, kind string, n Number) string {
	if lang == "tr" {
		if t := descriptionFrom(masterDescTR, descTablesTR, kind, n); t != "" {
			return t
		}
	}
	return descriptionFrom(masterDesc, descTables, kind, n)
}

func descriptionFrom(masters map[int]string, tables map[string]map[int]string, kind string, n Number) string {
	if n.IsMaster {
		if t, ok := masters[n.Value]; ok {
			return t
		}
	}
	return tables[kind][n.Value]
}

var masterDesc = map[int]string{
	11: "Master 11: spiritual messenger; inspiration meets intuition. Light up others by living your truth.",
	22: "Master 22: master builder; large-scale visions made tangible. Practical idealism.",
	33: "Master 33: master teacher; selfless service through compassion and creative communication.",
}

// descTables maps each description kind to its per-number English table.
var descTables = map[string]map[int]string{
	"life_path":      lifePathDesc,
	"expression":     expressionDesc,
	"soul_urge":      soulUrgeDesc,
	"personality":    personalityDesc,
	"maturity":       maturityDesc,
	"birthday":       birthdayDesc,
	"personal_year":  personalYearDesc,
	"personal_month": personalMonthDesc,
	"personal_day":   personalDayDesc,
}

var lifePathDesc = map[int]string{
	1: "The Pioneer. Independent leader; here to forge new paths and stand on your own.",
	2: "The Mediator. Sensitive cooperator; here to bring harmony, listen deeply, and unite.",
	3: "The Communicator. Creative expressionist; here to delight and inspire through words and art.",
	4: "The Builder. Disciplined craftsperson; here to create lasting structures and reliable systems.",
	5: "The Adventurer. Freedom-seeker; here to experience, change, and break stale conventions.",
	6: "The Caretaker. Heart-centered nurturer; here to heal, beautify, and protect family and community.",
	7: "The Seeker. Reflective mystic; here to study, search, and uncover hidden truths.",
	8: "The Powerhouse. Material master; here to build wealth, lead organizations, and balance ambition with integrity.",
	9: "The Humanitarian. Old soul; here to serve the whole, release the past, and love widely.",
}

var expressionDesc = map[int]string{
	1: "Your gifts express as initiative and original leadership.",
	2: "Your gifts express through partnership, tact, and graceful collaboration.",
	3: "Your gifts express as creative expression — writing, art, performance, social charm.",
	4: "Your gifts express through methodical work, structure, and practical results.",
	5: "Your gifts express as versatile communication, travel, and the spirit of adventure.",
	6: "Your gifts express through nurturing, healing, teaching, and creating beauty.",
	7: "Your gifts express as scholarship, analysis, intuition, and quiet authority.",
	8: "Your gifts express through executive power, strategy, and material accomplishment.",
	9: "Your gifts express as humanitarian service, the arts, and broad cultural vision.",
}

var soulUrgeDesc = map[int]string{
	1: "Your soul longs for autonomy and to make an original mark.",
	2: "Your soul longs for harmony, intimacy, and supportive partnership.",
	3: "Your soul longs to create, perform, and be appreciated.",
	4: "Your soul longs for stability, order, and a place that's truly yours.",
	5: "Your soul longs for freedom, novelty, and the open road.",
	6: "Your soul longs to nurture, beautify, and surround itself with love.",
	7: "Your soul longs for solitude, study, and direct experience of mystery.",
	8: "Your soul longs for material mastery and recognition for excellence.",
	9: "Your soul longs to love everyone and contribute to the larger whole.",
}

var personalityDesc = map[int]string{
	1: "You come across as confident and self-directed.",
	2: "You come across as gentle, attentive, and easy to be with.",
	3: "You come across as sparkling, witty, and socially warm.",
	4: "You come across as solid, dependable, and methodical.",
	5: "You come across as exciting, magnetic, and a bit unpredictable.",
	6: "You come across as warm, welcoming, and parental.",
	7: "You come across as introspective, mysterious, and deep.",
	8: "You come across as commanding, capable, and authoritative.",
	9: "You come across as compassionate, worldly, and quietly wise.",
}

var maturityDesc = map[int]string{
	1: "Maturity brings sovereign self-direction.",
	2: "Maturity brings deeper partnership and inner peace.",
	3: "Maturity brings refined creative expression.",
	4: "Maturity brings master craftsmanship and lasting legacy.",
	5: "Maturity brings wise discernment of when to roam and when to root.",
	6: "Maturity brings mastery of love, family, and beauty.",
	7: "Maturity brings deep wisdom and inner certainty.",
	8: "Maturity brings power used in service rather than for ego.",
	9: "Maturity brings universal compassion and graceful endings.",
}

var birthdayDesc = map[int]string{
	1: "Pioneer's spark.", 2: "Diplomatic touch.", 3: "Creative joy.",
	4: "Steady foundation.", 5: "Restless curiosity.", 6: "Caring heart.",
	7: "Seeker's mind.", 8: "Executive drive.", 9: "Compassionate vision.",
}

var personalYearDesc = map[int]string{
	1: "A year of fresh starts and bold initiative.",
	2: "A year of partnership, patience, and slow ripening.",
	3: "A year of creative expression and joyful socializing.",
	4: "A year of work, structure, and laying foundations.",
	5: "A year of change, travel, and breaking out of routine.",
	6: "A year of family, home, and responsibility.",
	7: "A year of reflection, study, and inner growth.",
	8: "A year of material achievement and reaping what you've sown.",
	9: "A year of completion, release, and humanitarian giving.",
}

var personalMonthDesc = map[int]string{
	1: "Initiate.", 2: "Cooperate.", 3: "Express.", 4: "Build.", 5: "Change.",
	6: "Care.", 7: "Reflect.", 8: "Achieve.", 9: "Release.",
}

var personalDayDesc = map[int]string{
	1: "Begin something.", 2: "Tend a relationship.", 3: "Create or share.",
	4: "Be diligent.", 5: "Change pace.", 6: "Care for someone.",
	7: "Pause and reflect.", 8: "Take charge.", 9: "Let something complete.",
}
