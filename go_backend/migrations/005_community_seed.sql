-- Cosmic Mirror: Seed default categories so the Spaces UI has something to
-- render at first run. Idempotent — uses ON CONFLICT DO NOTHING so re-running
-- is safe.

INSERT INTO space_categories (name, icon, sort_order) VALUES
    ('Astrology',     'auto_awesome_rounded',     0),
    ('Vedic',         'brightness_5_rounded',     1),
    ('Tarot',         'style_rounded',            2),
    ('Numerology',    'pin_rounded',              3),
    ('Crystals',      'diamond_rounded',          4),
    ('Spirituality',  'self_improvement_rounded', 5),
    ('Dreams',        'nightlight_round',         6),
    ('Compatibility', 'favorite_rounded',         7)
ON CONFLICT (name) DO NOTHING;
