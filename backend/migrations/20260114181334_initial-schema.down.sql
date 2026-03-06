-- Drop triggers
DROP TRIGGER IF EXISTS update_players_updated_at ON players;
DROP TRIGGER IF EXISTS update_punishment_categories_updated_at ON punishment_categories;
DROP TRIGGER IF EXISTS update_punishments_updated_at ON punishments;
DROP TRIGGER IF EXISTS update_appeals_updated_at ON appeals;
DROP TRIGGER IF EXISTS update_punishment_messages_updated_at ON punishment_messages;

DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Drop indexes
DROP INDEX IF EXISTS idx_punishments_player_category_active;
DROP INDEX IF EXISTS idx_punishments_player_category;
DROP INDEX IF EXISTS idx_punishments_active_player;
DROP INDEX IF EXISTS idx_appeals_pending;
DROP INDEX IF EXISTS idx_appeals_reviewed_by;
DROP INDEX IF EXISTS idx_appeals_status;
DROP INDEX IF EXISTS idx_appeals_player_uuid;
DROP INDEX IF EXISTS idx_appeals_punishment_id;
DROP INDEX IF EXISTS idx_punishments_issued_at;
DROP INDEX IF EXISTS idx_punishments_expires_at;
DROP INDEX IF EXISTS idx_punishments_active;
DROP INDEX IF EXISTS idx_punishments_category_id;
DROP INDEX IF EXISTS idx_punishments_staff_uuid;
DROP INDEX IF EXISTS idx_punishments_player_uuid;
DROP INDEX IF EXISTS idx_punishment_templates_category_offense;
DROP INDEX IF EXISTS idx_punishment_templates_category_id;
DROP INDEX IF EXISTS idx_punishment_categories_active;
DROP INDEX IF EXISTS idx_punishment_categories_name;
DROP INDEX IF EXISTS idx_punishment_messages_unique_default;
DROP INDEX IF EXISTS idx_players_staff;
DROP INDEX IF EXISTS idx_players_username;

-- Drop tables in dependency order
DROP TABLE IF EXISTS appeals;
DROP TABLE IF EXISTS punishment_messages;
DROP TABLE IF EXISTS punishments;
DROP TABLE IF EXISTS punishment_templates;
DROP TABLE IF EXISTS punishment_categories;
DROP TABLE IF EXISTS players;

-- Drop extension
DROP EXTENSION IF EXISTS "uuid-ossp";
