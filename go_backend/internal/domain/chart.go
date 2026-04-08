package domain

type NatalChart struct {
	Planets  []PlanetPlacement `json:"planets"`
	Houses   []House           `json:"houses"`
	Aspects  []Aspect          `json:"aspects"`
	Elements map[string]float64 `json:"elements"`
}

type PlanetPlacement struct {
	Name       string  `json:"name"`
	Sign       string  `json:"sign"`
	House      int     `json:"house"`
	Degree     float64 `json:"degree"`
	Retrograde bool    `json:"retrograde"`
}

type House struct {
	Number      int    `json:"number"`
	Sign        string `json:"sign"`
	Degree      float64 `json:"degree"`
	Description string `json:"description,omitempty"`
}

type Aspect struct {
	Planet1 string  `json:"planet1"`
	Planet2 string  `json:"planet2"`
	Type    string  `json:"type"` // conjunction, opposition, trine, square, sextile
	Orb     float64 `json:"orb"`
}

type ChartSummary struct {
	SunSign            string `json:"sun_sign"`
	MoonSign           string `json:"moon_sign"`
	RisingSign         string `json:"rising_sign"`
	SunDescription     string `json:"sun_description"`
	MoonDescription    string `json:"moon_description"`
	RisingDescription  string `json:"rising_description"`
}

type TimelineForecast struct {
	Type    string           `json:"type"` // 30d, 3m, 12m
	Periods []ForecastPeriod `json:"periods"`
}

type ForecastPeriod struct {
	Title       string `json:"title"`
	DateRange   string `json:"date_range"`
	Description string `json:"description"`
	Energy      string `json:"energy"` // positive, neutral, challenging, intense
}

type YearlyForecast struct {
	Year     int              `json:"year"`
	Theme    string           `json:"theme"`
	Overview string           `json:"overview"`
	Quarters []QuarterForecast `json:"quarters"`
}

type QuarterForecast struct {
	Label       string `json:"label"`
	Description string `json:"description"`
}
