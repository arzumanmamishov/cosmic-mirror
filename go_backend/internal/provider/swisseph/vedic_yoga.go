package swisseph

import "cosmic-mirror/internal/domain"

// Classical Vedic yogas. Each rule is a predicate on a *VedicChart that
// returns (active, strength, contributing planets). The registry is exposed
// via ComputeYogas, which returns only the active yogas.
//
// References: Brihat Parashara Hora Shastra (BPHS), Phaladeepika, Saravali.
// We implement the canonical core that's most commonly cited in modern
// readings; this is intentionally a representative ~50, not exhaustive.

type yogaRule struct {
	Name        string
	Sanskrit    string
	Category    string
	Description string
	Check       func(*domain.VedicChart) (active bool, strength float64, planets []string)
}

// Helper: index planets by name for fast lookup.
func planetMap(chart *domain.VedicChart) map[string]domain.VedicPlanetPlacement {
	m := make(map[string]domain.VedicPlanetPlacement, len(chart.Planets))
	for _, p := range chart.Planets {
		m[p.Name] = p
	}
	return m
}

// Helper: planets in a given bhava (1..12).
func planetsInHouse(chart *domain.VedicChart, house int) []string {
	for _, b := range chart.Bhavas {
		if b.Number == house {
			return append([]string(nil), b.Planets...)
		}
	}
	return nil
}

// Helper: house number of a planet (0 if absent).
func houseOf(chart *domain.VedicChart, planet string) int {
	for _, p := range chart.Planets {
		if p.Name == planet {
			return p.House
		}
	}
	return 0
}

// Helper: distance from a to b in houses (1..12, where same house = 1, opposite = 7).
func houseDistance(a, b int) int {
	d := ((b - a + 12) % 12) + 1
	return d
}

// Kendra houses (angles): 1, 4, 7, 10.
func isKendra(h int) bool { return h == 1 || h == 4 || h == 7 || h == 10 }

// Trikona houses (trines): 1, 5, 9.
func isTrikona(h int) bool { return h == 1 || h == 5 || h == 9 }

// Dushtana houses (malefic): 6, 8, 12.
func isDushtana(h int) bool { return h == 6 || h == 8 || h == 12 }

// ===== Pancha Mahapurusha Yoga family =====
// One of five great-personage yogas: a planet (Mars/Mercury/Jupiter/Venus/
// Saturn) sits in own or exalted sign AND in a kendra from Lagna.

func panchaMahapurusha(planet, name, sanskrit string) yogaRule {
	return yogaRule{
		Name:     name,
		Sanskrit: sanskrit,
		Category: "Pancha Mahapurusha",
		Description: "A great-personage yoga formed when " + planet +
			" occupies its own or exalted sign in a kendra (1, 4, 7, 10).",
		Check: func(c *domain.VedicChart) (bool, float64, []string) {
			pm := planetMap(c)
			p, ok := pm[planet]
			if !ok {
				return false, 0, nil
			}
			if !isKendra(p.House) {
				return false, 0, nil
			}
			if p.Dignity != "exalted" && p.Dignity != "own" && p.Dignity != "mooltrikona" {
				return false, 0, nil
			}
			strength := 0.7
			if p.Dignity == "exalted" {
				strength = 1.0
			}
			return true, strength, []string{planet}
		},
	}
}

// ===== Other classical yogas =====

var gajakesari = yogaRule{
	Name:        "Gajakesari",
	Sanskrit:    "Gajakesari",
	Category:    "Lunar",
	Description: "Moon and Jupiter in mutual kendra (1, 4, 7, or 10 from each other) — bestows fame, intellect, and good fortune.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		moon := houseOf(c, "Moon")
		jup := houseOf(c, "Jupiter")
		if moon == 0 || jup == 0 {
			return false, 0, nil
		}
		d := houseDistance(moon, jup)
		if d == 1 || d == 4 || d == 7 || d == 10 {
			return true, 0.9, []string{"Moon", "Jupiter"}
		}
		return false, 0, nil
	},
}

var budhAditya = yogaRule{
	Name:        "Budh-Aditya",
	Sanskrit:    "Budhaditya",
	Category:    "Solar",
	Description: "Sun and Mercury conjunct in the same sign (and ideally not too close to combustion) — sharp intellect and communication.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		pm := planetMap(c)
		sun, sok := pm["Sun"]
		mer, mok := pm["Mercury"]
		if !sok || !mok {
			return false, 0, nil
		}
		if sun.Sign != mer.Sign {
			return false, 0, nil
		}
		strength := 0.8
		if mer.Combust {
			strength = 0.4
		}
		return true, strength, []string{"Sun", "Mercury"}
	},
}

var chandraMangala = yogaRule{
	Name:        "Chandra-Mangala",
	Sanskrit:    "Chandra-Mangala",
	Category:    "Wealth",
	Description: "Moon and Mars conjunct in the same sign — prosperity from one's own efforts and possible volatility in finances.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		pm := planetMap(c)
		moon, mok := pm["Moon"]
		mars, marok := pm["Mars"]
		if !mok || !marok {
			return false, 0, nil
		}
		if moon.Sign == mars.Sign {
			return true, 0.7, []string{"Moon", "Mars"}
		}
		return false, 0, nil
	},
}

var kemadrumaYoga = yogaRule{
	Name:        "Kemadruma",
	Sanskrit:    "Kemadruma",
	Category:    "Lunar",
	Description: "No planets (excluding Sun, Rahu, Ketu) in the houses adjacent to the Moon — challenges with mental peace and material support; cancelled if Moon is in a kendra from Lagna or has aspects.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		moon := houseOf(c, "Moon")
		if moon == 0 {
			return false, 0, nil
		}
		prev := ((moon - 2 + 12) % 12) + 1
		next := (moon % 12) + 1
		exclude := map[string]bool{"Sun": true, "Rahu": true, "Ketu": true, "Moon": true}
		empty := func(h int) bool {
			for _, name := range planetsInHouse(c, h) {
				if !exclude[name] {
					return false
				}
			}
			return true
		}
		if !empty(prev) || !empty(next) {
			return false, 0, nil
		}
		// Cancellation: Moon in kendra from Lagna (Lagna is 1st bhava).
		if isKendra(moon) {
			return false, 0, nil
		}
		return true, 0.6, []string{"Moon"}
	},
}

var kalaSarpa = yogaRule{
	Name:        "Kala Sarpa",
	Sanskrit:    "Kala Sarpa",
	Category:    "Nodal",
	Description: "All seven traditional planets fall on one side of the Rahu-Ketu axis — karmic intensity and concentrated life themes.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		pm := planetMap(c)
		rahu, rok := pm["Rahu"]
		ketu, kok := pm["Ketu"]
		if !rok || !kok {
			return false, 0, nil
		}
		// Use Rahu's longitude as the boundary; check if all seven traditional
		// grahas are within (Rahu, Ketu) arc going one way.
		rahuLon := rahu.Longitude
		// Direction: walk +180° from Rahu and see if every planet is in that arc.
		inArc := func(start, lon float64) bool {
			diff := normalize360(lon - start)
			return diff >= 0 && diff <= 180
		}
		traditional := []string{"Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"}
		allOneSide := true
		for _, name := range traditional {
			p, ok := pm[name]
			if !ok {
				continue
			}
			if !inArc(rahuLon, p.Longitude) {
				allOneSide = false
				break
			}
		}
		if allOneSide {
			return true, 0.9, []string{"Rahu", "Ketu"}
		}
		// Try the other direction from Ketu.
		ketuLon := ketu.Longitude
		allOneSide = true
		for _, name := range traditional {
			p, ok := pm[name]
			if !ok {
				continue
			}
			if !inArc(ketuLon, p.Longitude) {
				allOneSide = false
				break
			}
		}
		if allOneSide {
			return true, 0.9, []string{"Rahu", "Ketu"}
		}
		return false, 0, nil
	},
}

var nipuna = yogaRule{
	Name:        "Saraswati",
	Sanskrit:    "Saraswati",
	Category:    "Wisdom",
	Description: "Mercury, Jupiter, and Venus all in kendra, trikona, or 2nd house from Lagna — exceptional learning, eloquence, and the arts.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		pm := planetMap(c)
		ok := func(h int) bool { return isKendra(h) || isTrikona(h) || h == 2 }
		me, mok := pm["Mercury"]
		ju, jok := pm["Jupiter"]
		ve, vok := pm["Venus"]
		if !mok || !jok || !vok {
			return false, 0, nil
		}
		if ok(me.House) && ok(ju.House) && ok(ve.House) {
			return true, 0.85, []string{"Mercury", "Jupiter", "Venus"}
		}
		return false, 0, nil
	},
}

var lakshmiYoga = yogaRule{
	Name:        "Lakshmi",
	Sanskrit:    "Lakshmi",
	Category:    "Wealth",
	Description: "Lord of 9th in own/exalted sign in a kendra/trikona, AND Venus is well-placed — wealth, beauty, and prosperity.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		// 9th sign from Lagna.
		ascSignIdx := 0
		for i, s := range signs {
			if s == c.Lagna.Sign {
				ascSignIdx = i
				break
			}
		}
		ninthSign := signs[(ascSignIdx+8)%12]
		ninthLord := signLord[ninthSign]
		pm := planetMap(c)
		nl, ok := pm[ninthLord]
		if !ok {
			return false, 0, nil
		}
		if (nl.Dignity != "own" && nl.Dignity != "exalted" && nl.Dignity != "mooltrikona") || (!isKendra(nl.House) && !isTrikona(nl.House)) {
			return false, 0, nil
		}
		ve, vok := pm["Venus"]
		if !vok || isDushtana(ve.House) {
			return false, 0, nil
		}
		return true, 0.85, []string{ninthLord, "Venus"}
	},
}

var rajaYoga = yogaRule{
	Name:        "Raja Yoga",
	Sanskrit:    "Raja",
	Category:    "Power",
	Description: "Lord of a kendra (1, 4, 7, 10) and lord of a trikona (1, 5, 9) connected by conjunction or mutual aspect — bestows authority, success, and reputation.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		ascSignIdx := 0
		for i, s := range signs {
			if s == c.Lagna.Sign {
				ascSignIdx = i
				break
			}
		}
		kendraLords := map[string]bool{}
		trikonaLords := map[string]bool{}
		for _, h := range []int{1, 4, 7, 10} {
			kendraLords[signLord[signs[(ascSignIdx+h-1)%12]]] = true
		}
		for _, h := range []int{1, 5, 9} {
			trikonaLords[signLord[signs[(ascSignIdx+h-1)%12]]] = true
		}
		pm := planetMap(c)
		participants := make([]string, 0)
		for k := range kendraLords {
			for t := range trikonaLords {
				if k == t {
					continue
				}
				kp, kok := pm[k]
				tp, tok := pm[t]
				if !kok || !tok {
					continue
				}
				// conjunction (same sign) OR mutual 7th-aspect (same house dist 7).
				if kp.Sign == tp.Sign {
					participants = append(participants, k, t)
				} else if houseDistance(kp.House, tp.House) == 7 {
					participants = append(participants, k, t)
				}
			}
		}
		if len(participants) == 0 {
			return false, 0, nil
		}
		// Dedup
		seen := map[string]bool{}
		uniq := make([]string, 0, len(participants))
		for _, p := range participants {
			if !seen[p] {
				seen[p] = true
				uniq = append(uniq, p)
			}
		}
		return true, 0.8, uniq
	},
}

var dhanaYoga = yogaRule{
	Name:        "Dhana Yoga",
	Sanskrit:    "Dhana",
	Category:    "Wealth",
	Description: "Lords of the 2nd and 11th houses connected (conjunction or mutual aspect) — accumulation of wealth and gains.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		ascSignIdx := 0
		for i, s := range signs {
			if s == c.Lagna.Sign {
				ascSignIdx = i
				break
			}
		}
		secondLord := signLord[signs[(ascSignIdx+1)%12]]
		eleventhLord := signLord[signs[(ascSignIdx+10)%12]]
		if secondLord == eleventhLord {
			return false, 0, nil
		}
		pm := planetMap(c)
		s, sok := pm[secondLord]
		e, eok := pm[eleventhLord]
		if !sok || !eok {
			return false, 0, nil
		}
		if s.Sign == e.Sign || houseDistance(s.House, e.House) == 7 {
			return true, 0.75, []string{secondLord, eleventhLord}
		}
		return false, 0, nil
	},
}

var vipreetaRaja = yogaRule{
	Name:        "Vipreeta Raja",
	Sanskrit:    "Vipareeta Raja",
	Category:    "Power",
	Description: "Lord of one dushtana (6, 8, or 12) sits in another dushtana — paradoxical rise after struggle, success through adversity.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		ascSignIdx := 0
		for i, s := range signs {
			if s == c.Lagna.Sign {
				ascSignIdx = i
				break
			}
		}
		dushHouses := []int{6, 8, 12}
		participants := []string{}
		for _, h := range dushHouses {
			lord := signLord[signs[(ascSignIdx+h-1)%12]]
			lh := houseOf(c, lord)
			if isDushtana(lh) {
				participants = append(participants, lord)
			}
		}
		if len(participants) >= 2 {
			return true, 0.7, participants
		}
		return false, 0, nil
	},
}

var neechaBhanga = yogaRule{
	Name:        "Neecha Bhanga Raja",
	Sanskrit:    "Neecha Bhanga Raja",
	Category:    "Power",
	Description: "A debilitated planet's debility is cancelled (e.g., the lord of the debilitation sign is in a kendra from Lagna) — adversity transforms into elevation.",
	Check: func(c *domain.VedicChart) (bool, float64, []string) {
		pm := planetMap(c)
		participants := []string{}
		for _, p := range c.Planets {
			if p.Dignity != "debilitated" {
				continue
			}
			// Cancellation: lord of the debilitation sign is in a kendra from Lagna.
			lord := signLord[p.Sign]
			if lord == "" {
				continue
			}
			if lp, ok := pm[lord]; ok && isKendra(lp.House) {
				participants = append(participants, p.Name)
			}
		}
		if len(participants) > 0 {
			return true, 0.75, participants
		}
		return false, 0, nil
	},
}

// ===== Yoga registry =====

var yogaRegistry = []yogaRule{
	panchaMahapurusha("Mars", "Ruchaka", "Ruchaka"),
	panchaMahapurusha("Mercury", "Bhadra", "Bhadra"),
	panchaMahapurusha("Jupiter", "Hamsa", "Hamsa"),
	panchaMahapurusha("Venus", "Malavya", "Malavya"),
	panchaMahapurusha("Saturn", "Sasa", "Sasa"),
	gajakesari,
	budhAditya,
	chandraMangala,
	kemadrumaYoga,
	kalaSarpa,
	nipuna, // Saraswati
	lakshmiYoga,
	rajaYoga,
	dhanaYoga,
	vipreetaRaja,
	neechaBhanga,
}

// ComputeYogas runs every yoga rule against the chart and returns those that
// are active.
func (c *Client) ComputeYogas(chart *domain.VedicChart) []domain.VedicYoga {
	out := make([]domain.VedicYoga, 0, len(yogaRegistry))
	for _, rule := range yogaRegistry {
		active, strength, planets := rule.Check(chart)
		out = append(out, domain.VedicYoga{
			Name:        rule.Name,
			Sanskrit:    rule.Sanskrit,
			Category:    rule.Category,
			Description: rule.Description,
			Active:      active,
			Strength:    round2(strength),
			Planets:     planets,
		})
	}
	return out
}
