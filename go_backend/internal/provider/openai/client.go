package openai

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

const apiURL = "https://api.openai.com/v1/chat/completions"

// ErrNotConfigured is returned by every request path when the client
// was constructed without an API key. Handlers can use errors.Is to
// distinguish this from a real upstream failure and return a stub or
// a friendly "AI features unavailable" response instead of a 500.
var ErrNotConfigured = errors.New("openai: OPENAI_API_KEY not set")

// Timeout budget. These must stay consistent with the HTTP server in
// cmd/server/main.go (WriteTimeout 90s): a request's whole LLM phase is
// capped at RequestBudget so the handler still has time to persist the
// result and write the response before the server cuts the connection.
const (
	// AttemptTimeout caps one HTTP round-trip to OpenAI (gpt-4o JSON
	// responses of ~2k tokens typically take 10–30s).
	AttemptTimeout = 40 * time.Second
	// RequestBudget caps all attempts plus backoff for one call.
	RequestBudget = 75 * time.Second
	// maxAttempts: the first try plus up to two retries on 429/5xx/network
	// errors, as far as RequestBudget allows.
	maxAttempts = 3
)

type Client struct {
	apiKey     string
	httpClient *http.Client
	model      string
	url        string // apiURL; overridable in tests
}

func NewClient(apiKey string) *Client {
	return &Client{
		apiKey: apiKey,
		httpClient: &http.Client{
			// Backstop only; each attempt also gets a context deadline.
			Timeout: AttemptTimeout,
		},
		model: "gpt-4o",
		url:   apiURL,
	}
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Model          string          `json:"model"`
	Messages       []Message       `json:"messages"`
	Temperature    float64         `json:"temperature"`
	MaxTokens      int             `json:"max_tokens,omitempty"`
	ResponseFormat *responseFormat `json:"response_format,omitempty"`
}

type responseFormat struct {
	Type string `json:"type"`
}

type chatResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func (c *Client) ChatCompletion(ctx context.Context, messages []Message) (string, error) {
	return c.doRequest(ctx, messages, 0.7, 1000, false)
}

func (c *Client) ChatCompletionJSON(ctx context.Context, messages []Message) (string, error) {
	return c.doRequest(ctx, messages, 0.6, 2000, true)
}

func (c *Client) doRequest(ctx context.Context, messages []Message, temp float64, maxTokens int, jsonMode bool) (string, error) {
	if c.apiKey == "" {
		return "", ErrNotConfigured
	}
	req := chatRequest{
		Model:       c.model,
		Messages:    messages,
		Temperature: temp,
		MaxTokens:   maxTokens,
	}
	if jsonMode {
		req.ResponseFormat = &responseFormat{Type: "json_object"}
	}

	body, err := json.Marshal(req)
	if err != nil {
		return "", fmt.Errorf("marshal request: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, RequestBudget)
	defer cancel()

	var lastErr error
	for attempt := 0; attempt < maxAttempts; attempt++ {
		if attempt > 0 {
			// Linear backoff (1s, 2s) that gives up as soon as the caller
			// goes away or the budget runs out.
			t := time.NewTimer(time.Duration(attempt) * time.Second)
			select {
			case <-ctx.Done():
				t.Stop()
				return "", fmt.Errorf("OpenAI request aborted after %d attempt(s): %w (last error: %v)",
					attempt, ctx.Err(), lastErr)
			case <-t.C:
			}
		}

		content, retryable, err := c.attempt(ctx, body)
		if err == nil {
			return content, nil
		}
		if !retryable || ctx.Err() != nil {
			return "", err
		}
		lastErr = err
	}

	return "", fmt.Errorf("OpenAI request failed after retries: %w", lastErr)
}

// attempt performs one HTTP round-trip. A fresh request (and body reader)
// is built every time — a retried *http.Request would resend an already
// drained body — and the response body is closed before returning rather
// than deferred until the whole retry loop ends.
func (c *Client) attempt(ctx context.Context, body []byte) (content string, retryable bool, err error) {
	ctx, cancel := context.WithTimeout(ctx, AttemptTimeout)
	defer cancel()

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, c.url, bytes.NewReader(body))
	if err != nil {
		return "", false, fmt.Errorf("create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return "", true, fmt.Errorf("OpenAI request: %w", err)
	}
	defer resp.Body.Close()

	// Cap what we read: a chat completion is a few KB.
	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return "", true, fmt.Errorf("read OpenAI response: %w", err)
	}

	if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
		return "", true, fmt.Errorf("OpenAI API returned status %d", resp.StatusCode)
	}

	var chatResp chatResponse
	if err := json.Unmarshal(respBody, &chatResp); err != nil {
		return "", false, fmt.Errorf("unmarshal response (status %d): %w", resp.StatusCode, err)
	}
	if chatResp.Error != nil {
		return "", false, fmt.Errorf("OpenAI error: %s", chatResp.Error.Message)
	}
	if len(chatResp.Choices) == 0 {
		return "", false, fmt.Errorf("no choices in response")
	}
	return chatResp.Choices[0].Message.Content, false, nil
}
