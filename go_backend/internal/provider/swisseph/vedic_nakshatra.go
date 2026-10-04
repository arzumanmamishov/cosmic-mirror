package swisseph

import "cosmic-mirror/internal/domain"

// nakshatraSpan is 360° / 27 = 13°20' = 13.333... per nakshatra.
const nakshatraSpan = 360.0 / 27.0

// padaSpan is one quarter of a nakshatra: 13°20' / 4 = 3°20'.
const padaSpan = nakshatraSpan / 4

// nakshatraData is the full table of 27 lunar mansions in canonical order
// starting from Ashwini (0° Aries sidereal). Source: Brihat Parashara
// Hora Shastra (BPHS) plus traditional commentary.
//
// The Vimshottari Dasha cycle (see vedic_dasha.go) uses the Ruler field as
// the dasha lord for each segment.
var nakshatraData = [27]domain.VedicNakshatra{
	{Index: 1, Name: "Ashwini", Ruler: "Ketu", Deity: "Ashwini Kumaras", Symbol: "Horse's head", Gana: "Deva", Nadi: "Adi", Varna: "Vaishya", Animal: "Horse (male)", Gender: "male", Caste: "Vaishya"},
	{Index: 2, Name: "Bharani", Ruler: "Venus", Deity: "Yama", Symbol: "Yoni / vagina", Gana: "Manushya", Nadi: "Madhya", Varna: "Mleccha", Animal: "Elephant (male)", Gender: "female", Caste: "Mleccha"},
	{Index: 3, Name: "Krittika", Ruler: "Sun", Deity: "Agni", Symbol: "Razor / flame", Gana: "Rakshasa", Nadi: "Antya", Varna: "Brahmin", Animal: "Sheep (female)", Gender: "female", Caste: "Brahmin"},
	{Index: 4, Name: "Rohini", Ruler: "Moon", Deity: "Brahma / Prajapati", Symbol: "Chariot / banyan tree", Gana: "Manushya", Nadi: "Antya", Varna: "Shudra", Animal: "Serpent (male)", Gender: "female", Caste: "Shudra"},
	{Index: 5, Name: "Mrigashira", Ruler: "Mars", Deity: "Soma / Chandra", Symbol: "Deer's head", Gana: "Deva", Nadi: "Madhya", Varna: "Kshatriya", Animal: "Serpent (female)", Gender: "neutral", Caste: "Kshatriya"},
	{Index: 6, Name: "Ardra", Ruler: "Rahu", Deity: "Rudra", Symbol: "Teardrop / diamond", Gana: "Manushya", Nadi: "Adi", Varna: "Butcher", Animal: "Dog (female)", Gender: "female", Caste: "Mleccha"},
	{Index: 7, Name: "Punarvasu", Ruler: "Jupiter", Deity: "Aditi", Symbol: "Bow & quiver", Gana: "Deva", Nadi: "Adi", Varna: "Vaishya", Animal: "Cat (female)", Gender: "male", Caste: "Vaishya"},
	{Index: 8, Name: "Pushya", Ruler: "Saturn", Deity: "Brihaspati", Symbol: "Cow's udder / lotus", Gana: "Deva", Nadi: "Madhya", Varna: "Kshatriya", Animal: "Goat (male)", Gender: "male", Caste: "Kshatriya"},
	{Index: 9, Name: "Ashlesha", Ruler: "Mercury", Deity: "Naga / serpent", Symbol: "Coiled serpent", Gana: "Rakshasa", Nadi: "Antya", Varna: "Mleccha", Animal: "Cat (male)", Gender: "female", Caste: "Mleccha"},
	{Index: 10, Name: "Magha", Ruler: "Ketu", Deity: "Pitris (ancestors)", Symbol: "Royal throne", Gana: "Rakshasa", Nadi: "Antya", Varna: "Shudra", Animal: "Rat (male)", Gender: "female", Caste: "Shudra"},
	{Index: 11, Name: "Purva Phalguni", Ruler: "Venus", Deity: "Bhaga", Symbol: "Front of bed / hammock", Gana: "Manushya", Nadi: "Madhya", Varna: "Brahmin", Animal: "Rat (female)", Gender: "female", Caste: "Brahmin"},
	{Index: 12, Name: "Uttara Phalguni", Ruler: "Sun", Deity: "Aryaman", Symbol: "Back of bed", Gana: "Manushya", Nadi: "Adi", Varna: "Kshatriya", Animal: "Cow (male)", Gender: "female", Caste: "Kshatriya"},
	{Index: 13, Name: "Hasta", Ruler: "Moon", Deity: "Savitr / Surya", Symbol: "Hand", Gana: "Deva", Nadi: "Adi", Varna: "Vaishya", Animal: "Buffalo (female)", Gender: "male", Caste: "Vaishya"},
	{Index: 14, Name: "Chitra", Ruler: "Mars", Deity: "Vishvakarma / Tvashtar", Symbol: "Bright jewel / pearl", Gana: "Rakshasa", Nadi: "Madhya", Varna: "Mleccha", Animal: "Tigress", Gender: "female", Caste: "Mleccha"},
	{Index: 15, Name: "Swati", Ruler: "Rahu", Deity: "Vayu", Symbol: "Sapling moving in wind", Gana: "Deva", Nadi: "Antya", Varna: "Butcher", Animal: "Buffalo (male)", Gender: "female", Caste: "Mleccha"},
	{Index: 16, Name: "Vishakha", Ruler: "Jupiter", Deity: "Indra & Agni", Symbol: "Triumphal arch / potter's wheel", Gana: "Rakshasa", Nadi: "Antya", Varna: "Mleccha", Animal: "Tiger (male)", Gender: "female", Caste: "Mleccha"},
	{Index: 17, Name: "Anuradha", Ruler: "Saturn", Deity: "Mitra", Symbol: "Lotus / staff", Gana: "Deva", Nadi: "Madhya", Varna: "Shudra", Animal: "Deer (female)", Gender: "male", Caste: "Shudra"},
	{Index: 18, Name: "Jyeshtha", Ruler: "Mercury", Deity: "Indra", Symbol: "Earring / umbrella", Gana: "Rakshasa", Nadi: "Adi", Varna: "Servant", Animal: "Deer (male)", Gender: "female", Caste: "Mleccha"},
	{Index: 19, Name: "Mula", Ruler: "Ketu", Deity: "Nirriti", Symbol: "Bunch of roots", Gana: "Rakshasa", Nadi: "Adi", Varna: "Butcher", Animal: "Dog (male)", Gender: "neutral", Caste: "Mleccha"},
	{Index: 20, Name: "Purva Ashadha", Ruler: "Venus", Deity: "Apas / waters", Symbol: "Elephant tusk / fan", Gana: "Manushya", Nadi: "Madhya", Varna: "Brahmin", Animal: "Monkey (male)", Gender: "female", Caste: "Brahmin"},
	{Index: 21, Name: "Uttara Ashadha", Ruler: "Sun", Deity: "Vishvedevas", Symbol: "Elephant tusk / planks of bed", Gana: "Manushya", Nadi: "Antya", Varna: "Kshatriya", Animal: "Mongoose (male)", Gender: "female", Caste: "Kshatriya"},
	{Index: 22, Name: "Shravana", Ruler: "Moon", Deity: "Vishnu", Symbol: "Ear / three footprints", Gana: "Deva", Nadi: "Antya", Varna: "Mleccha", Animal: "Monkey (female)", Gender: "male", Caste: "Mleccha"},
	{Index: 23, Name: "Dhanishta", Ruler: "Mars", Deity: "Eight Vasus", Symbol: "Drum / flute", Gana: "Rakshasa", Nadi: "Madhya", Varna: "Servant", Animal: "Lion (female)", Gender: "female", Caste: "Mleccha"},
	{Index: 24, Name: "Shatabhisha", Ruler: "Rahu", Deity: "Varuna", Symbol: "Empty circle / 100 stars", Gana: "Rakshasa", Nadi: "Adi", Varna: "Butcher", Animal: "Horse (female)", Gender: "neutral", Caste: "Mleccha"},
	{Index: 25, Name: "Purva Bhadrapada", Ruler: "Jupiter", Deity: "Aja Ekapada", Symbol: "Front of funeral cot / two-faced man", Gana: "Manushya", Nadi: "Adi", Varna: "Brahmin", Animal: "Lion (male)", Gender: "male", Caste: "Brahmin"},
	{Index: 26, Name: "Uttara Bhadrapada", Ruler: "Saturn", Deity: "Ahir Budhnya", Symbol: "Back of funeral cot / serpent in deep water", Gana: "Manushya", Nadi: "Madhya", Varna: "Kshatriya", Animal: "Cow (female)", Gender: "male", Caste: "Kshatriya"},
	{Index: 27, Name: "Revati", Ruler: "Mercury", Deity: "Pushan", Symbol: "Fish / drum", Gana: "Deva", Nadi: "Antya", Varna: "Shudra", Animal: "Elephant (female)", Gender: "female", Caste: "Shudra"},
}

// nakshatraOf returns the lunar mansion containing the given sidereal longitude.
// The longitude must already be in the sidereal frame.
func nakshatraOf(siderealLongitude float64) domain.VedicNakshatra {
	idx := int(normalize360(siderealLongitude) / nakshatraSpan)
	if idx < 0 {
		idx = 0
	}
	if idx > 26 {
		idx = 26
	}
	return nakshatraData[idx]
}

// padaOf returns the quarter (1..4) of the nakshatra that the given sidereal
// longitude falls in.
func padaOf(siderealLongitude float64) int {
	lon := normalize360(siderealLongitude)
	withinNak := lon - float64(int(lon/nakshatraSpan))*nakshatraSpan
	pada := int(withinNak/padaSpan) + 1
	if pada < 1 {
		pada = 1
	}
	if pada > 4 {
		pada = 4
	}
	return pada
}

// ===== Localization =====
//
// Sanskrit proper names (nakshatra names, deities, gana, nadi) stay
// transliterated; descriptive attributes (symbols, animals, gender and the
// English-worded varna/caste values) get a Turkish rendering. Tables are
// indexed by nakshatra Index-1 (deity/symbol) or keyed by the English value
// (animal, varna/caste, gender). Missing entries fall back to English.

type nakshatraTextTR struct {
	Deity  string
	Symbol string
}

var nakshatraTR = [27]nakshatraTextTR{
	{Deity: "Ashwini Kumaras", Symbol: "At başı"},
	{Deity: "Yama", Symbol: "Yoni / rahim"},
	{Deity: "Agni", Symbol: "Ustura / alev"},
	{Deity: "Brahma / Prajapati", Symbol: "At arabası / banyan ağacı"},
	{Deity: "Soma / Chandra", Symbol: "Geyik başı"},
	{Deity: "Rudra", Symbol: "Gözyaşı damlası / elmas"},
	{Deity: "Aditi", Symbol: "Yay ve sadak"},
	{Deity: "Brihaspati", Symbol: "İnek memesi / lotus"},
	{Deity: "Naga / yılan", Symbol: "Çöreklenmiş yılan"},
	{Deity: "Pitris (atalar)", Symbol: "Kraliyet tahtı"},
	{Deity: "Bhaga", Symbol: "Yatağın ön ayakları / hamak"},
	{Deity: "Aryaman", Symbol: "Yatağın arka ayakları"},
	{Deity: "Savitr / Surya", Symbol: "El"},
	{Deity: "Vishvakarma / Tvashtar", Symbol: "Parlak mücevher / inci"},
	{Deity: "Vayu", Symbol: "Rüzgârda salınan fidan"},
	{Deity: "Indra ve Agni", Symbol: "Zafer takı / çömlekçi çarkı"},
	{Deity: "Mitra", Symbol: "Lotus / asa"},
	{Deity: "Indra", Symbol: "Küpe / şemsiye"},
	{Deity: "Nirriti", Symbol: "Kök demeti"},
	{Deity: "Apas / sular", Symbol: "Fil dişi / yelpaze"},
	{Deity: "Vishvedevas", Symbol: "Fil dişi / yatak tahtaları"},
	{Deity: "Vishnu", Symbol: "Kulak / üç ayak izi"},
	{Deity: "Sekiz Vasu", Symbol: "Davul / flüt"},
	{Deity: "Varuna", Symbol: "Boş daire / 100 yıldız"},
	{Deity: "Aja Ekapada", Symbol: "Cenaze sedyesinin ön kısmı / iki yüzlü adam"},
	{Deity: "Ahir Budhnya", Symbol: "Cenaze sedyesinin arka kısmı / derin sulardaki yılan"},
	{Deity: "Pushan", Symbol: "Balık / davul"},
}

var nakshatraAnimalTR = map[string]string{
	"Horse (male)":      "At (erkek)",
	"Horse (female)":    "At (dişi)",
	"Elephant (male)":   "Fil (erkek)",
	"Elephant (female)": "Fil (dişi)",
	"Sheep (female)":    "Koyun (dişi)",
	"Serpent (male)":    "Yılan (erkek)",
	"Serpent (female)":  "Yılan (dişi)",
	"Dog (male)":        "Köpek (erkek)",
	"Dog (female)":      "Köpek (dişi)",
	"Cat (male)":        "Kedi (erkek)",
	"Cat (female)":      "Kedi (dişi)",
	"Goat (male)":       "Keçi (erkek)",
	"Rat (male)":        "Fare (erkek)",
	"Rat (female)":      "Fare (dişi)",
	"Cow (male)":        "Sığır (erkek)",
	"Cow (female)":      "Sığır (dişi)",
	"Buffalo (male)":    "Manda (erkek)",
	"Buffalo (female)":  "Manda (dişi)",
	"Tiger (male)":      "Kaplan (erkek)",
	"Tigress":           "Kaplan (dişi)",
	"Deer (male)":       "Geyik (erkek)",
	"Deer (female)":     "Geyik (dişi)",
	"Monkey (male)":     "Maymun (erkek)",
	"Monkey (female)":   "Maymun (dişi)",
	"Mongoose (male)":   "Firavunfaresi (erkek)",
	"Lion (male)":       "Aslan (erkek)",
	"Lion (female)":     "Aslan (dişi)",
}

// nakshatraVarnaTR covers both the Varna and Caste fields.
var nakshatraVarnaTR = map[string]string{
	"Brahmin":   "Brahman",
	"Kshatriya": "Kşatriya",
	"Vaishya":   "Vaişya",
	"Shudra":    "Şudra",
	"Mleccha":   "Mleccha",
	"Butcher":   "Kasap",
	"Servant":   "Hizmetkâr",
}

var nakshatraGenderTR = map[string]string{
	"male":    "eril",
	"female":  "dişil",
	"neutral": "nötr",
}

func trOr(table map[string]string, en string) string {
	if t := table[en]; t != "" {
		return t
	}
	return en
}

// LocalizeNakshatra returns a copy of n with its descriptive attributes
// rendered in lang ("tr"; anything else returns n unchanged). Name, Ruler,
// Gana and Nadi are never altered.
func LocalizeNakshatra(lang string, n domain.VedicNakshatra) domain.VedicNakshatra {
	if lang != "tr" {
		return n
	}
	if n.Index >= 1 && n.Index <= len(nakshatraTR) {
		t := nakshatraTR[n.Index-1]
		if t.Deity != "" {
			n.Deity = t.Deity
		}
		if t.Symbol != "" {
			n.Symbol = t.Symbol
		}
	}
	n.Animal = trOr(nakshatraAnimalTR, n.Animal)
	n.Varna = trOr(nakshatraVarnaTR, n.Varna)
	n.Caste = trOr(nakshatraVarnaTR, n.Caste)
	n.Gender = trOr(nakshatraGenderTR, n.Gender)
	return n
}

// LocalizeVedicChart returns chart with every nakshatra (lagna + planets)
// localized to lang. For "en" (or unknown) it returns chart as-is; otherwise
// it returns a copy and never mutates the input, so cached English charts
// stay English.
func LocalizeVedicChart(lang string, chart *domain.VedicChart) *domain.VedicChart {
	if chart == nil || lang != "tr" {
		return chart
	}
	out := *chart
	out.Lagna.Nakshatra = LocalizeNakshatra(lang, chart.Lagna.Nakshatra)
	out.Planets = make([]domain.VedicPlanetPlacement, len(chart.Planets))
	for i, p := range chart.Planets {
		p.Nakshatra = LocalizeNakshatra(lang, p.Nakshatra)
		out.Planets[i] = p
	}
	return &out
}
