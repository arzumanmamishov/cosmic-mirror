package domain

import (
	"time"

	"github.com/google/uuid"
)

// ===== Spaces =====

// SpaceCategory is a top-level grouping (Astrology, Tarot, Vedic, etc).
// Seeded via 005_community_seed.sql.
type SpaceCategory struct {
	ID        uuid.UUID `db:"id"         json:"id"`
	Name      string    `db:"name"       json:"name"`
	Icon      *string   `db:"icon"       json:"icon,omitempty"`
	SortOrder int       `db:"sort_order" json:"sort_order"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

// Space is a community / discussion group.
type Space struct {
	ID           uuid.UUID  `db:"id"            json:"id"`
	Handle       string     `db:"handle"        json:"handle"`
	Name         string     `db:"name"          json:"name"`
	Description  *string    `db:"description"   json:"description,omitempty"`
	AvatarURL    *string    `db:"avatar_url"    json:"avatar_url,omitempty"`
	CategoryID   *uuid.UUID `db:"category_id"   json:"category_id,omitempty"`
	CreatedBy    uuid.UUID  `db:"created_by"    json:"created_by"`
	MemberCount  int        `db:"member_count"  json:"member_count"`
	IsVerified   bool       `db:"is_verified"   json:"is_verified"`
	IsSpicy      bool       `db:"is_spicy"      json:"is_spicy"`
	CreatedAt    time.Time  `db:"created_at"    json:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at"    json:"updated_at"`
}

// SpaceWithMeta is the list-response shape — Space plus per-viewer flags
// and the joined category name. Returned from List/Get list endpoints.
type SpaceWithMeta struct {
	Space
	IsJoined     bool    `db:"is_joined"     json:"is_joined"`
	CategoryName *string `db:"category_name" json:"category_name,omitempty"`
}

// SpaceMember is one user's membership of one space (joined to user data
// for display).
type SpaceMember struct {
	SpaceID         uuid.UUID `db:"space_id"        json:"space_id"`
	UserID          uuid.UUID `db:"user_id"         json:"user_id"`
	Role            string    `db:"role"            json:"role"` // member|mod|owner
	JoinedAt        time.Time `db:"joined_at"       json:"joined_at"`
	UserName        string    `db:"user_name"       json:"user_name"`
	UserAvatarURL   *string   `db:"user_avatar_url" json:"user_avatar_url,omitempty"`
}

// ===== Posts =====

type Post struct {
	ID           uuid.UUID `db:"id"            json:"id"`
	SpaceID      uuid.UUID `db:"space_id"      json:"space_id"`
	AuthorID     uuid.UUID `db:"author_id"     json:"author_id"`
	Content      string    `db:"content"       json:"content"`
	LinkURL      *string   `db:"link_url"      json:"link_url,omitempty"`
	LikeCount    int       `db:"like_count"    json:"like_count"`
	CommentCount int       `db:"comment_count" json:"comment_count"`
	CreatedAt    time.Time `db:"created_at"    json:"created_at"`
	UpdatedAt    time.Time `db:"updated_at"    json:"updated_at"`
}

// PostWithMeta is the feed-shape variant — Post plus joined author data,
// the parent space's handle, and the per-viewer "is liked by me" flag.
type PostWithMeta struct {
	Post
	AuthorName      string  `db:"author_name"       json:"author_name"`
	AuthorAvatarURL *string `db:"author_avatar_url" json:"author_avatar_url,omitempty"`
	SpaceHandle     string  `db:"space_handle"      json:"space_handle"`
	SpaceName       string  `db:"space_name"        json:"space_name"`
	IsLikedByMe     bool    `db:"is_liked_by_me"    json:"is_liked_by_me"`
}

// ===== Comments =====

type Comment struct {
	ID              uuid.UUID  `db:"id"                 json:"id"`
	PostID          uuid.UUID  `db:"post_id"            json:"post_id"`
	ParentCommentID *uuid.UUID `db:"parent_comment_id"  json:"parent_comment_id,omitempty"`
	AuthorID        uuid.UUID  `db:"author_id"          json:"author_id"`
	Content         string     `db:"content"            json:"content"`
	LikeCount       int        `db:"like_count"         json:"like_count"`
	CreatedAt       time.Time  `db:"created_at"         json:"created_at"`
	UpdatedAt       time.Time  `db:"updated_at"         json:"updated_at"`
}

type CommentWithMeta struct {
	Comment
	AuthorName      string  `db:"author_name"       json:"author_name"`
	AuthorAvatarURL *string `db:"author_avatar_url" json:"author_avatar_url,omitempty"`
	IsLikedByMe     bool    `db:"is_liked_by_me"    json:"is_liked_by_me"`
}

// ===== Hashtags =====

type Hashtag struct {
	ID        uuid.UUID `db:"id"         json:"id"`
	Name      string    `db:"name"       json:"name"`
	UseCount  int       `db:"use_count"  json:"use_count"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

// ===== Notifications =====

type CommunityNotification struct {
	ID          uuid.UUID  `db:"id"           json:"id"`
	RecipientID uuid.UUID  `db:"recipient_id" json:"recipient_id"`
	ActorID     *uuid.UUID `db:"actor_id"     json:"actor_id,omitempty"`
	Type        string     `db:"type"         json:"type"`
	TargetType  string     `db:"target_type"  json:"target_type"`
	TargetID    uuid.UUID  `db:"target_id"    json:"target_id"`
	Snippet     *string    `db:"snippet"      json:"snippet,omitempty"`
	ReadAt      *time.Time `db:"read_at"      json:"read_at,omitempty"`
	CreatedAt   time.Time  `db:"created_at"   json:"created_at"`
}

type NotificationWithMeta struct {
	CommunityNotification
	ActorName      *string `db:"actor_name"       json:"actor_name,omitempty"`
	ActorAvatarURL *string `db:"actor_avatar_url" json:"actor_avatar_url,omitempty"`
}

// ===== Input types (for handlers) =====

type CreateSpaceInput struct {
	Handle      string     `json:"handle"`
	Name        string     `json:"name"`
	Description *string    `json:"description"`
	AvatarURL   *string    `json:"avatar_url"`
	CategoryID  *uuid.UUID `json:"category_id"`
	IsSpicy     bool       `json:"is_spicy"`
}

type UpdateSpaceInput struct {
	Name        *string    `json:"name"`
	Description *string    `json:"description"`
	AvatarURL   *string    `json:"avatar_url"`
	CategoryID  *uuid.UUID `json:"category_id"`
	IsSpicy     *bool      `json:"is_spicy"`
}

type CreatePostInput struct {
	Content string  `json:"content"`
	LinkURL *string `json:"link_url"`
}

type UpdatePostInput struct {
	Content *string `json:"content"`
	LinkURL *string `json:"link_url"`
}

type CreateCommentInput struct {
	Content         string     `json:"content"`
	ParentCommentID *uuid.UUID `json:"parent_comment_id"`
}

type UpdateCommentInput struct {
	Content *string `json:"content"`
}
