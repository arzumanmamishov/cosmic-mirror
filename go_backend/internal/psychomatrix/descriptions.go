package psychomatrix

// This file holds the interpretive text for the psychomatrix: per-cell
// meanings that vary by how many times the digit appears (the "count band"),
// and per-line meanings that vary by line strength.

// CellTitle returns the short title for a grid cell digit (1..9).
func CellTitle(digit int) string {
	return cellTitles[digit]
}

var cellTitles = map[int]string{
	1: "Character",
	2: "Energy",
	3: "Interest & Cognition",
	4: "Health",
	5: "Logic & Intuition",
	6: "Skill & Labor",
	7: "Luck",
	8: "Sense of Duty",
	9: "Memory & Intelligence",
}

// countBand maps a raw count to a band index used for selecting text:
//
//	0 -> absent, 1 -> single, 2 -> double, 3 -> triple, 4+ -> abundant.
func countBand(count int) int {
	if count >= 4 {
		return 4
	}
	if count < 0 {
		return 0
	}
	return count
}

// CellMeaning returns the interpretation for a cell digit given how many
// times that digit occurs in the digit pool.
func CellMeaning(digit, count int) string {
	bands, ok := cellBands[digit]
	if !ok {
		return ""
	}
	return bands[countBand(count)]
}

// cellBands[digit] = [absent, single, double, triple, abundant].
var cellBands = map[int][5]string{
	1: {
		"No 1s: a soft, accommodating will. You shape your character through others and tend to defer rather than insist.",
		"One 1: a flexible egoist — self-interested but willing to bend; you weigh your own needs against others'.",
		"Two 1s: a balanced, settled character. You know your own mind without forcing it on anyone.",
		"Three 1s: a steady, even-tempered will. Adaptable yet firm when it matters.",
		"Four or more 1s: a strong, dominant will. A natural leader who can be stubborn and slow to yield.",
	},
	2: {
		"No 2s: very low bioenergy at birth; you replenish energy through care, contact, and good habits rather than reserves.",
		"One 2: modest energy reserves. You give what you receive and dislike depleting yourself for others.",
		"Two 2s: healthy bioenergy and a knack for sensing others — a natural empath and sometimes a healer.",
		"Three 2s: abundant energy with strong intuition and a pull toward helping or healing others.",
		"Four or more 2s: powerful, magnetic energy. You can give a great deal but must guard against burning out.",
	},
	3: {
		"No 3s: little drive toward exact sciences; you lean on intuition, order, and tidiness instead of theory.",
		"One 3: average curiosity — interests come and go depending on mood and circumstance.",
		"Two 3s: a real aptitude for science, technology, or analysis when you choose to apply it.",
		"Three 3s: strong scientific and analytical talent; precision and study come naturally.",
		"Four or more 3s: exceptional cognitive drive — best channeled into one focused field to avoid scattering.",
	},
	4: {
		"No 4s: a more delicate constitution; health rewards consistent care and rest, especially later in life.",
		"One 4: generally sound health with average resilience to strain.",
		"Two 4s: a robust constitution and good physical endurance.",
		"Three 4s: strong vitality and stamina; you recover quickly and tire slowly.",
		"Four or more 4s: very strong physical reserves and an athletic, hardy nature.",
	},
	5: {
		"No 5s: you learn primarily by experience and trial, often making the same discoveries more than once.",
		"One 5: developing intuition; reasoning is sound but second-guessing is common.",
		"Two 5s: well-developed logic and intuition — you rarely take wrong turns and read situations clearly.",
		"Three 5s: highly intuitive, almost clairvoyant insight paired with sharp reasoning.",
		"Four or more 5s: a powerful inner compass; you sense outcomes early and seldom err on the important calls.",
	},
	6: {
		"No 6s: little natural pull toward manual craft; you prefer mental work and may need to learn hands-on skills.",
		"One 6: capable with your hands when required, though craft is not your first love.",
		"Two 6s: a genuine aptitude for physical, hands-on, or craft work — you enjoy making and building.",
		"Three 6s: strong practical skill and a real love of grounded, productive labor.",
		"Four or more 6s: an exceptional maker; hard physical or technical work is where you shine and should be balanced with rest.",
	},
	7: {
		"No 7s: luck is earned, not given; you build fortune through effort and persistence rather than chance.",
		"One 7: a faint streak of luck and latent talent that grows the more you cultivate it.",
		"Two 7s: noticeable good fortune and a clear creative or artistic gift.",
		"Three 7s: strong luck and talent; opportunities seem to find you and gifts come easily.",
		"Four or more 7s: a marked, almost protective fortune — great talent that asks to be used responsibly.",
	},
	8: {
		"No 8s: a developing sense of duty; responsibility and punctuality are qualities you grow into.",
		"One 8: a fair sense of duty — you meet obligations, especially ones you have chosen.",
		"Two 8s: a strong, dependable sense of responsibility and care toward others.",
		"Three 8s: a deep, sometimes self-sacrificing sense of duty and service.",
		"Four or more 8s: an extraordinary, all-consuming sense of obligation; remember to extend the same care to yourself.",
	},
	9: {
		"No 9s: memory and abstract reasoning take effort; repetition and good notes serve you well.",
		"One 9: average memory and intellect — enough for daily life, sharpened by deliberate practice.",
		"Two 9s: a good mind and reliable memory; you grasp and retain ideas readily.",
		"Three 9s: a sharp intellect and strong memory; learning comes quickly.",
		"Four or more 9s: a brilliant, retentive mind — capable of demanding intellectual work but easily impatient with slower minds.",
	},
}

// LineTitle returns the display title for a line key.
func LineTitle(key string) string {
	return lineTitles[key]
}

var lineTitles = map[string]string{
	"row_147":  "Sense of Purpose",
	"row_258":  "Family",
	"row_369":  "Stability",
	"col_123":  "Self-esteem",
	"col_456":  "Everyday / Material",
	"col_789":  "Talent",
	"diag_159": "Spirituality",
	"diag_357": "Temperament",
}

// LineMeaning returns the interpretation for a line given its strength
// (total digit count across its three cells). Strength is read in three
// bands: weak (0-1), balanced (2-4), strong (5+).
func LineMeaning(key string, strength int) string {
	bands, ok := lineBands[key]
	if !ok {
		return ""
	}
	switch {
	case strength <= 1:
		return bands[0]
	case strength <= 4:
		return bands[1]
	default:
		return bands[2]
	}
}

// lineBands[key] = [weak, balanced, strong].
var lineBands = map[string][3]string{
	"row_147": {
		"Weak sense of purpose: goals shift easily and follow-through can be hard to sustain.",
		"Balanced determination: you set goals and pursue them with steady, realistic resolve.",
		"Very strong purpose: a driven, goal-oriented nature that pushes relentlessly toward what it wants.",
	},
	"row_258": {
		"Low family drive: independence comes first; partnership and domestic life take conscious effort.",
		"Balanced family aptitude: you value close bonds and can build a warm, stable home.",
		"Powerful family orientation: deeply devoted to loved ones and home, sometimes to your own cost.",
	},
	"row_369": {
		"Low stability: restless and changeable, you thrive on novelty more than routine.",
		"Balanced stability: grounded and consistent without being rigid.",
		"High stability: very settled and dependable, occasionally resistant to needed change.",
	},
	"col_123": {
		"Fragile self-esteem: confidence depends heavily on outside validation.",
		"Healthy self-esteem: a steady, realistic sense of your own worth.",
		"Strong self-esteem: marked self-assurance that can edge into pride if unchecked.",
	},
	"col_456": {
		"Low material focus: practical, everyday matters feel like a chore rather than a calling.",
		"Balanced practicality: competent and efficient with day-to-day work and resources.",
		"Strong material drive: highly capable and industrious in practical, worldly affairs.",
	},
	"col_789": {
		"Latent talent: gifts are present but need deliberate cultivation to surface.",
		"Balanced talent: clear abilities that you can develop and rely on.",
		"Abundant talent: strong, multifaceted gifts that flourish when given an outlet.",
	},
	"diag_159": {
		"Low spirituality: a practical, material outlook with little pull toward the metaphysical.",
		"Balanced spirituality: open to meaning and the inner life without losing your footing.",
		"Strong spirituality: a deeply felt inner and metaphysical life that guides your choices.",
	},
	"diag_357": {
		"Cool temperament: reserved, even-keeled, and slow to ignite in passion or conflict.",
		"Balanced temperament: warm and responsive without being volatile.",
		"Fiery temperament: intense, passionate energy that needs healthy outlets.",
	},
}
