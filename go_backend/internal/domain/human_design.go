package domain

// HumanDesignChart is the full Human Design reading for a person.
//
// Type / Strategy / Authority / Profile / Definition / NotSelfTheme are
// derived metadata from the underlying gate / channel / center mechanics.
type HumanDesignChart struct {
	Type             string             `json:"type"`              // Manifestor | Generator | Manifesting Generator | Projector | Reflector
	Strategy         string             `json:"strategy"`
	Authority        string             `json:"authority"`         // Emotional | Sacral | Splenic | Ego | Self-Projected | Mental | Lunar
	Profile          string             `json:"profile"`           // "3/5", "1/3", etc.
	Definition       string             `json:"definition"`        // Single | Split | Triple Split | Quadruple Split | None
	NotSelfTheme     string             `json:"not_self_theme"`    // Anger / Frustration / Bitterness / Disappointment
	Centers          []HDCenter         `json:"centers"`           // 9 entries, canonical order
	Gates            []HDGateActivation `json:"gates"`             // 26 = 13 personality + 13 design
	Channels         []HDChannel        `json:"channels"`          // only those defined
	IncarnationCross HDCross            `json:"incarnation_cross"`
	Variables        HDVariables        `json:"variables"`
}

// HDCenter is one of the 9 energy centers.
type HDCenter struct {
	Name    string `json:"name"`
	Defined bool   `json:"defined"`
	Gates   []int  `json:"gates"` // active gates of this center in this chart
}

// HDGateActivation is one body's gate position (and which chart it's from).
type HDGateActivation struct {
	Gate          int    `json:"gate"`
	Line          int    `json:"line"`            // 1..6
	Body          string `json:"body"`            // Sun, Moon, Earth, ...
	IsPersonality bool   `json:"is_personality"`  // false = design (88° earlier)
}

// HDChannel is one defined channel between two centers.
type HDChannel struct {
	Gate1   int      `json:"gate1"`
	Gate2   int      `json:"gate2"`
	Name    string   `json:"name"`
	Centers []string `json:"centers"` // length 2
}

// HDCross is the Incarnation Cross — your life's purpose theme.
type HDCross struct {
	Name    string `json:"name"`
	Quarter string `json:"quarter"` // Initiation | Civilization | Duality | Mutation
	Gates   [4]int `json:"gates"`   // [pers Sun, pers Earth, design Sun, design Earth]
}

// HDVariables is the four-arrow PRA strip below the body graph.
type HDVariables struct {
	Digestion   string `json:"digestion"`   // Left | Right
	Environment string `json:"environment"` // Left | Right
	Awareness   string `json:"awareness"`   // Left | Right
	Perspective string `json:"perspective"` // Left | Right
}
