package destinymatrix

// This file holds the interpretive text for the 22 Major Arcana that populate
// the octagram. Each point value 1..22 maps to one arcana with a short name
// and a one-to-two-sentence meaning.

// Arcana returns the name and meaning for an arcana value (1..22). For an
// out-of-range value it returns empty strings.
func Arcana(n int) (name, meaning string) {
	a, ok := arcana[n]
	if !ok {
		return "", ""
	}
	return a.name, a.meaning
}

// ArcanaName returns just the name for an arcana value, or "" if unknown.
func ArcanaName(n int) string {
	return arcana[n].name
}

// ArcanaMeaning returns just the meaning for an arcana value, or "" if unknown.
func ArcanaMeaning(n int) string {
	return arcana[n].meaning
}

type arcanaInfo struct {
	name    string
	meaning string
}

var arcana = map[int]arcanaInfo{
	1: {
		"The Magician",
		"Will, initiative, and the power to turn intention into action. You are wired to start things and to make the abstract real.",
	},
	2: {
		"The High Priestess",
		"Inner knowing, intuition, and the wisdom held in silence. Trusting what you sense before you can prove it is your gift.",
	},
	3: {
		"The Empress",
		"Creativity, abundance, and nurturing. You grow ideas, people, and beauty, and thrive when you let your warmth flow outward.",
	},
	4: {
		"The Emperor",
		"Structure, authority, and steady leadership. You build lasting order and feel safest when boundaries and plans are clear.",
	},
	5: {
		"The Hierophant",
		"Tradition, teaching, and shared meaning. You connect with the world through values, mentors, and the wisdom of community.",
	},
	6: {
		"The Lovers",
		"Union, choice, and the harmony of opposites. Your path turns on whom and what you choose to give your heart to.",
	},
	7: {
		"The Chariot",
		"Drive, willpower, and forward motion. You succeed by harnessing competing forces and steering them toward a single goal.",
	},
	8: {
		"Justice",
		"Balance, fairness, and cause and effect. You are called to weigh things honestly and to answer for the choices you make.",
	},
	9: {
		"The Hermit",
		"Solitude, reflection, and inner light. You find your deepest answers by withdrawing to think before you guide others.",
	},
	10: {
		"Wheel of Fortune",
		"Cycles, change, and destiny in motion. Your life turns on timing; learning to ride the wheel rather than fight it is key.",
	},
	11: {
		"Strength",
		"Courage, patience, and gentle mastery. You tame difficulty not by force but by calm, compassionate persistence.",
	},
	12: {
		"The Hanged Man",
		"Surrender, perspective, and the pause before insight. Growth comes when you let go and see your life from a new angle.",
	},
	13: {
		"Death (Transformation)",
		"Endings that clear the way for renewal. You are built for deep change, releasing what is finished so something truer can begin.",
	},
	14: {
		"Temperance",
		"Balance, blending, and patient healing. You harmonize extremes and do your best work as a bridge between opposing energies.",
	},
	15: {
		"The Devil",
		"Desire, attachment, and the shadow. Your lessons involve facing temptation and reclaiming power from what binds you.",
	},
	16: {
		"The Tower",
		"Sudden upheaval that breaks false structures. Disruptions in your life strip away illusion and force liberating honesty.",
	},
	17: {
		"The Star",
		"Hope, inspiration, and quiet renewal. You carry a healing, guiding light and shine brightest after coming through darkness.",
	},
	18: {
		"The Moon",
		"Dreams, intuition, and the unseen. You move through mystery and emotion, learning to trust feeling without losing your footing.",
	},
	19: {
		"The Sun",
		"Joy, vitality, and clear self-expression. You radiate warmth and success when you let your authentic self be fully seen.",
	},
	20: {
		"Judgement",
		"Awakening, reckoning, and renewal of purpose. You are called to rise into a higher version of yourself and answer a deeper calling.",
	},
	21: {
		"The World",
		"Completion, wholeness, and integration. You are meant to bring things full circle and to feel at home everywhere you go.",
	},
	22: {
		"The Fool",
		"Boundless potential, trust, and the leap into the new. You embody open-hearted beginnings and the freedom of an unwritten path.",
	},
}
