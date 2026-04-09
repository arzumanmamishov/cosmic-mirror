package astrologyapi

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"cosmic-mirror/internal/domain"
)

type Client struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

func NewClient(apiKey, baseURL string) *Client {
	return &Client{
		apiKey:  apiKey,
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// BirthDataRequest is the standard request body for most endpoints.
type BirthDataRequest struct {
	Day       int     `json:"day"`
	Month     int     `json:"month"`
	Year      int     `json:"year"`
	Hour      int     `json:"hour"`
	Min       int     `json:"min"`
	Lat       float64 `json:"lat"`
	Lon       float64 `json:"lon"`
	Tzone     float64 `json:"tzone"`
}

// --- Response types matching AstrologyAPI.com western endpoints ---

type PlanetResponse struct {
	Name               string  `json:"name"`
	FullDegree         float64 `json:"fullDegree"`
	NormDegree         float64 `json:"normDegree"`
	Speed              float64 `json:"speed"`
	IsRetro            string  `json:"isRetro"`
	Sign               string  `json:"sign"`
	House              int     `json:"house"`
}

type HouseResponse struct {
	House    int     `json:"house"`
	Sign     string  `json:"sign"`
	Degree   float64 `json:"degree"`
}

type AspectResponse struct {
	AspectingPlanet string  `json:"aspecting_planet"`
	AspectedPlanet  string  `json:"aspected_planet"`
	Type            string  `json:"type"`
	Orb             float64 `json:"orb"`
}

// GetNatalChart fetches the full natal chart from AstrologyAPI.
func (c *Client) GetNatalChart(ctx context.Context, birthDate time.Time, birthHour, birthMin int, lat, lon, tzone float64) (*domain.NatalChart, error) {
	reqBody := BirthDataRequest{
		Day:   birthDate.Day(),
		Month: int(birthDate.Month()),
		Year:  birthDate.Year(),
		Hour:  birthHour,
		Min:   birthMin,
		Lat:   lat,
		Lon:   lon,
		Tzone: tzone,
	}

	// Fetch planets, houses, and aspects in sequence
	planets, err := c.fetchPlanets(ctx, reqBody)
	if err != nil {
		return nil, fmt.Errorf("fetch planets: %w", err)
	}

	houses, err := c.fetchHouses(ctx, reqBody)
	if err != nil {
		return nil, fmt.Errorf("fetch houses: %w", err)
	}

	aspects, err := c.fetchAspects(ctx, reqBody)
	if err != nil {
		return nil, fmt.Errorf("fetch aspects: %w", err)
	}

	chart := &domain.NatalChart{
		Planets:  convertPlanets(planets),
		Houses:   convertHouses(houses),
		Aspects:  convertAspects(aspects),
		Elements: calculateElements(planets),
	}

	return chart, nil
}

func (c *Client) fetchPlanets(ctx context.Context, req BirthDataRequest) ([]PlanetResponse, error) {
	var planets []PlanetResponse
	if err := c.doRequest(ctx, "/western/planets", req, &planets); err != nil {
		return nil, err
	}
	return planets, nil
}

func (c *Client) fetchHouses(ctx context.Context, req BirthDataRequest) ([]HouseResponse, error) {
	var houses []HouseResponse
	if err := c.doRequest(ctx, "/western/houses", req, &houses); err != nil {
		return nil, err
	}
	return houses, nil
}

func (c *Client) fetchAspects(ctx context.Context, req BirthDataRequest) ([]AspectResponse, error) {
	var aspects []AspectResponse
	if err := c.doRequest(ctx, "/western/aspects", req, &aspects); err != nil {
		return nil, err
	}
	return aspects, nil
}

func (c *Client) doRequest(ctx context.Context, endpoint string, reqBody any, result any) error {
	body, err := json.Marshal(reqBody)
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	url := c.baseURL + endpoint
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return fmt.Errorf("http request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("astrologyapi returned status %d: %s", resp.StatusCode, string(respBody))
	}

	if err := json.Unmarshal(respBody, result); err != nil {
		return fmt.Errorf("unmarshal response: %w", err)
	}

	return nil
}

// --- Conversion helpers ---

func convertPlanets(planets []PlanetResponse) []domain.PlanetPlacement {
	result := make([]domain.PlanetPlacement, 0, len(planets))
	for _, p := range planets {
		result = append(result, domain.PlanetPlacement{
			Name:       p.Name,
			Sign:       p.Sign,
			House:      p.House,
			Degree:     p.NormDegree,
			Retrograde: p.IsRetro == "true",
		})
	}
	return result
}

func convertHouses(houses []HouseResponse) []domain.House {
	result := make([]domain.House, 0, len(houses))
	for _, h := range houses {
		result = append(result, domain.House{
			Number: h.House,
			Sign:   h.Sign,
			Degree: h.Degree,
		})
	}
	return result
}

func convertAspects(aspects []AspectResponse) []domain.Aspect {
	result := make([]domain.Aspect, 0, len(aspects))
	for _, a := range aspects {
		result = append(result, domain.Aspect{
			Planet1: a.AspectingPlanet,
			Planet2: a.AspectedPlanet,
			Type:    a.Type,
			Orb:     a.Orb,
		})
	}
	return result
}

var signElements = map[string]string{
	"Aries": "fire", "Leo": "fire", "Sagittarius": "fire",
	"Taurus": "earth", "Virgo": "earth", "Capricorn": "earth",
	"Gemini": "air", "Libra": "air", "Aquarius": "air",
	"Cancer": "water", "Scorpio": "water", "Pisces": "water",
}

func calculateElements(planets []PlanetResponse) map[string]float64 {
	counts := map[string]float64{"fire": 0, "earth": 0, "air": 0, "water": 0}
	for _, p := range planets {
		if el, ok := signElements[p.Sign]; ok {
			counts[el]++
		}
	}
	total := counts["fire"] + counts["earth"] + counts["air"] + counts["water"]
	if total == 0 {
		return counts
	}
	for k := range counts {
		counts[k] = counts[k] / total * 100
	}
	return counts
}
