-- Drop views first
DROP VIEW IF EXISTS active_punishments;
DROP VIEW IF EXISTS punishment_history;

-- Drop indexes
DROP INDEX IF EXISTS idx_punishment_notes_punishment_id;
DROP INDEX IF EXISTS idx_appeals_status;
DROP INDEX IF EXISTS idx_appeals_player_uuid;
DROP INDEX IF EXISTS idx_appeals_punishment_id;
DROP INDEX IF EXISTS idx_punishments_expires_at;
DROP INDEX IF EXISTS idx_punishments_active;
DROP INDEX IF EXISTS idx_punishments_template_id;
DROP INDEX IF EXISTS idx_punishments_staff_uuid;
DROP INDEX IF EXISTS idx_punishments_player_uuid;

-- Remove foreign key constraints
ALTER TABLE IF EXISTS punishments DROP CONSTRAINT IF EXISTS fk_punishment_appeal;

-- Drop tables
DROP TABLE IF EXISTS punishment_notes;
DROP TABLE IF EXISTS appeals;
DROP TABLE IF EXISTS punishments;
DROP TABLE IF EXISTS punishment_templates;
DROP TABLE IF EXISTS punishment_categories;
DROP TABLE IF EXISTS players;