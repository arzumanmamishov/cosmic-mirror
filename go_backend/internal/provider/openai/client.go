package openai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const apiURL = "https://api.openai.com/v1/chat/completions"

type Client struct {
	apiKey     string
	httpClient *http.Client
	model      string
}

func NewClient(apiKey string) *Client {
	return &Client{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
		model: "gpt-4o",
	}
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Model          string    `json:"model"`
	Messages       []Message `json:"messages"`
	Temperature    float64   `json:"temperature"`
	MaxTokens      int       `json:"max_tokens,omitempty"`
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

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)

	// Retry up to 2 times
	var lastErr error
	for attempt := 0; attempt < 3; attempt++ {
		if attempt > 0 {
			time.Sleep(time.Duration(attempt) * time.Second)
		}

		resp, err := c.httpClient.Do(httpReq)
		if err != nil {
			lastErr = err
			continue
		}
		defer resp.Body.Close()

		respBody, err := io.ReadAll(resp.Body)
		if err != nil {
			lastErr = err
			continue
		}

		if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
			lastErr = fmt.Errorf("OpenAI API returned status %d", resp.StatusCode)
			continue
		}

		var chatResp chatResponse
		if err := json.Unmarshal(respBody, &chatResp); err != nil {
			return "", fmt.Errorf("unmarshal response: %w", err)
		}

		if chatResp.Error != nil {
			return "", fmt.Errorf("OpenAI error: %s", chatResp.Error.Message)
		}

		if len(chatResp.Choices) == 0 {
			return "", fmt.Errorf("no choices in response")
		}

		return chatResp.Choices[0].Message.Content, nil
	}

	return "", fmt.Errorf("OpenAI request failed after retries: %w", lastErr)
}
