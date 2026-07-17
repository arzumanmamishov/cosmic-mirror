package service

import (
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
)

// Deterministic yearly + timeline forecasts. Used when OPENAI_API_KEY is
// not set so the endpoints stay functional. Transits are still real
// Swiss-Ephemeris output; only the narrative is templated instead of
// LLM-written.

// weight maps a transit event to a rough "importance" score. Outer
// planets to personal points score highest; ingresses/lunations are
// background. Higher = more likely to headline a period.
func eventWeight(e openai.TransitEventLite) int {
	w := 1
	switch e.Body {
	case "Pluto", "Neptune", "Uranus":
		w += 5
	case "Saturn":
		w += 4
	case "Jupiter":
		w += 3
	case "Chiron":
		w += 3
	case "Mars":
		w += 2
	}
	switch e.Aspect {
	case "conjunction":
		w += 3
	case "opposition", "square":
		w += 2
	case "trine", "sextile":
		w += 1
	}
	if e.NatalPoint == "Sun" || e.NatalPoint == "Moon" || e.NatalPoint == "Ascendant" || e.NatalPoint == "Midheaven" {
		w += 2
	}
	switch e.Type {
	case "lunation":
		w += 1
	case "retrograde":
		w += 1
	}
	return w
}

// energyFor classifies a period based on its dominant events.
func energyFor(events []openai.TransitEventLite) string {
	positive, challenging, intense := 0, 0, 0
	for _, e := range events {
		switch e.Aspect {
		case "square", "opposition":
			challenging += 2
			if e.Body == "Saturn" || e.Body == "Pluto" || e.Body == "Mars" {
				intense++
			}
		case "trine", "sextile":
			positive += 2
		case "conjunction":
			intense++
			if e.Body == "Jupiter" || e.Body == "Venus" {
				positive++
			}
		}
	}
	switch {
	case intense >= 2 && intense >= challenging:
		return "intense"
	case challenging > positive:
		return "challenging"
	case positive > challenging:
		return "positive"
	default:
		return "neutral"
	}
}

// eventPhrase turns an event into a second-person clause.
func eventPhrase(e openai.TransitEventLite, lang string) string {
	if lang == "tr" {
		return eventPhraseTR(e)
	}
	switch e.Type {
	case "ingress":
		return fmt.Sprintf("%s moves into %s, shifting the tone of that terrain", e.Body, e.Sign)
	case "lunation":
		if e.Phase == "new_moon" {
			return fmt.Sprintf("the new moon in %s opens a fresh chapter", e.Sign)
		}
		if e.Phase == "full_moon" {
			return fmt.Sprintf("the full moon in %s brings something to light", e.Sign)
		}
		return fmt.Sprintf("a %s lunation in %s marks the beat", e.Phase, e.Sign)
	case "retrograde":
		if e.Phase == "retrograde" {
			return fmt.Sprintf("%s stations retrograde — a period to revisit, not launch", e.Body)
		}
		if e.Phase == "direct" {
			return fmt.Sprintf("%s goes direct, releasing what had been held", e.Body)
		}
		return fmt.Sprintf("%s changes direction", e.Body)
	case "aspect":
		verb := aspectVerb(e.Aspect, lang)
		return fmt.Sprintf("%s %s your natal %s — %s", e.Body, e.Aspect, e.NatalPoint, verb)
	}
	if e.Description != "" {
		return e.Description
	}
	return fmt.Sprintf("%s activates the chart", e.Body)
}

func eventPhraseTR(e openai.TransitEventLite) string {
	body := trBody(e.Body)
	switch e.Type {
	case "ingress":
		return fmt.Sprintf("%s, %s burcuna geçiyor ve o alanın tonunu değiştiriyor", body, trSign(e.Sign))
	case "lunation":
		if e.Phase == "new_moon" {
			return fmt.Sprintf("%s burcundaki yeni ay yeni bir sayfa açıyor", trSign(e.Sign))
		}
		if e.Phase == "full_moon" {
			return fmt.Sprintf("%s burcundaki dolunay bir şeyi gün yüzüne çıkarıyor", trSign(e.Sign))
		}
		return fmt.Sprintf("%s burcunda bir ay evresi bu dönemin ritmini belirliyor", trSign(e.Sign))
	case "retrograde":
		if e.Phase == "retrograde" {
			return fmt.Sprintf("%s geri harekete geçiyor — başlatmaktan çok geri dönmek için bir dönem", body)
		}
		if e.Phase == "direct" {
			return fmt.Sprintf("%s ileri harekete dönüyor ve bekletilen enerji serbest kalıyor", body)
		}
		return fmt.Sprintf("%s yön değiştiriyor", body)
	case "aspect":
		return fmt.Sprintf("%s, doğum haritandaki %s ile %s — %s", body, trPoint(e.NatalPoint), trAspect(e.Aspect), aspectVerb(e.Aspect, "tr"))
	}
	if e.Description != "" {
		return e.Description
	}
	return fmt.Sprintf("%s harita üzerinde bir tetikleyici yaratıyor", body)
}

func aspectVerb(aspect string, lang string) string {
	if lang == "tr" {
		switch aspect {
		case "conjunction":
			return "iki enerji birleşiyor, hissedebilirsin"
		case "opposition":
			return "bir eksen dengelenmeni istiyor"
		case "square":
			return "büyümeyi tetikleyen bir sürtünme yaratıyor"
		case "trine":
			return "akışkan bir kanal açılıyor"
		case "sextile":
			return "harekete geçebileceğin bir fırsat sunuyor"
		}
		return "not düşülmeye değer bir an"
	}
	switch aspect {
	case "conjunction":
		return "a merging you can feel"
	case "opposition":
		return "an axis asks for balance"
	case "square":
		return "friction that pushes growth"
	case "trine":
		return "a smooth channel opens"
	case "sextile":
		return "an opportunity to act on"
	}
	return "a note worth marking"
}

func trBody(name string) string {
	switch name {
	case "Sun":
		return "Güneş"
	case "Moon":
		return "Ay"
	case "Mercury":
		return "Merkür"
	case "Venus":
		return "Venüs"
	case "Mars":
		return "Mars"
	case "Jupiter":
		return "Jüpiter"
	case "Saturn":
		return "Satürn"
	case "Uranus":
		return "Uranüs"
	case "Neptune":
		return "Neptün"
	case "Pluto":
		return "Plüton"
	case "Chiron":
		return "Chiron"
	}
	return name
}

func trSign(sign string) string {
	switch sign {
	case "Aries":
		return "Koç"
	case "Taurus":
		return "Boğa"
	case "Gemini":
		return "İkizler"
	case "Cancer":
		return "Yengeç"
	case "Leo":
		return "Aslan"
	case "Virgo":
		return "Başak"
	case "Libra":
		return "Terazi"
	case "Scorpio":
		return "Akrep"
	case "Sagittarius":
		return "Yay"
	case "Capricorn":
		return "Oğlak"
	case "Aquarius":
		return "Kova"
	case "Pisces":
		return "Balık"
	}
	return sign
}

func trPoint(point string) string {
	switch point {
	case "Sun":
		return "Güneşin"
	case "Moon":
		return "Ayın"
	case "Ascendant":
		return "Yükselenin"
	case "Midheaven":
		return "Tepe Noktan (MC)"
	case "Mercury":
		return "Merkürün"
	case "Venus":
		return "Venüsün"
	case "Mars":
		return "Marsın"
	case "Jupiter":
		return "Jüpiterin"
	case "Saturn":
		return "Satürnün"
	case "Uranus":
		return "Uranüsün"
	case "Neptune":
		return "Neptünün"
	case "Pluto":
		return "Plütonun"
	}
	return point
}

func trAspect(aspect string) string {
	switch aspect {
	case "conjunction":
		return "kavuşuyor"
	case "opposition":
		return "karşıt açı yapıyor"
	case "square":
		return "kare açı yapıyor"
	case "trine":
		return "üçgen açı yapıyor"
	case "sextile":
		return "altmışlık açı yapıyor"
	}
	return aspect
}

// pickHeadliners returns up to n events by weight, preserving date order.
func pickHeadliners(events []openai.TransitEventLite, n int) []openai.TransitEventLite {
	if len(events) <= n {
		return events
	}
	// Score, sort by score desc, take top n, then re-sort by date.
	type scored struct {
		e openai.TransitEventLite
		w int
		i int
	}
	all := make([]scored, len(events))
	for i, e := range events {
		all[i] = scored{e, eventWeight(e), i}
	}
	// simple partial selection sort, n is small
	for i := 0; i < n; i++ {
		best := i
		for j := i + 1; j < len(all); j++ {
			if all[j].w > all[best].w {
				best = j
			}
		}
		all[i], all[best] = all[best], all[i]
	}
	picked := all[:n]
	// restore chronological order
	for i := 0; i < len(picked); i++ {
		for j := i + 1; j < len(picked); j++ {
			if picked[j].i < picked[i].i {
				picked[i], picked[j] = picked[j], picked[i]
			}
		}
	}
	out := make([]openai.TransitEventLite, n)
	for i, s := range picked {
		out[i] = s.e
	}
	return out
}

// windowLabel formats a date range like "Jan 5 – Jan 19, 2026".
func windowLabel(start, end time.Time, lang string) string {
	if lang == "tr" {
		if start.Year() == end.Year() {
			return fmt.Sprintf("%d %s – %d %s %d",
				start.Day(), trMonth(start.Month()), end.Day(), trMonth(end.Month()), start.Year())
		}
		return fmt.Sprintf("%d %s %d – %d %s %d",
			start.Day(), trMonth(start.Month()), start.Year(),
			end.Day(), trMonth(end.Month()), end.Year())
	}
	if start.Year() == end.Year() {
		return fmt.Sprintf("%s – %s, %d",
			start.Format("Jan 2"), end.Format("Jan 2"), start.Year())
	}
	return fmt.Sprintf("%s, %d – %s, %d",
		start.Format("Jan 2"), start.Year(), end.Format("Jan 2"), end.Year())
}

func trMonth(m time.Month) string {
	switch m {
	case time.January:
		return "Ocak"
	case time.February:
		return "Şubat"
	case time.March:
		return "Mart"
	case time.April:
		return "Nisan"
	case time.May:
		return "Mayıs"
	case time.June:
		return "Haziran"
	case time.July:
		return "Temmuz"
	case time.August:
		return "Ağustos"
	case time.September:
		return "Eylül"
	case time.October:
		return "Ekim"
	case time.November:
		return "Kasım"
	case time.December:
		return "Aralık"
	}
	return m.String()
}

// splitPeriods divides a window into n roughly equal date buckets.
func splitPeriods(start, end time.Time, n int) [][2]time.Time {
	if n < 1 {
		n = 1
	}
	total := end.Sub(start)
	step := total / time.Duration(n)
	out := make([][2]time.Time, n)
	for i := 0; i < n; i++ {
		a := start.Add(step * time.Duration(i))
		b := start.Add(step * time.Duration(i+1))
		if i == n-1 {
			b = end
		}
		out[i] = [2]time.Time{a, b}
	}
	return out
}

// bucketEvents drops each event into whichever window contains its date.
func bucketEvents(events []openai.TransitEventLite, windows [][2]time.Time) [][]openai.TransitEventLite {
	buckets := make([][]openai.TransitEventLite, len(windows))
	for _, e := range events {
		d, err := time.Parse("2006-01-02", e.Date)
		if err != nil {
			continue
		}
		for i, w := range windows {
			if !d.Before(w[0]) && d.Before(w[1]) {
				buckets[i] = append(buckets[i], e)
				break
			}
			// tail-inclusive for the final window
			if i == len(windows)-1 && !d.Before(w[0]) && !d.After(w[1]) {
				buckets[i] = append(buckets[i], e)
				break
			}
		}
	}
	return buckets
}

// periodTitle produces a short title for a period from its headliner.
func periodTitle(events []openai.TransitEventLite, lang string) string {
	if len(events) == 0 {
		if lang == "tr" {
			return "Sabit Zemin"
		}
		return "Steady Ground"
	}
	head := events[0]
	best := head
	bestW := eventWeight(head)
	for _, e := range events[1:] {
		if w := eventWeight(e); w > bestW {
			best = e
			bestW = w
		}
	}
	if lang == "tr" {
		switch best.Type {
		case "aspect":
			return fmt.Sprintf("%s → %s", trBody(best.Body), trPoint(best.NatalPoint))
		case "ingress":
			return fmt.Sprintf("%s %s'ta", trBody(best.Body), trSign(best.Sign))
		case "lunation":
			if best.Phase == "new_moon" {
				return fmt.Sprintf("%s'ta Yeni Ay", trSign(best.Sign))
			}
			if best.Phase == "full_moon" {
				return fmt.Sprintf("%s'ta Dolunay", trSign(best.Sign))
			}
		case "retrograde":
			if best.Phase == "retrograde" {
				return fmt.Sprintf("%s Retro", trBody(best.Body))
			}
			if best.Phase == "direct" {
				return fmt.Sprintf("%s İleri Yönde", trBody(best.Body))
			}
		}
		if best.Description != "" {
			return best.Description
		}
		return trBody(best.Body)
	}
	switch best.Type {
	case "aspect":
		return fmt.Sprintf("%s to %s", best.Body, best.NatalPoint)
	case "ingress":
		return fmt.Sprintf("%s in %s", best.Body, best.Sign)
	case "lunation":
		if best.Phase == "new_moon" {
			return fmt.Sprintf("New Moon in %s", best.Sign)
		}
		if best.Phase == "full_moon" {
			return fmt.Sprintf("Full Moon in %s", best.Sign)
		}
	case "retrograde":
		if best.Phase == "retrograde" {
			return fmt.Sprintf("%s Retrograde", best.Body)
		}
		if best.Phase == "direct" {
			return fmt.Sprintf("%s Direct", best.Body)
		}
	}
	if best.Description != "" {
		return best.Description
	}
	return best.Body
}

// periodDescription weaves up to 3 headliner events into 2-3 sentences.
func periodDescription(events []openai.TransitEventLite, lang string) string {
	if len(events) == 0 {
		if lang == "tr" {
			return "Bu dönemde tam üzerinde büyük bir transit yok. Doğum haritanın sabit örüntüsü öne çıkıyor — pekiştirmek, ince ayar yapmak ve daha önce başlattığın şeyle kalmak için iyi bir aralık."
		}
		return "No major transits are exact in this window. The steady pattern of your natal chart holds — a good stretch to consolidate, refine, and stay with what you've already begun."
	}
	head := pickHeadliners(events, 3)
	var b strings.Builder
	if lang == "tr" {
		b.WriteString("Bu dönemi şekillendiren şey ")
	} else {
		b.WriteString("This window is shaped by ")
	}
	for i, e := range head {
		if i > 0 {
			if i == len(head)-1 {
				if lang == "tr" {
					b.WriteString(" ve ")
				} else {
					b.WriteString(", and ")
				}
			} else {
				b.WriteString(", ")
			}
		}
		b.WriteString(eventPhrase(e, lang))
	}
	b.WriteString(". ")
	b.WriteString(closingLine(head, lang))
	return b.String()
}

func closingLine(events []openai.TransitEventLite, lang string) string {
	e := energyFor(events)
	if lang == "tr" {
		switch e {
		case "positive":
			return "Momentum senden yana — üzerinde çalıştığın şeylere uzanabilirsin."
		case "challenging":
			return "Direnç göreceksin ama bunu heykel yontmak gibi düşün: sana karşı direnen şey aslında biçimi gösteriyor."
		case "intense":
			return "İçeriden yüksek sesli hissedilecek. Ritmi sabit tut ve gürültü dinmeden kalıcı bir karar verme."
		}
		return "Elini zorlayan bir şey yok — gözlemlemek, ayar yapmak ve yüzeye çıkana açık kalmak için iyi bir aralık."
	}
	switch e {
	case "positive":
		return "Momentum is with you — reach for the things you've been rehearsing."
	case "challenging":
		return "Expect resistance, but take it as sculpting: what pushes back is showing you the shape."
	case "intense":
		return "It will feel loud from the inside. Keep the pace steady and let the noise settle before deciding anything permanent."
	}
	return "Nothing forcing your hand — a good stretch to observe, adjust, and stay open to what surfaces."
}

// BuildDeterministicTimeline is the OpenAI-free fallback for GetTimeline.
func BuildDeterministicTimeline(
	events []openai.TransitEventLite,
	forecastType string,
	start, end time.Time,
	lang string,
) *domain.TimelineForecast {
	nPeriods := 4
	switch forecastType {
	case "12m":
		nPeriods = 6
	case "3m":
		nPeriods = 4
	case "30d":
		nPeriods = 3
	}
	windows := splitPeriods(start, end, nPeriods)
	buckets := bucketEvents(events, windows)

	periods := make([]domain.ForecastPeriod, 0, nPeriods)
	for i, w := range windows {
		periods = append(periods, domain.ForecastPeriod{
			Title:       periodTitle(buckets[i], lang),
			DateRange:   windowLabel(w[0], w[1].Add(-24*time.Hour), lang),
			Description: periodDescription(buckets[i], lang),
			Energy:      energyFor(buckets[i]),
		})
	}

	return &domain.TimelineForecast{Type: forecastType, Periods: periods}
}

// BuildDeterministicYearly is the OpenAI-free fallback for GetYearlyForecast.
func BuildDeterministicYearly(
	events []openai.TransitEventLite,
	year int,
	lang string,
) *domain.YearlyForecast {
	start := time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC)
	q1End := time.Date(year, 4, 1, 0, 0, 0, 0, time.UTC)
	q2End := time.Date(year, 7, 1, 0, 0, 0, 0, time.UTC)
	q3End := time.Date(year, 10, 1, 0, 0, 0, 0, time.UTC)
	yearEnd := time.Date(year+1, 1, 1, 0, 0, 0, 0, time.UTC)
	windows := [][2]time.Time{
		{start, q1End},
		{q1End, q2End},
		{q2End, q3End},
		{q3End, yearEnd},
	}
	buckets := bucketEvents(events, windows)

	q1Label := "Q1: January - March"
	q2Label := "Q2: April - June"
	q3Label := "Q3: July - September"
	q4Label := "Q4: October - December"
	if lang == "tr" {
		q1Label = "Ç1: Ocak - Mart"
		q2Label = "Ç2: Nisan - Haziran"
		q3Label = "Ç3: Temmuz - Eylül"
		q4Label = "Ç4: Ekim - Aralık"
	}
	quarters := []domain.QuarterForecast{
		{Label: q1Label, Description: quarterParagraph(buckets[0], lang)},
		{Label: q2Label, Description: quarterParagraph(buckets[1], lang)},
		{Label: q3Label, Description: quarterParagraph(buckets[2], lang)},
		{Label: q4Label, Description: quarterParagraph(buckets[3], lang)},
	}

	return &domain.YearlyForecast{
		Year:     year,
		Theme:    yearTheme(events, lang),
		Overview: yearOverview(events, year, lang),
		Quarters: quarters,
	}
}

func quarterParagraph(events []openai.TransitEventLite, lang string) string {
	if len(events) == 0 {
		if lang == "tr" {
			return "Büyük bir tam transitin olmadığı, daha sakin bir çeyrek. Bunu, komşu dönemlerin talep edeceklerini içselleştirmek için kullan — bu duraklama da yayın bir parçası."
		}
		return "A quieter quarter with no exact major transits. Use it to integrate what the surrounding stretches will demand — the pause is part of the arc."
	}
	head := pickHeadliners(events, 3)
	var b strings.Builder
	if lang == "tr" {
		b.WriteString("Bu aylar boyunca ")
	} else {
		b.WriteString("Across these months, ")
	}
	for i, e := range head {
		if i > 0 {
			if i == len(head)-1 {
				if lang == "tr" {
					b.WriteString(" ve ")
				} else {
					b.WriteString(", and ")
				}
			} else {
				b.WriteString(", ")
			}
		}
		b.WriteString(eventPhrase(e, lang))
	}
	b.WriteString(". ")
	b.WriteString(closingLine(head, lang))
	return b.String()
}

func yearTheme(events []openai.TransitEventLite, lang string) string {
	if len(events) == 0 {
		if lang == "tr" {
			return "Sabit Bir Entegrasyon"
		}
		return "Steady Integration"
	}
	best := events[0]
	bestW := eventWeight(best)
	for _, e := range events[1:] {
		if w := eventWeight(e); w > bestW {
			best = e
			bestW = w
		}
	}
	if lang == "tr" {
		switch best.Body {
		case "Pluto":
			return "Derin Dönüşüm"
		case "Neptune":
			return "Erime ve Yeniden Rüya"
		case "Uranus":
			return "Kırılma ve Yeniden İcat"
		case "Saturn":
			return "Kalıcı Olanı İnşa Etmek"
		case "Jupiter":
			return "Genişleme ve Fırsat"
		case "Chiron":
			return "Eski Yaranın İyileşmesi"
		}
		return "Hareketli Bir Yıl"
	}
	switch best.Body {
	case "Pluto":
		return "Deep Transformation"
	case "Neptune":
		return "Dissolving and Redreaming"
	case "Uranus":
		return "Breakthrough and Reinvention"
	case "Saturn":
		return "Building What Lasts"
	case "Jupiter":
		return "Expansion and Opportunity"
	case "Chiron":
		return "Healing the Old Wound"
	}
	return "A Year of Movement"
}

func yearOverview(events []openai.TransitEventLite, year int, lang string) string {
	if len(events) == 0 {
		if lang == "tr" {
			return fmt.Sprintf("%d, dış gezegenlerden doğum noktalarına büyük bir isabet almadığı için daha sakin bir yıl olarak açılıyor. Bunu içselleştirme zemini olarak kullan: son bölümü pekiştir, işleyeni ince ayarla ve bir sonraki büyük transit geldiğinde nasıl bir formda olmak istediğine hazırlan.", year)
		}
		return fmt.Sprintf("%d unfolds as a quieter year — no major outer-planet hits to your natal points. Treat it as ground to integrate on: consolidate the last chapter, refine what's working, and prepare the shape you want to be in when the next big transit arrives.", year)
	}
	head := pickHeadliners(events, 4)
	var b strings.Builder
	if lang == "tr" {
		b.WriteString(fmt.Sprintf("%d yılını şekillendiren şey ", year))
	} else {
		b.WriteString(fmt.Sprintf("%d is shaped by ", year))
	}
	for i, e := range head {
		if i > 0 {
			if i == len(head)-1 {
				if lang == "tr" {
					b.WriteString(" ve ")
				} else {
					b.WriteString(", and ")
				}
			} else {
				b.WriteString(", ")
			}
		}
		b.WriteString(eventPhrase(e, lang))
	}
	b.WriteString(". ")
	b.WriteString(closingLine(head, lang))
	if lang == "tr" {
		b.WriteString(" Aşağıdaki her çeyreği bu yayın bir bölümü olarak oku — transitler yıl boyunca üst üste biniyor ve serbest kalıyor; asıl önemli olan tek bir hafta değil, aradaki bağ.")
	} else {
		b.WriteString(" Read each quarter below as one chapter of the arc — the transits stack and release across the year, and the through-line is what matters more than any single week.")
	}
	return b.String()
}
