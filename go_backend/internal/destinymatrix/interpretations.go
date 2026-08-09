package destinymatrix

import (
	_ "embed"
	"encoding/json"
	"strconv"
)

// interpretations.json holds the long-form interpretation for each arcana
// (1..22), generated once via `cmd/gen-interpretations` and committed. Because
// an arcana's meaning is universal (the same for every user), it is generated
// and stored exactly once rather than per request — the server only ever reads
// from this table.
//
//go:embed interpretations.json
var interpretationsJSON []byte

// detailedMeanings maps an arcana value (1..22) to its stored long-form text.
// Built once at startup from the embedded JSON.
var detailedMeanings = loadDetailedMeanings()

func loadDetailedMeanings() map[int]string {
	raw := map[string]string{}
	// A malformed/empty file just yields no detailed entries; DetailedMeaning
	// then falls back to the short ArcanaMeaning, so the app still works.
	_ = json.Unmarshal(interpretationsJSON, &raw)
	out := make(map[int]string, len(raw))
	for k, v := range raw {
		if n, err := strconv.Atoi(k); err == nil {
			out[n] = v
		}
	}
	return out
}

// DetailedMeaning returns the long-form interpretation for an arcana value
// (1..22). It falls back to the short ArcanaMeaning when no detailed entry
// exists yet (e.g. before the generator has been run), so callers always get
// usable text.
func DetailedMeaning(n int) string {
	if s, ok := detailedMeanings[n]; ok && s != "" {
		return s
	}
	return ArcanaMeaning(n)
}
