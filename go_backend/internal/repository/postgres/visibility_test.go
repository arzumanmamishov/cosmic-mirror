package postgres

import (
	"strings"
	"testing"
)

func TestNotBlockedSQLChecksBothDirections(t *testing.T) {
	got := notBlockedSQL("$1", "p.author_id")
	for _, want := range []string{
		"ub.blocker_id = $1 AND ub.blocked_id = p.author_id",
		"ub.blocker_id = p.author_id AND ub.blocked_id = $1",
		"NOT EXISTS",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("notBlockedSQL missing %q in:\n%s", want, got)
		}
	}
}

func TestVisibleContentSQL(t *testing.T) {
	got := visibleContentSQL("c", "u", "$1")
	for _, want := range []string{
		"c.hidden_at IS NULL OR c.author_id = $1", // authors still see their hidden content
		"u.banned_at IS NULL",
		"ub.blocked_id = c.author_id",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("visibleContentSQL missing %q in:\n%s", want, got)
		}
	}
}
