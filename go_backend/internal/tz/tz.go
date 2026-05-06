// Package tz centralises geo-coded IANA timezone resolution + historical
// UTC-offset lookup. Two operations matter for accurate astrology charts:
//
//  1. Map (lat, lon) → an IANA zone name like "Asia/Baku" or
//     "America/New_York". The places handler stores this name on the
//     user's birth profile.
//  2. Convert a saved zone name + a birth instant → the actual UTC offset
//     in effect AT THAT MOMENT. Go's time.LoadLocation reads the bundled
//     IANA tzdata, which already encodes Soviet decree time, USSR DST
//     1981–1991, US DST history, EU rule changes, etc.
//
// Without this, charts for any DST-historical or decree-time birth (Baku
// 1987, Moscow 1985, NYC 1942 wartime, ...) get the ascendant ~1.5
// signs wrong because the local→UT conversion uses the wrong offset.
package tz

import (
	"fmt"
	"sync"
	"time"

	"github.com/ringsaturn/tzf"
)

var (
	finderOnce sync.Once
	finder     tzf.F
	finderErr  error
)

// FromCoords returns the IANA timezone name (e.g. "Asia/Baku") covering
// the given coordinates. Falls back to "Etc/UTC" only on a hard failure
// (offshore / antarctic / lookup error) — for any inhabited location
// tzf returns the canonical name.
func FromCoords(lat, lon float64) string {
	f, err := initFinder()
	if err != nil || f == nil {
		return "Etc/UTC"
	}
	name := f.GetTimezoneName(lon, lat)
	if name == "" {
		return "Etc/UTC"
	}
	return name
}

// OffsetAt returns the UTC offset (in hours, may be fractional) that
// the given IANA zone has at the specified instant. Pass the local
// civil time at the place of birth — Go interprets it via the zone's
// historical rules and returns the offset that was active.
//
// Example: OffsetAt("Asia/Baku", 1987, time.June, 15, 13, 0) → 6.0
// (USSR decree time +1 plus 1987 summer DST +1 on top of standard +4).
func OffsetAt(tzName string, year int, month time.Month, day, hour, min int) float64 {
	loc, err := time.LoadLocation(tzName)
	if err != nil {
		return 0
	}
	at := time.Date(year, month, day, hour, min, 0, 0, loc)
	_, secs := at.Zone()
	return float64(secs) / 3600
}

// OffsetForBirth is a convenience wrapper for service callers that
// already have the parsed birth-profile fields.
func OffsetForBirth(tzName string, birthDate time.Time, hour, min int) float64 {
	return OffsetAt(tzName, birthDate.Year(), birthDate.Month(), birthDate.Day(), hour, min)
}

// initFinder lazily builds the tzf finder. The library bundles the
// timezone polygon shapefile so this is in-process — no network.
func initFinder() (tzf.F, error) {
	finderOnce.Do(func() {
		f, err := tzf.NewDefaultFinder()
		if err != nil {
			finderErr = fmt.Errorf("tzf init: %w", err)
			return
		}
		finder = f
	})
	return finder, finderErr
}
