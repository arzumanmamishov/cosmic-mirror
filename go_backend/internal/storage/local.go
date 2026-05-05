// Package storage provides a tiny local-filesystem store for user-uploaded
// assets (currently just profile avatars). Files live under a base directory
// configured via UPLOADS_DIR (default /app/uploads inside the container) and
// are served back to clients via a static file route mounted at /uploads.
//
// Swap this out for an S3/GCS adapter later without changing the handlers —
// they only depend on the SaveAvatar / DeleteAvatar contract.
package storage

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// AvatarStore writes avatar files to a local directory and returns the
// public URL the API serves them at.
type AvatarStore struct {
	// BaseDir is the absolute filesystem path where files are written
	// (e.g. /app/uploads).
	BaseDir string
	// PublicPrefix is the URL prefix the static-file route is mounted at
	// (e.g. /uploads). The final URL returned to clients is
	// PublicPrefix + "/avatars/" + filename.
	PublicPrefix string
}

func NewAvatarStore(baseDir, publicPrefix string) *AvatarStore {
	return &AvatarStore{BaseDir: baseDir, PublicPrefix: publicPrefix}
}

// allowed extensions — keep narrow to avoid any image-format surprises.
var allowedExt = map[string]struct{}{
	".jpg":  {},
	".jpeg": {},
	".png":  {},
	".webp": {},
	".heic": {},
}

// SaveAvatar reads the upload from r, writes it to disk under
// avatars/{userID}_{ts}{ext}, and returns the public URL. Old files for
// the same user are removed so we don't accumulate orphans.
func (s *AvatarStore) SaveAvatar(userID uuid.UUID, originalName string, r io.Reader) (string, error) {
	ext := strings.ToLower(filepath.Ext(originalName))
	if _, ok := allowedExt[ext]; !ok {
		return "", fmt.Errorf("unsupported file type %q", ext)
	}

	dir := filepath.Join(s.BaseDir, "avatars")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", fmt.Errorf("create avatar dir: %w", err)
	}

	if err := s.removeUserAvatars(userID); err != nil {
		// Non-fatal — log via returning, the next write still succeeds.
		// We don't want a stale-file error to block a successful upload.
		_ = err
	}

	filename := fmt.Sprintf(
		"%s_%d%s",
		userID.String(),
		time.Now().Unix(),
		ext,
	)
	dst, err := os.Create(filepath.Join(dir, filename))
	if err != nil {
		return "", fmt.Errorf("open dest: %w", err)
	}
	defer dst.Close()
	if _, err := io.Copy(dst, r); err != nil {
		return "", fmt.Errorf("write file: %w", err)
	}

	return fmt.Sprintf("%s/avatars/%s", s.PublicPrefix, filename), nil
}

// DeleteAvatar removes any avatar files belonging to userID.
func (s *AvatarStore) DeleteAvatar(userID uuid.UUID) error {
	return s.removeUserAvatars(userID)
}

func (s *AvatarStore) removeUserAvatars(userID uuid.UUID) error {
	dir := filepath.Join(s.BaseDir, "avatars")
	entries, err := os.ReadDir(dir)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		return err
	}
	prefix := userID.String() + "_"
	for _, e := range entries {
		if !e.IsDir() && strings.HasPrefix(e.Name(), prefix) {
			_ = os.Remove(filepath.Join(dir, e.Name()))
		}
	}
	return nil
}
