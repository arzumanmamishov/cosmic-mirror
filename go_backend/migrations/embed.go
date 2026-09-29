// Package migrations embeds the SQL migration files into the server
// binary so a deploy can never run code against a schema it didn't ship.
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
