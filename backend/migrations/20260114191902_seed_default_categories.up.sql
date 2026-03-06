-- password_hash for 'FishiGames' generated using SHA-256
INSERT INTO players (uuid, username,
                     password_hash, password_change_required,
                     staff) VALUES
    ('e0251b43-351c-4318-a742-aa350627df60', 'FishiGames',
     '26fd07e1e0b80176afee967a824af6a4aa102555b0f3efd89d4b0e3c2d4baa30',
     FALSE, TRUE)
ON CONFLICT (uuid) DO NOTHING;

INSERT INTO punishment_categories (name, description, color_hex) VALUES
    ('Cheating/Hacking',  'Use of unauthorized mods, hacks, or external tools that provide an unfair advantage',  '#8B0000'),
    ('Chat Abuse',        'Spam, harassment, hate speech, excessive toxicity, or inappropriate language in chat',  '#FFA500'),
    ('Game Exploiting',   'Abusing bugs, glitches, or unintended game mechanics for personal gain',               '#FF4444'),
    ('Advertising',       'Promoting other servers, websites, or services without permission',                     '#9B59B6')
ON CONFLICT (name) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- Escalation ladders
-- Each row defines exactly what happens on offense N for that category.
-- If a player's offense count exceeds the highest step, the last step repeats.
-- ─────────────────────────────────────────────────────────────────────────────

-- Cheating/Hacking: 1st offense → 1-month ban  |  2nd offense → permanent ban
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 1, 'temp_ban', 43200, 'Banned for 1 month for using cheats or unauthorized mods. Remove them before appealing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 2, 'perm_ban',  NULL, 'Permanently banned for repeated cheating. Appeal on our forum with proof of a clean client.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

-- Chat Abuse: warning → 2-hour mute → 12-hour mute → 7-day ban → permanent ban
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 1, 'warn',      NULL, 'Warning for chat abuse. Keep the chat respectful and family-friendly.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 2, 'mute',       120, 'Muted for 2 hours for continued chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 3, 'mute',       720, 'Muted for 12 hours for repeated chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 4, 'temp_ban', 10080, 'Banned for 7 days for severe chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 5, 'perm_ban',   NULL, 'Permanently banned for extreme chat abuse. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

-- Game Exploiting: warning → 12-hour ban → 3-day ban → permanent ban
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 1, 'warn',     NULL, 'Warning for exploiting a game bug. Please report bugs instead of abusing them.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 2, 'temp_ban',  720, 'Banned for 12 hours for game exploiting.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 3, 'temp_ban', 4320, 'Banned for 3 days for repeated exploiting.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 4, 'perm_ban',  NULL, 'Permanently banned for excessive exploiting. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

-- Advertising: warning → kick → 7-day ban → permanent ban
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Advertising'), 1, 'warn',      NULL, 'Warning for advertising. Do not promote other servers or services in chat.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Advertising'), 2, 'kick',      NULL, 'Kicked for advertising.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Advertising'), 3, 'temp_ban', 10080, 'Banned for 7 days for continued advertising.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Advertising'), 4, 'perm_ban',   NULL, 'Permanently banned for persistent advertising. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- Default punishment notification messages
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO punishment_messages (message_type, name, description, message_content, is_default)
SELECT 'mute', 'Default Mute Message', 'Standard mute notification message',
       '§r§7§m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n§r§6§l🔇 You are muted§r\n§r§eReason: §f{reason}\n{expires_text}§r\n\n§r§7Contact support if this was issued in error\n§r§7§m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
       TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM punishment_messages WHERE message_type = 'mute' AND is_default = true
);

INSERT INTO punishment_messages (message_type, name, description, message_content, is_default)
SELECT 'ban', 'Default Ban Message', 'Standard ban notification with full formatting',
       '§r§4━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n§r§c  🔒 §r§f§lSENTINEL SECURITY\n§r§4━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n§r\n§r§4§l🚫 You have been banned!\n§r\n§r§c{reason}\n§r\n§r§e📅 Issued: §r§f{issued_at}§r\n{expires_text}§r\n\n§r§8━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n§r§7💬 Contact support if this was issued in error\n§r§8━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
       TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM punishment_messages WHERE message_type = 'ban' AND is_default = true
);

INSERT INTO punishment_messages (message_type, name, description, message_content, is_default)
SELECT 'kick', 'Default Kick Message', 'Simple kick notification message',
       '§r§e⚠️ §r§f§lYou have been kicked!\n§r\n§r§eReason: §f{reason}\n§r\n§r§7You may rejoin immediately',
       TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM punishment_messages WHERE message_type = 'kick' AND is_default = true
);

INSERT INTO punishment_messages (message_type, name, description, message_content, is_default)
SELECT 'warn', 'Default Warning Message', 'Standard warning notification',
       '§r§6§l⚠️ WARNING\n§r\n§r§eReason: §f{reason}\n§r\n§r§7This is offense #{offense_number} for {category_name}\n§r§7Please follow server rules to avoid further punishment',
       TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM punishment_messages WHERE message_type = 'warn' AND is_default = true
);
