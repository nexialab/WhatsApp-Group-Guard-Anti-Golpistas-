CREATE TABLE IF NOT EXISTS group_policies (
  id BIGSERIAL PRIMARY KEY,
  group_jid TEXT UNIQUE NOT NULL,
  group_name TEXT,
  only_admins_can_post BOOLEAN DEFAULT FALSE,
  auto_delete_enabled BOOLEAN DEFAULT TRUE,
  auto_remove_enabled BOOLEAN DEFAULT TRUE,
  min_score_to_delete INTEGER DEFAULT 35,
  min_score_to_remove INTEGER DEFAULT 60,
  admin_alert_number TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trusted_senders (
  id BIGSERIAL PRIMARY KEY,
  group_jid TEXT NULL,
  phone TEXT NOT NULL,
  label TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS participant_snapshots (
  id BIGSERIAL PRIMARY KEY,
  group_jid TEXT NOT NULL,
  participant_jid TEXT,
  phone TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  is_present BOOLEAN DEFAULT TRUE,
  source TEXT DEFAULT 'unknown',
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (group_jid, phone)
);

CREATE TABLE IF NOT EXISTS moderation_incidents (
  id BIGSERIAL PRIMARY KEY,
  occurred_at TIMESTAMPTZ DEFAULT NOW(),
  group_jid TEXT NOT NULL,
  sender_phone TEXT,
  sender_jid TEXT,
  message_id TEXT,
  message_text TEXT,
  event_name TEXT,
  score INTEGER DEFAULT 0,
  reasons JSONB DEFAULT '[]'::jsonb,
  delete_attempted BOOLEAN DEFAULT FALSE,
  remove_attempted BOOLEAN DEFAULT FALSE,
  raw_payload JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS contact_scores (
  id BIGSERIAL PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  score INTEGER DEFAULT 0,
  risk_level TEXT DEFAULT 'low',
  reason_summary JSONB DEFAULT '[]'::jsonb,
  metrics JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_participant_snapshots_phone ON participant_snapshots (phone);
CREATE INDEX IF NOT EXISTS idx_participant_snapshots_group_jid ON participant_snapshots (group_jid);
CREATE INDEX IF NOT EXISTS idx_moderation_incidents_sender_phone ON moderation_incidents (sender_phone);
CREATE INDEX IF NOT EXISTS idx_moderation_incidents_group_jid ON moderation_incidents (group_jid);
CREATE INDEX IF NOT EXISTS idx_contact_scores_score ON contact_scores (score DESC);

-- EXEMPLOS DE POLÍTICA
-- INSERT INTO group_policies (group_jid, group_name, only_admins_can_post, auto_delete_enabled, auto_remove_enabled, min_score_to_delete, min_score_to_remove, admin_alert_number)
-- VALUES ('120363000000000000@g.us', 'Lançamento VIP', true, true, true, 35, 60, '5531999999999')
-- ON CONFLICT (group_jid) DO NOTHING;

-- EXEMPLOS DE WHITELIST
-- INSERT INTO trusted_senders (group_jid, phone, label)
-- VALUES
--   (NULL, '5531999999999', 'Sócio'),
--   ('120363000000000000@g.us', '5531888888888', 'Suporte do grupo');
