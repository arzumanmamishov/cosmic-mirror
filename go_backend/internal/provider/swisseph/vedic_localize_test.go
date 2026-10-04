package swisseph

import (
	"testing"

	"cosmic-mirror/internal/domain"
)

// TestNakshatraTurkishCompleteness asserts every English nakshatra attribute
// has a non-empty Turkish counterpart.
func TestNakshatraTurkishCompleteness(t *testing.T) {
	for i, n := range nakshatraData {
		tr := nakshatraTR[i]
		if n.Deity != "" && tr.Deity == "" {
			t.Errorf("nakshatraTR[%d] (%s) deity missing", i, n.Name)
		}
		if n.Symbol != "" && tr.Symbol == "" {
			t.Errorf("nakshatraTR[%d] (%s) symbol missing", i, n.Name)
		}
		if n.Animal != "" && nakshatraAnimalTR[n.Animal] == "" {
			t.Errorf("nakshatraAnimalTR[%q] missing", n.Animal)
		}
		if n.Varna != "" && nakshatraVarnaTR[n.Varna] == "" {
			t.Errorf("nakshatraVarnaTR[%q] (varna) missing", n.Varna)
		}
		if n.Caste != "" && nakshatraVarnaTR[n.Caste] == "" {
			t.Errorf("nakshatraVarnaTR[%q] (caste) missing", n.Caste)
		}
		if n.Gender != "" && nakshatraGenderTR[n.Gender] == "" {
			t.Errorf("nakshatraGenderTR[%q] missing", n.Gender)
		}
	}
}

// TestYogaTurkishCompleteness asserts every registered yoga has a Turkish
// description.
func TestYogaTurkishCompleteness(t *testing.T) {
	for _, r := range yogaRegistry {
		if r.Description != "" && yogaDescriptionTR[r.Name] == "" {
			t.Errorf("yogaDescriptionTR[%q] missing", r.Name)
		}
	}
	known := map[string]bool{}
	for _, r := range yogaRegistry {
		known[r.Name] = true
	}
	for name := range yogaDescriptionTR {
		if !known[name] {
			t.Errorf("yogaDescriptionTR has extra key %q", name)
		}
	}
}

func TestLocalizeVedicChartDoesNotMutate(t *testing.T) {
	chart := &domain.VedicChart{
		Lagna:   domain.VedicLagna{Nakshatra: nakshatraData[0]},
		Planets: []domain.VedicPlanetPlacement{{Name: "Moon", Nakshatra: nakshatraData[8]}},
	}
	if got := LocalizeVedicChart("en", chart); got != chart {
		t.Errorf("en should return the same chart")
	}
	tr := LocalizeVedicChart("tr", chart)
	if tr.Lagna.Nakshatra.Symbol != "At başı" || tr.Lagna.Nakshatra.Gender != "eril" {
		t.Errorf("lagna nakshatra not localized: %+v", tr.Lagna.Nakshatra)
	}
	if tr.Planets[0].Nakshatra.Deity != "Naga / yılan" || tr.Planets[0].Nakshatra.Name != "Ashlesha" {
		t.Errorf("planet nakshatra not localized: %+v", tr.Planets[0].Nakshatra)
	}
	if chart.Lagna.Nakshatra.Symbol != "Horse's head" || chart.Planets[0].Nakshatra.Deity != "Naga / serpent" {
		t.Errorf("input chart was mutated")
	}

	yogas := []domain.VedicYoga{{Name: "Gajakesari", Description: "en"}, {Name: "Unknown", Description: "keep"}}
	ly := LocalizeYogas("tr", yogas)
	if ly[0].Description == "en" || ly[1].Description != "keep" || yogas[0].Description != "en" {
		t.Errorf("LocalizeYogas wrong: %+v / input %+v", ly, yogas)
	}
}
