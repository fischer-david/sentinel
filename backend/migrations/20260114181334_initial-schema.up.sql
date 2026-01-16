-- Enable UUID extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Uses Minecraft UUID as primary key for direct integration
CREATE TABLE players (
                         uuid UUID PRIMARY KEY,                    -- Minecraft UUID (without hyphens converted to UUID format)
                         username VARCHAR(16) NOT NULL,           -- Current Minecraft username (max 16 chars)
                         tokens_invalidated_before TIMESTAMPTZ DEFAULT NULL, -- Last time tokens were invalidated

                         password_hash TEXT,                      -- Hashed password for web interface login
                         password_change_required BOOLEAN NOT NULL DEFAULT TRUE, -- Force password change on next login

                         created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                         updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
