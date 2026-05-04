package swisseph

import (
	"context"
	"fmt"
	"math"
	"sort"
	"time"

	"github.com/mshafiee/swephgo"

	"cosmic-mirror/internal/domain"
)

// hdBodies are the 13 bodies whose tropical longitude is computed for both
// the Personality (birth) chart and the Design (88° solar arc earlier) chart.
// Earth is computed as Sun + 180°. South Node = North Node + 180°.
var hdBodies = []planetSpec{
	{"Sun", swephgo.SeSun},
	{"Moon", swephgo.SeMoon},
	{"NorthNode", swephgo.SeTrueNode},
	{"Mercury", swephgo.SeMercury},
	{"Venus", swephgo.SeVenus},
	{"Mars", swephgo.SeMars},
	{"Jupiter", swephgo.SeJupiter},
	{"Saturn", swephgo.SeSaturn},
	{"Uranus", swephgo.SeUranus},
	{"Neptune", swephgo.SeNeptune},
	{"Pluto", swephgo.SePluto},
}

// computeTropicalPlanetsForHD returns the 13 HD bodies (11 from swephgo +
// derived Earth + South Node) with tropical longitudes at the given JD.
func computeTropicalPlanetsForHD(jdUT float64) ([]planetPosition, error) {
	computeMu.Lock()
	defer computeMu.Unlock()

	// Tropical: SeflgSwieph + speed (no SeflgSidereal here).
	flags := swephgo.SeflgSwieph | swephgo.SeflgSpeed
	out := make([]planetPosition, 0, 13)
	var sunLon, nodeLon float64
	for _, b := range hdBodies {
		xx := make([]float64, 6)
		serr := make([]byte, 256)
		ret := swephgo.CalcUt(jdUT, b.ID, flags, xx, serr)
		if ret < 0 {
			return nil, fmt.Errorf("hd calc %s: %s", b.Name, trimNullBytes(serr))
		}
		out = append(out, planetPosition{
			Name:       b.Name,
			Longitude:  xx[0],
			Speed:      xx[3],
			Retrograde: xx[3] < 0,
		})
		switch b.Name {
		case "Sun":
			sunLon = xx[0]
		case "NorthNode":
			nodeLon = xx[0]
		}
	}
	// Earth = Sun + 180°
	out = append(out, planetPosition{
		Name:      "Earth",
		Longitude: math.Mod(sunLon+180, 360),
	})
	// South Node = North Node + 180°
	out = append(out, planetPosition{
		Name:      "SouthNode",
		Longitude: math.Mod(nodeLon+180, 360),
	})
	return out, nil
}

// findDesignTime returns the JD at which the Sun's tropical longitude was
// 88° behind its longitude at jdUT (`birthSunLon`). Uses Newton iteration
// starting from jdUT - 88.0 days; the Sun's mean motion is ≈ 0.9856°/day
// so this converges quickly.
func findDesignTime(jdUT, birthSunLon float64) (float64, error) {
	target := math.Mod(birthSunLon-88+360, 360)
	jd := jdUT - 88.0 // initial guess

	for i := 0; i < 20; i++ {
		// Compute Sun longitude at current jd.
		computeMu.Lock()
		xx := make([]float64, 6)
		serr := make([]byte, 256)
		flags := swephgo.SeflgSwieph | swephgo.SeflgSpeed
		ret := swephgo.CalcUt(jd, swephgo.SeSun, flags, xx, serr)
		computeMu.Unlock()
		if ret < 0 {
			return 0, fmt.Errorf("design sun calc: %s", trimNullBytes(serr))
		}
		sunLon := xx[0]
		sunSpeed := xx[3]
		if sunSpeed == 0 {
			sunSpeed = 0.9856 // fallback to mean motion
		}
		diff := math.Mod(sunLon-target+540, 360) - 180 // signed [-180, 180]
		if math.Abs(diff) < 0.0001 {
			return jd, nil
		}
		jd -= diff / sunSpeed
	}
	return jd, nil // converged or close enough
}

// HDActivation is one body's gate/line in either Personality or Design.
type hdActivation struct {
	Body          string
	Gate          int
	Line          int
	Color         int
	Tone          int
	IsPersonality bool
}

// GetHumanDesign computes the full chart for the given birth data.
func (c *Client) GetHumanDesign(
	ctx context.Context,
	birthDate time.Time,
	birthHour, birthMin int,
	lat, lon, tzone float64,
) (*domain.HumanDesignChart, error) {
	if err := c.Init(); err != nil {
		return nil, fmt.Errorf("swisseph init: %w", err)
	}
	hourLocal := float64(birthHour) + float64(birthMin)/60.0
	hourUT := hourLocal - tzone
	jdUT := swephgo.Julday(
		birthDate.Year(), int(birthDate.Month()), birthDate.Day(),
		hourUT, swephgo.SeGregCal,
	)

	// Personality positions = at birth time.
	personPlanets, err := computeTropicalPlanetsForHD(jdUT)
	if err != nil {
		return nil, fmt.Errorf("personality: %w", err)
	}

	// Find Sun's longitude at birth for the Design search.
	var birthSunLon float64
	for _, p := range personPlanets {
		if p.Name == "Sun" {
			birthSunLon = p.Longitude
			break
		}
	}

	// Design = the moment when the Sun was 88° earlier on the ecliptic.
	designJD, err := findDesignTime(jdUT, birthSunLon)
	if err != nil {
		return nil, fmt.Errorf("design time: %w", err)
	}
	designPlanets, err := computeTropicalPlanetsForHD(designJD)
	if err != nil {
		return nil, fmt.Errorf("design planets: %w", err)
	}

	// Compute activations for every body in both charts.
	activations := make([]hdActivation, 0, 26)
	for _, p := range personPlanets {
		g, l, col, tn := gateForLongitude(p.Longitude)
		activations = append(activations, hdActivation{
			Body: p.Name, Gate: g, Line: l, Color: col, Tone: tn,
			IsPersonality: true,
		})
	}
	for _, p := range designPlanets {
		g, l, col, tn := gateForLongitude(p.Longitude)
		activations = append(activations, hdActivation{
			Body: p.Name, Gate: g, Line: l, Color: col, Tone: tn,
			IsPersonality: false,
		})
	}

	// Build the set of defined gates.
	defGates := make(map[int]bool, 26)
	for _, a := range activations {
		defGates[a.Gate] = true
	}

	// Find defined channels — both endpoints in defGates.
	var definedChannels []domain.HDChannel
	channelTouchedCenter := make(map[string]bool)
	for _, ch := range channels {
		if defGates[ch.Gate1] && defGates[ch.Gate2] {
			definedChannels = append(definedChannels, domain.HDChannel{
				Gate1:   ch.Gate1,
				Gate2:   ch.Gate2,
				Name:    ch.Name,
				Centers: []string{ch.Centers[0], ch.Centers[1]},
			})
			channelTouchedCenter[ch.Centers[0]] = true
			channelTouchedCenter[ch.Centers[1]] = true
		}
	}

	// Build defined-centers list (in canonical order).
	centersOut := make([]domain.HDCenter, 0, 9)
	for _, name := range HDCenterNames {
		// The "active gates" of this center are gates from defGates that
		// also belong to this center.
		var activeGates []int
		for _, g := range centerGates[name] {
			if defGates[g] {
				activeGates = append(activeGates, g)
			}
		}
		sort.Ints(activeGates)
		centersOut = append(centersOut, domain.HDCenter{
			Name:    name,
			Defined: channelTouchedCenter[name],
			Gates:   activeGates,
		})
	}

	// Sort gate activations by Personality-first then by canonical body order.
	bodyOrder := map[string]int{
		"Sun": 0, "Earth": 1, "NorthNode": 2, "SouthNode": 3, "Moon": 4,
		"Mercury": 5, "Venus": 6, "Mars": 7, "Jupiter": 8, "Saturn": 9,
		"Uranus": 10, "Neptune": 11, "Pluto": 12,
	}
	sort.SliceStable(activations, func(i, j int) bool {
		if activations[i].IsPersonality != activations[j].IsPersonality {
			return activations[i].IsPersonality
		}
		return bodyOrder[activations[i].Body] < bodyOrder[activations[j].Body]
	})
	gatesOut := make([]domain.HDGateActivation, 0, len(activations))
	for _, a := range activations {
		gatesOut = append(gatesOut, domain.HDGateActivation{
			Gate:          a.Gate,
			Line:          a.Line,
			Body:          a.Body,
			IsPersonality: a.IsPersonality,
		})
	}

	// Type
	hdType := determineType(channelTouchedCenter, definedChannels)

	// Authority
	authority := determineAuthority(channelTouchedCenter, definedChannels, hdType)

	// Profile = personality-Sun line × design-Sun line
	var pSunLine, dSunLine int
	for _, a := range activations {
		if a.Body == "Sun" {
			if a.IsPersonality {
				pSunLine = a.Line
			} else {
				dSunLine = a.Line
			}
		}
	}
	profile := fmt.Sprintf("%d/%d", pSunLine, dSunLine)

	// Definition (component count)
	definition := determineDefinition(definedChannels, channelTouchedCenter)

	strategy, notSelf := strategyAndNotSelf(hdType)

	// Incarnation cross
	cross := buildIncarnationCross(activations)

	// Variables — computed from Personality Sun's color/tone.
	var pSunColor, pSunTone, dSunColor, dSunTone int
	for _, a := range activations {
		if a.Body == "Sun" {
			if a.IsPersonality {
				pSunColor = a.Color
				pSunTone = a.Tone
			} else {
				dSunColor = a.Color
				dSunTone = a.Tone
			}
		}
	}
	variables := domain.HDVariables{
		Digestion:   leftRightFromColor(pSunColor),
		Environment: leftRightFromColor(dSunColor),
		Awareness:   leftRightFromTone(pSunTone),
		Perspective: leftRightFromTone(dSunTone),
	}

	return &domain.HumanDesignChart{
		Type:             hdType,
		Strategy:         strategy,
		Authority:        authority,
		Profile:          profile,
		Definition:       definition,
		NotSelfTheme:     notSelf,
		Centers:          centersOut,
		Gates:            gatesOut,
		Channels:         definedChannels,
		IncarnationCross: cross,
		Variables:        variables,
	}, nil
}

// determineType applies the canonical priority logic.
func determineType(definedCenters map[string]bool, channels []domain.HDChannel) string {
	if len(definedCenters) == 0 {
		return "Reflector"
	}
	sacralDefined := definedCenters["Sacral"]
	throatDefined := definedCenters["Throat"]
	throatViaMotor := false
	if throatDefined {
		throatViaMotor = isThroatConnectedToMotor(channels)
	}

	switch {
	case sacralDefined && throatViaMotor:
		return "Manifesting Generator"
	case sacralDefined:
		return "Generator"
	case throatViaMotor:
		return "Manifestor"
	default:
		return "Projector"
	}
}

// isThroatConnectedToMotor traverses defined channels to find a Throat→motor path.
func isThroatConnectedToMotor(channels []domain.HDChannel) bool {
	// Build adjacency among defined centers.
	adj := make(map[string]map[string]bool)
	for _, c := range channels {
		a, b := c.Centers[0], c.Centers[1]
		if adj[a] == nil {
			adj[a] = map[string]bool{}
		}
		if adj[b] == nil {
			adj[b] = map[string]bool{}
		}
		adj[a][b] = true
		adj[b][a] = true
	}
	// BFS from Throat.
	if _, ok := adj["Throat"]; !ok {
		return false
	}
	visited := map[string]bool{"Throat": true}
	queue := []string{"Throat"}
	for len(queue) > 0 {
		node := queue[0]
		queue = queue[1:]
		for next := range adj[node] {
			if visited[next] {
				continue
			}
			if motorCenters[next] {
				return true
			}
			visited[next] = true
			queue = append(queue, next)
		}
	}
	return false
}

func determineAuthority(definedCenters map[string]bool, channels []domain.HDChannel, hdType string) string {
	if hdType == "Reflector" {
		return "Lunar"
	}
	if definedCenters["SolarPlexus"] {
		return "Emotional"
	}
	if definedCenters["Sacral"] {
		return "Sacral"
	}
	if definedCenters["Spleen"] {
		return "Splenic"
	}
	if definedCenters["Heart"] {
		// Ego if connected to Throat (Manifestor); Self-Projected if to G.
		if hasChannel(channels, "Heart", "Throat") {
			return "Ego"
		}
		if hasChannel(channels, "Heart", "G") {
			return "Self-Projected"
		}
		return "Ego"
	}
	// Mental / Sounding Board (only for Projectors with no inner motor).
	return "Mental"
}

func hasChannel(channels []domain.HDChannel, a, b string) bool {
	for _, c := range channels {
		if (c.Centers[0] == a && c.Centers[1] == b) ||
			(c.Centers[0] == b && c.Centers[1] == a) {
			return true
		}
	}
	return false
}

// determineDefinition counts the connected components in the defined-channel graph.
func determineDefinition(channels []domain.HDChannel, definedCenters map[string]bool) string {
	if len(definedCenters) == 0 {
		return "None"
	}
	adj := make(map[string]map[string]bool)
	for c := range definedCenters {
		adj[c] = map[string]bool{}
	}
	for _, ch := range channels {
		a, b := ch.Centers[0], ch.Centers[1]
		adj[a][b] = true
		adj[b][a] = true
	}
	visited := map[string]bool{}
	components := 0
	for start := range adj {
		if visited[start] {
			continue
		}
		components++
		// BFS
		queue := []string{start}
		visited[start] = true
		for len(queue) > 0 {
			node := queue[0]
			queue = queue[1:]
			for next := range adj[node] {
				if !visited[next] {
					visited[next] = true
					queue = append(queue, next)
				}
			}
		}
	}
	switch components {
	case 1:
		return "Single"
	case 2:
		return "Split"
	case 3:
		return "Triple Split"
	case 4:
		return "Quadruple Split"
	default:
		return fmt.Sprintf("%d Components", components)
	}
}

func strategyAndNotSelf(hdType string) (strategy, notSelf string) {
	switch hdType {
	case "Manifestor":
		return "Inform before acting", "Anger"
	case "Generator":
		return "Wait to respond", "Frustration"
	case "Manifesting Generator":
		return "Wait to respond, then inform", "Frustration & Anger"
	case "Projector":
		return "Wait for the invitation", "Bitterness"
	case "Reflector":
		return "Wait a lunar cycle (28 days)", "Disappointment"
	}
	return "", ""
}

func buildIncarnationCross(acts []hdActivation) domain.HDCross {
	var pSun, pEarth, dSun, dEarth int
	for _, a := range acts {
		switch {
		case a.Body == "Sun" && a.IsPersonality:
			pSun = a.Gate
		case a.Body == "Earth" && a.IsPersonality:
			pEarth = a.Gate
		case a.Body == "Sun" && !a.IsPersonality:
			dSun = a.Gate
		case a.Body == "Earth" && !a.IsPersonality:
			dEarth = a.Gate
		}
	}
	// Quarter is determined by the personality Sun's gate; uses a fixed
	// mapping per Ra Uru Hu's Global Cycle:
	//   Initiation  : gates from 13 onward in the wheel-walk (13, 49, 30, 55, 37, 63, 22, 36, 25, 17, 21, 51, 42, 3, 27, 24)
	//   Civilization: 2, 23, 8, 20, 16, 35, 45, 12, 15, 52, 39, 53, 62, 56, 31, 33
	//   Duality     : 7, 4, 29, 59, 40, 64, 47, 6, 46, 18, 48, 57, 32, 50
	//   Mutation    : 28, 44, 1, 43, 14, 34, 9, 5, 26, 11, 10, 58, 38, 54, 61, 60, 41, 19
	quarter := quarterForGate(pSun)
	name := fmt.Sprintf("Cross of (%d/%d | %d/%d)", pSun, pEarth, dSun, dEarth)
	return domain.HDCross{
		Name:    name,
		Quarter: quarter,
		Gates:   [4]int{pSun, pEarth, dSun, dEarth},
	}
}

var quarterMap = func() map[int]string {
	m := make(map[int]string, 64)
	initiation := []int{13, 49, 30, 55, 37, 63, 22, 36, 25, 17, 21, 51, 42, 3, 27, 24}
	civilization := []int{2, 23, 8, 20, 16, 35, 45, 12, 15, 52, 39, 53, 62, 56, 31, 33}
	duality := []int{7, 4, 29, 59, 40, 64, 47, 6, 46, 18, 48, 57, 32, 50}
	mutation := []int{28, 44, 1, 43, 14, 34, 9, 5, 26, 11, 10, 58, 38, 54, 61, 60, 41, 19}
	for _, g := range initiation {
		m[g] = "Initiation"
	}
	for _, g := range civilization {
		m[g] = "Civilization"
	}
	for _, g := range duality {
		m[g] = "Duality"
	}
	for _, g := range mutation {
		m[g] = "Mutation"
	}
	return m
}()

func quarterForGate(g int) string {
	if q, ok := quarterMap[g]; ok {
		return q
	}
	return "Initiation"
}

func leftRightFromColor(c int) string {
	if c <= 3 {
		return "Left"
	}
	return "Right"
}

func leftRightFromTone(t int) string {
	if t <= 3 {
		return "Left"
	}
	return "Right"
}
