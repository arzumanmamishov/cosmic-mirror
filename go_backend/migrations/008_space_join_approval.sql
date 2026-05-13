-- Migration 008 — Space join approval workflow.
--
-- Spaces are now gated: tapping "Join" creates a pending request that the
-- space owner must accept before the requester can read posts or appear in
-- the member list. Existing memberships are grandfathered as 'approved' so
-- nobody loses access on deploy.

ALTER TABLE space_members
    ADD COLUMN status TEXT NOT NULL DEFAULT 'approved'
        CHECK (status IN ('pending', 'approved'));

-- Partial index for the owner's pending-requests inbox: this is the only
-- query that filters by status, and pending rows are a tiny minority, so
-- a partial index is cheaper than a full one.
CREATE INDEX idx_space_members_pending
    ON space_members(space_id, joined_at DESC)
    WHERE status = 'pending';

-- The notifications table's CHECK constraint enumerates allowed types.
-- Add the three new join-approval notification types; preserve all the
-- existing ones so this is purely additive.
ALTER TABLE community_notifications
    DROP CONSTRAINT IF EXISTS community_notifications_type_check;
ALTER TABLE community_notifications
    ADD CONSTRAINT community_notifications_type_check CHECK (type IN (
        'space_followed',
        'space_member_joined',
        'space_join_requested',
        'space_join_approved',
        'space_join_declined',
        'post_in_space',
        'post_liked',
        'post_commented',
        'comment_replied',
        'comment_liked',
        'mentioned'
    ));
