// Command gen-interpretations generates the long-form Matrix of Destiny arcana
// interpretations ONCE and writes them to interpretations.json, which the
// backend embeds and serves. Because an arcana's meaning is universal, this is
// a build-time/offline step — it is never run per request or per user.
//
// Usage (from the go_backend directory):
//
//	OPENAI_API_KEY=sk-... go run ./cmd/gen-interpretations
//
// Optional first arg overrides the output path (defaults to the embedded file).
// Re-running overwrites the file; commit the result.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"cosmic-mirror/internal/destinymatrix"
	"cosmic-mirror/internal/provider/openai"
)

const defaultOutPath = "internal/destinymatrix/interpretations.json"

const systemPrompt = "You are a warm, precise guide writing Matrix of Destiny readings based on the 22 Major Arcana. " +
	"Write in the second person ('you'), grounded and encouraging, never flowery or doom-laden. " +
	"Return ONLY the interpretation text: no headings, no markdown, no lists, 3-4 sentences, about 60-90 words."

func main() {
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "error: OPENAI_API_KEY is required")
		os.Exit(1)
	}

	outPath := defaultOutPath
	if len(os.Args) > 1 {
		outPath = os.Args[1]
	}

	client := openai.NewClient(apiKey)
	ctx := context.Background()

	result := make(map[string]string, 22)
	for n := 1; n <= 22; n++ {
		name, base := destinymatrix.Arcana(n)
		user := fmt.Sprintf(
			"Arcana %d is %q. Its short meaning is: %s\n\n"+
				"Write a detailed interpretation of arcana %d (%s) as it appears on someone's "+
				"Matrix of Destiny octagram. Cover its core energy, its gifts, and the growth "+
				"lesson it brings. The text is shown when a user taps any position holding this "+
				"number, so keep it about the arcana itself (universal), not any one position.",
			n, name, base, n, name,
		)

		fmt.Printf("generating %2d/22  %s\n", n, name)
		text, err := client.ChatCompletion(ctx, []openai.Message{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: user},
		})
		if err != nil {
			fmt.Fprintf(os.Stderr, "error: arcana %d (%s): %v\n", n, name, err)
			os.Exit(1)
		}
		result[strconv.Itoa(n)] = strings.TrimSpace(text)
		time.Sleep(300 * time.Millisecond) // gentle pacing
	}

	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: marshal: %v\n", err)
		os.Exit(1)
	}
	data = append(data, '\n')
	if err := os.WriteFile(outPath, data, 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "error: write %s: %v\n", outPath, err)
		os.Exit(1)
	}

	fmt.Printf("\nwrote %d interpretations to %s\n", len(result), outPath)
	fmt.Println("commit the file; the server embeds and serves it.")
}
