-- Enable UUID extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Uses Minecraft UUID as primary key for direct integration
CREATE TABLE players (
                         uuid UUID PRIMARY KEY,                                     -- Minecraft UUID (without hyphens converted to UUID format)
                         username VARCHAR(16) NOT NULL,                             -- Current Minecraft username (max 16 chars)
                         tokens_invalidated_before TIMESTAMPTZ DEFAULT NULL,        -- Last time tokens were invalidated

                         staff BOOLEAN NOT NULL DEFAULT FALSE,                      -- Whether the player is a staff member

                         password_hash TEXT,                                        -- Hashed password for web interface login
                         password_change_required BOOLEAN NOT NULL DEFAULT TRUE,    -- Force password change on next login

                         created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                         updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Punishment categories for better organization and escalation tracking
CREATE TABLE punishment_categories (
                                       id SERIAL PRIMARY KEY,
                                       name VARCHAR(50) NOT NULL UNIQUE,                      -- e.g., "Game Exploiting", "Chat Abuse", "Cheating/Hacking"
                                       description TEXT,                                      -- Description of what falls under this category
                                       color_hex VARCHAR(7) DEFAULT '#FF6B6B',               -- Color for UI display (e.g., red for severe)
                                       severity_level INTEGER NOT NULL DEFAULT 1,            -- 1=Low, 2=Medium, 3=High, 4=Critical
                                       active BOOLEAN NOT NULL DEFAULT TRUE,
                                       created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                       updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                                       CONSTRAINT valid_color_hex CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
                                       CONSTRAINT valid_severity_level CHECK (severity_level BETWEEN 1 AND 4)
);

-- Templates for punishment escalation
CREATE TABLE punishment_templates (
                                      id SERIAL PRIMARY KEY,
                                      category_id INTEGER NOT NULL REFERENCES punishment_categories(id) ON DELETE CASCADE,
                                      offense_number INTEGER NOT NULL,                       -- 1st offense, 2nd offense, etc.
                                      punishment_type VARCHAR(20) NOT NULL,                  -- 'warn', 'mute', 'kick', 'temp_ban', 'perm_ban'
                                      duration_minutes INTEGER,                              -- NULL for permanent or warnings
                                      reason_template TEXT NOT NULL,                         -- Template reason with placeholders
                                      active BOOLEAN NOT NULL DEFAULT TRUE,
                                      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                                      CONSTRAINT valid_punishment_type CHECK (punishment_type IN ('warn', 'mute', 'kick', 'temp_ban', 'perm_ban')),
                                      CONSTRAINT duration_for_temp_punishments CHECK (
                                          (punishment_type IN ('temp_ban', 'mute') AND duration_minutes > 0) OR
                                          (punishment_type NOT IN ('temp_ban', 'mute'))
                                          ),
                                      CONSTRAINT positive_offense_number CHECK (offense_number > 0),
                                      UNIQUE(category_id, offense_number)
);

-- Punishments issued to players (must be based on templates)
CREATE TABLE punishments (
                             id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                             player_uuid UUID NOT NULL REFERENCES players(uuid),
                             staff_uuid UUID NOT NULL REFERENCES players(uuid),
                             template_id INTEGER NOT NULL REFERENCES punishment_templates(id),
                             category_id INTEGER NOT NULL REFERENCES punishment_categories(id),
                             offense_number INTEGER NOT NULL,
                             note TEXT,

    -- Custom fields that can override template defaults
                             custom_reason TEXT,                                        -- Optional custom reason, falls back to template
                             evidence TEXT,                                             -- Links to screenshots, logs, etc.

    -- Duration tracking
                             issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             expires_at TIMESTAMPTZ,                                   -- Calculated based on template or custom duration

    -- Status tracking
                             active BOOLEAN NOT NULL DEFAULT TRUE,                     -- Whether punishment is currently active
                             revoked BOOLEAN NOT NULL DEFAULT FALSE,                   -- Whether punishment was manually revoked
                             revoked_by UUID REFERENCES players(uuid),
                             revoked_at TIMESTAMPTZ,
                             revoke_reason TEXT,

                             created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                             CONSTRAINT revoked_fields_consistency CHECK (
                                 (revoked = true AND revoked_by IS NOT NULL AND revoked_at IS NOT NULL) OR
                                 (revoked = false AND revoked_by IS NULL AND revoked_at IS NULL)
                                 ),
                             CONSTRAINT expires_at_future CHECK (expires_at IS NULL OR expires_at > issued_at),
                             CONSTRAINT staff_not_self CHECK (player_uuid != staff_uuid),
                             CONSTRAINT positive_offense_number CHECK (offense_number > 0)
);

-- Appeals system for punishments
CREATE TABLE appeals (
                         id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                         punishment_id UUID NOT NULL REFERENCES punishments(id),
                         player_uuid UUID NOT NULL REFERENCES players(uuid),

    -- Appeal content
                         reason TEXT NOT NULL,                                      -- Player's appeal reason
                         additional_info TEXT,                                     -- Any additional information

    -- Status tracking
                         status VARCHAR(20) NOT NULL DEFAULT 'pending',            -- 'pending', 'under_review', 'approved', 'denied', 'withdrawn'

    -- Review information
                         reviewed_by UUID REFERENCES players(uuid),
                         reviewed_at TIMESTAMPTZ,
                         review_notes TEXT,                                        -- Staff notes on the appeal

    -- Timestamps
                         created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                         updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                         CONSTRAINT valid_appeal_status CHECK (status IN ('pending', 'under_review', 'approved', 'denied', 'withdrawn')),
                         CONSTRAINT review_fields_consistency CHECK (
                             (status IN ('approved', 'denied') AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL) OR
                             (status NOT IN ('approved', 'denied'))
                             ),
                         CONSTRAINT reviewer_not_appellant CHECK (reviewed_by IS NULL OR reviewed_by != player_uuid),
                         CONSTRAINT one_appeal_per_punishment UNIQUE(punishment_id)
);

-- Message templates for punishment notifications
CREATE TABLE punishment_messages (
                                     id SERIAL PRIMARY KEY,
                                     message_type VARCHAR(20) NOT NULL,                         -- 'warn', 'mute', 'kick', 'ban'
                                     name VARCHAR(100) NOT NULL,                                -- Human-readable name for the template
                                     description TEXT,                                          -- Description of when to use this template
                                     message_content TEXT NOT NULL,                            -- Message content with placeholders
                                     is_default BOOLEAN NOT NULL DEFAULT FALSE,                -- Whether this is the default for the type
                                     active BOOLEAN NOT NULL DEFAULT TRUE,                     -- Whether this template is active
                                     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                                     CONSTRAINT valid_message_type CHECK (message_type IN ('warn', 'mute', 'kick', 'ban'))
);

-- Create partial unique index to ensure only one default per message type
CREATE UNIQUE INDEX idx_punishment_messages_unique_default
ON punishment_messages(message_type)
WHERE is_default = true;

-- Indexes for performance
CREATE INDEX idx_players_username ON players(username);
CREATE INDEX idx_players_staff ON players(staff) WHERE staff = true;

CREATE INDEX idx_punishment_categories_name ON punishment_categories(name);
CREATE INDEX idx_punishment_categories_active ON punishment_categories(active) WHERE active = true;

CREATE INDEX idx_punishment_templates_category_id ON punishment_templates(category_id);
CREATE INDEX idx_punishment_templates_active ON punishment_templates(active) WHERE active = true;
CREATE INDEX idx_punishment_templates_category_offense ON punishment_templates(category_id, offense_number);

CREATE INDEX idx_punishments_player_uuid ON punishments(player_uuid);
CREATE INDEX idx_punishments_staff_uuid ON punishments(staff_uuid);
CREATE INDEX idx_punishments_category_id ON punishments(category_id);
CREATE INDEX idx_punishments_template_id ON punishments(template_id);
CREATE INDEX idx_punishments_active ON punishments(active) WHERE active = true;
CREATE INDEX idx_punishments_expires_at ON punishments(expires_at) WHERE expires_at IS NOT NULL AND active = true;
CREATE INDEX idx_punishments_issued_at ON punishments(issued_at);

CREATE INDEX idx_appeals_punishment_id ON appeals(punishment_id);
CREATE INDEX idx_appeals_player_uuid ON appeals(player_uuid);
CREATE INDEX idx_appeals_status ON appeals(status);
CREATE INDEX idx_appeals_reviewed_by ON appeals(reviewed_by);

-- Additional functional indexes for common queries
CREATE INDEX idx_punishments_active_player ON punishments(player_uuid, active) WHERE active = true;
CREATE INDEX idx_appeals_pending ON appeals(status, created_at) WHERE status = 'pending';

-- New indexes for offense counting and escalation
CREATE INDEX idx_punishments_player_category_offense ON punishments(player_uuid, category_id, offense_number);
CREATE INDEX idx_punishments_category_not_revoked ON punishments(category_id, player_uuid) WHERE NOT revoked;

-- Function to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to automatically update updated_at columns
CREATE TRIGGER update_players_updated_at
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_punishment_categories_updated_at
    BEFORE UPDATE ON punishment_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_punishment_templates_updated_at
    BEFORE UPDATE ON punishment_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_punishments_updated_at
    BEFORE UPDATE ON punishments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appeals_updated_at
    BEFORE UPDATE ON appeals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_punishment_messages_updated_at
    BEFORE UPDATE ON punishment_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

