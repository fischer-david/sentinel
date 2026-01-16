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

-- Punishment categories for organization
CREATE TABLE punishment_categories (
                                       id SERIAL PRIMARY KEY,
                                       name VARCHAR(50) NOT NULL UNIQUE,                      -- e.g., "Griefing", "Harassment", "Cheating"
                                       description TEXT,
                                       color VARCHAR(7) DEFAULT '#ff0000',                    -- Hex color for UI
                                       active BOOLEAN NOT NULL DEFAULT TRUE,
                                       created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Templates for punishment escalation
CREATE TABLE punishment_templates (
                                      id SERIAL PRIMARY KEY,
                                      category_id INTEGER NOT NULL REFERENCES punishment_categories(id),
                                      offense_number INTEGER NOT NULL,                       -- 1st offense, 2nd offense, etc.
                                      punishment_type VARCHAR(20) NOT NULL,                  -- 'warn', 'mute', 'kick', 'temp_ban', 'perm_ban'
                                      duration_minutes INTEGER,                              -- NULL for permanent or warnings
                                      reason_template TEXT NOT NULL,                         -- Template reason with placeholders
                                      active BOOLEAN NOT NULL DEFAULT TRUE,
                                      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                                      CONSTRAINT valid_punishment_type CHECK (punishment_type IN ('warn', 'mute', 'kick', 'temp_ban', 'perm_ban')),
                                      CONSTRAINT duration_for_temp_punishments CHECK (
                                          (punishment_type IN ('temp_ban', 'mute') AND duration_minutes > 0) OR
                                          (punishment_type NOT IN ('temp_ban', 'mute'))
                                          ),
                                      UNIQUE(category_id, offense_number)
);

-- Punishments issued to players (must be based on templates)
CREATE TABLE punishments (
                             id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                             player_uuid UUID NOT NULL REFERENCES players(uuid),
                             staff_uuid UUID NOT NULL REFERENCES players(uuid),
                             template_id INTEGER NOT NULL REFERENCES punishment_templates(id),

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

    -- Appeal tracking
                             appeal_id UUID,                                           -- References appeals table

                             created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

                             CONSTRAINT revoked_fields_consistency CHECK (
                                 (revoked = true AND revoked_by IS NOT NULL AND revoked_at IS NOT NULL) OR
                                 (revoked = false AND revoked_by IS NULL AND revoked_at IS NULL)
                                 )
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
                             )
);

-- Add foreign key reference from punishments to appeals
ALTER TABLE punishments ADD CONSTRAINT fk_punishment_appeal
    FOREIGN KEY (appeal_id) REFERENCES appeals(id);

-- Notes for punishments (additional context from staff)
CREATE TABLE punishment_notes (
                                  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                  punishment_id UUID NOT NULL REFERENCES punishments(id),
                                  staff_uuid UUID NOT NULL REFERENCES players(uuid),
                                  note TEXT NOT NULL,
                                  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_punishments_player_uuid ON punishments(player_uuid);
CREATE INDEX idx_punishments_staff_uuid ON punishments(staff_uuid);
CREATE INDEX idx_punishments_template_id ON punishments(template_id);
CREATE INDEX idx_punishments_active ON punishments(active) WHERE active = true;
CREATE INDEX idx_punishments_expires_at ON punishments(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_appeals_punishment_id ON appeals(punishment_id);
CREATE INDEX idx_appeals_player_uuid ON appeals(player_uuid);
CREATE INDEX idx_appeals_status ON appeals(status);
CREATE INDEX idx_punishment_notes_punishment_id ON punishment_notes(punishment_id);