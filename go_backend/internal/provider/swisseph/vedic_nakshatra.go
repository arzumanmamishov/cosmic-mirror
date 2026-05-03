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
