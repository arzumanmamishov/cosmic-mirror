-- Cosmic Mirror: Community / Spaces forum indexes
-- Run after 003_community_schema.sql
-- All indexes target the hot-path queries: list spaces, list posts in space,
-- list comments on post, fetch unread notifications, etc.

-- Spaces: ranking by popularity, filter by category, search by handle
CREATE INDEX idx_spaces_member_count
    ON spaces(member_count DESC);

CREATE INDEX idx_spaces_category
    ON spaces(category_id, member_count DESC);

CREATE INDEX idx_spaces_handle_lower
    ON spaces(LOWER(handle));

CREATE INDEX idx_spaces_created_by
    ON spaces(created_by, created_at DESC);

-- Membership: "my joined spaces", "members of this space"
CREATE INDEX idx_space_members_user
    ON space_members(user_id, joined_at DESC);

-- Posts: feed within a space, "my posts" lookup
CREATE INDEX idx_posts_space_created
    ON posts(space_id, created_at DESC);

CREATE INDEX idx_posts_author
    ON posts(author_id, created_at DESC);

-- Comments: thread for a post (oldest first), "my comments"
CREATE INDEX idx_comments_post_created
    ON comments(post_id, created_at ASC);

CREATE INDEX idx_comments_author
    ON comments(author_id, created_at DESC);

CREATE INDEX idx_comments_parent
    ON comments(parent_comment_id);

-- Likes: "is this liked by me" lookup uses the PK; "who liked X" uses this:
CREATE INDEX idx_likes_target
    ON likes(target_type, target_id);

-- Hashtags: popular trending list, post→tag join lookup
CREATE INDEX idx_hashtags_use_count
    ON hashtags(use_count DESC);

CREATE INDEX idx_post_hashtags_hashtag
    ON post_hashtags(hashtag_id);

-- Notifications: feed for a user (newest first); fast unread-count query
CREATE INDEX idx_community_notifications_recip
    ON community_notifications(recipient_id, created_at DESC);

CREATE INDEX idx_community_notifications_unread
    ON community_notifications(recipient_id, created_at DESC)
    WHERE read_at IS NULL;
