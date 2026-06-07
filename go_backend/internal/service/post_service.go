package service

import (
	"context"
	"errors"
	"regexp"
	"strings"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type PostService struct {
	db          *sqlx.DB
	postRepo    *postgres.PostRepository
	spaceRepo   *postgres.SpaceRepository
	memberRepo  *postgres.SpaceMemberRepository
	hashtagRepo *postgres.HashtagRepository
	notifSvc    *CommunityNotificationService
}

func NewPostService(
	db *sqlx.DB,
	postRepo *postgres.PostRepository,
	spaceRepo *postgres.SpaceRepository,
	memberRepo *postgres.SpaceMemberRepository,
	hashtagRepo *postgres.HashtagRepository,
	notifSvc *CommunityNotificationService,
) *PostService {
	return &PostService{
		db: db, postRepo: postRepo, spaceRepo: spaceRepo,
		memberRepo: memberRepo, hashtagRepo: hashtagRepo, notifSvc: notifSvc,
	}
}

var (
	ErrPostNotFound = errors.New("post not found")
)

// hashtagRegex extracts hashtag tokens from post content. Matches `#word`
// where word is 1-50 chars of letters, digits, or underscore.
var hashtagRegex = regexp.MustCompile(`#(\w{1,50})`)

func extractHashtags(content string) []string {
	matches := hashtagRegex.FindAllStringSubmatch(content, -1)
	if len(matches) == 0 {
		return nil
	}
	out := make([]string, 0, len(matches))
	seen := make(map[string]struct{}, len(matches))
	for _, m := range matches {
		t := strings.ToLower(m[1])
		if _, ok := seen[t]; ok {
			continue
		}
		seen[t] = struct{}{}
		out = append(out, t)
	}
	return out
}

func (s *PostService) Create(ctx context.Context, userID, spaceID uuid.UUID, input domain.CreatePostInput) (*domain.Post, error) {
	if strings.TrimSpace(input.Content) == "" {
		return nil, errors.New("content is required")
	}
	// Posting requires approved membership — pending requesters can see
	// the space header but cannot write into it.
	approved, err := s.memberRepo.IsApprovedMember(ctx, spaceID, userID)
	if err != nil {
		return nil, err
	}
	if !approved {
		return nil, ErrForbidden
	}
	post := &domain.Post{
		SpaceID:  spaceID,
		AuthorID: userID,
		Content:  input.Content,
		LinkURL:  input.LinkURL,
	}

	err = postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		if err := s.postRepo.Create(ctx, tx, post); err != nil {
			return err
		}
		// Hashtag indexing
		if names := extractHashtags(post.Content); len(names) > 0 {
			ids, err := s.hashtagRepo.UpsertMany(ctx, tx, names)
			if err != nil {
				return err
			}
			if err := s.hashtagRepo.LinkPost(ctx, tx, post.ID, ids); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	// Fan out a "new post in space" notification to every other member.
	go s.fanOutNewPost(spaceID, post.ID, userID, post.Content)
	return post, nil
}

func (s *PostService) fanOutNewPost(spaceID, postID, actorID uuid.UUID, content string) {
	ctx := context.Background()
	memberIDs, err := s.memberRepo.ListSpaceMemberUserIDs(ctx, spaceID)
	if err != nil {
		return
	}
	snippet := truncateRunes(content, 140, "…")
	s.notifSvc.EmitMany(ctx, nil, memberIDs, EmitParams{
		ActorID:    &actorID,
		Type:       "post_in_space",
		TargetType: "post",
		TargetID:   postID,
		Snippet:    &snippet,
	})
}

func (s *PostService) Get(ctx context.Context, id, userID uuid.UUID) (*domain.PostWithMeta, error) {
	p, err := s.postRepo.GetByID(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPostNotFound
	}
	// Reading a single post requires approved membership in its space —
	// otherwise a non-member holding a post id could read gated content.
	approved, err := s.memberRepo.IsApprovedMember(ctx, p.SpaceID, userID)
	if err != nil {
		return nil, err
	}
	if !approved {
		return nil, ErrForbidden
	}
	return p, nil
}

func (s *PostService) ListBySpace(ctx context.Context, spaceID, userID uuid.UUID, limit, offset int) ([]domain.PostWithMeta, error) {
	// Reading a space's posts requires approved membership. Pending
	// requesters and non-members see ErrForbidden so the client can
	// render a "Request to join" CTA instead of an empty feed.
	approved, err := s.memberRepo.IsApprovedMember(ctx, spaceID, userID)
	if err != nil {
		return nil, err
	}
	if !approved {
		return nil, ErrForbidden
	}
	return s.postRepo.ListBySpace(ctx, spaceID, userID, limit, offset)
}

func (s *PostService) Update(ctx context.Context, id, userID uuid.UUID, input domain.UpdatePostInput) error {
	post, err := s.postRepo.GetBareByID(ctx, id)
	if err != nil {
		return err
	}
	if post == nil {
		return ErrPostNotFound
	}
	if post.AuthorID != userID {
		return ErrForbidden
	}

	// Re-extract hashtags if content changed.
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		// Update post itself — on the tx so it rolls back with the
		// hashtag re-linking below if anything fails.
		if err := s.postRepo.UpdateTx(ctx, tx, id, input); err != nil {
			return err
		}
		if input.Content != nil {
			if err := s.hashtagRepo.UnlinkPost(ctx, tx, id); err != nil {
				return err
			}
			if names := extractHashtags(*input.Content); len(names) > 0 {
				ids, err := s.hashtagRepo.UpsertMany(ctx, tx, names)
				if err != nil {
					return err
				}
				if err := s.hashtagRepo.LinkPost(ctx, tx, id, ids); err != nil {
					return err
				}
			}
		}
		return nil
	})
}

func (s *PostService) Delete(ctx context.Context, id, userID uuid.UUID) error {
	post, err := s.postRepo.GetBareByID(ctx, id)
	if err != nil {
		return err
	}
	if post == nil {
		return ErrPostNotFound
	}

	// Author or space-owner can delete.
	if post.AuthorID != userID {
		space, err := s.spaceRepo.GetByID(ctx, post.SpaceID, userID)
		if err != nil {
			return err
		}
		if space == nil || space.CreatedBy != userID {
			return ErrForbidden
		}
	}

	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		if err := s.hashtagRepo.UnlinkPost(ctx, tx, id); err != nil {
			return err
		}
		// Tx commits even though we use the bare repo here — DELETE CASCADE
		// will clean up comments/likes too.
		return s.postRepo.Delete(ctx, id)
	})
}
