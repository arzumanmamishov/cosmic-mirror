package swisseph

// Human Design — the 36 channels.
//
// A channel connects two gates living in different (or sometimes the same)
// centers. When BOTH gates are active in a person's chart, the channel is
// defined and BOTH centers connected to it become defined. The channel is
// the most consistent energetic signature in a person.

// HDChannelDef is the static description of one channel.
type HDChannelDef struct {
	Gate1   int
	Gate2   int
	Name    string
	Centers [2]string // the two centers connected (may be the same in rare cases)
}

// channels — the canonical 36 channels of the Rave system.
var channels = []HDChannelDef{
	// To-throat channels (manifestation potential)
	{1, 8, "Inspiration", [2]string{"G", "Throat"}},
	{2, 14, "The Beat", [2]string{"G", "Sacral"}},
	{3, 60, "Mutation", [2]string{"Sacral", "Root"}},
	{4, 63, "Logic", [2]string{"Ajna", "Head"}},
	{5, 15, "Rhythm", [2]string{"Sacral", "G"}},
	{6, 59, "Mating", [2]string{"SolarPlexus", "Sacral"}},
	{7, 31, "Alpha (Leadership)", [2]string{"G", "Throat"}},
	{9, 52, "Concentration", [2]string{"Sacral", "Root"}},
	{10, 20, "Awakening", [2]string{"G", "Throat"}},
	{10, 34, "Exploration", [2]string{"G", "Sacral"}},
	{10, 57, "Perfected Form", [2]string{"G", "Spleen"}},
	{11, 56, "Curiosity", [2]string{"Ajna", "Throat"}},
	{12, 22, "Openness", [2]string{"Throat", "SolarPlexus"}},
	{13, 33, "The Prodigal", [2]string{"G", "Throat"}},
	{16, 48, "The Wavelength", [2]string{"Throat", "Spleen"}},
	{17, 62, "Acceptance", [2]string{"Ajna", "Throat"}},
	{18, 58, "Judgement", [2]string{"Spleen", "Root"}},
	{19, 49, "Synthesis", [2]string{"Root", "SolarPlexus"}},
	{20, 34, "Charisma", [2]string{"Throat", "Sacral"}},
	{20, 57, "The Brain Wave", [2]string{"Throat", "Spleen"}},
	{21, 45, "Money Line", [2]string{"Heart", "Throat"}},
	{23, 43, "Structuring", [2]string{"Throat", "Ajna"}},
	{24, 61, "Awareness", [2]string{"Ajna", "Head"}},
	{25, 51, "Initiation", [2]string{"G", "Heart"}},
	{26, 44, "Surrender", [2]string{"Heart", "Spleen"}},
	{27, 50, "Preservation", [2]string{"Sacral", "Spleen"}},
	{28, 38, "Struggle", [2]string{"Spleen", "Root"}},
	{29, 46, "Discovery", [2]string{"Sacral", "G"}},
	{30, 41, "Recognition", [2]string{"SolarPlexus", "Root"}},
	{32, 54, "Transformation", [2]string{"Spleen", "Root"}},
	{34, 57, "Power", [2]string{"Sacral", "Spleen"}},
	{35, 36, "Transitoriness", [2]string{"Throat", "SolarPlexus"}},
	{37, 40, "Community", [2]string{"SolarPlexus", "Heart"}},
	{39, 55, "Emoting", [2]string{"Root", "SolarPlexus"}},
	{42, 53, "Maturation", [2]string{"Sacral", "Root"}},
	{47, 64, "Abstraction", [2]string{"Ajna", "Head"}},
}

// channelKey returns a deterministic key for a (g1, g2) pair regardless of
// argument order — used for fast active-channel lookup.
func channelKey(g1, g2 int) [2]int {
	if g1 < g2 {
		return [2]int{g1, g2}
	}
	return [2]int{g2, g1}
}

// channelByKey is built once at init for fast channel lookup.
var channelByKey = func() map[[2]int]HDChannelDef {
	m := make(map[[2]int]HDChannelDef, len(channels))
	for _, c := range channels {
		m[channelKey(c.Gate1, c.Gate2)] = c
	}
	return m
}()
