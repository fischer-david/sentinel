-- password_hash for 'FishiGames' generated using SHA-256

INSERT INTO players (uuid, username,
                     password_hash, password_change_required,
                     staff) VALUES
    ('e0251b43-351c-4318-a742-aa350627df60', 'FishiGames',
     '26fd07e1e0b80176afee967a824af6a4aa102555b0f3efd89d4b0e3c2d4baa30',
     FALSE, TRUE)
ON CONFLICT (uuid) DO NOTHING;

INSERT INTO punishment_categories (name, description, color_hex, severity_level) VALUES
    ('Game Exploiting', 'Exploiting game mechanics, glitches, or bugs for unfair advantage', '#FF4444', 4),
    ('Team Griefing', 'Sabotaging teammates or intentionally helping enemies', '#FF6B35', 3),
    ('Chat Abuse', 'Spam, toxicity, inappropriate language, or advertising', '#FFA500', 2),
    ('Cheating/Hacking', 'Use of unauthorized mods, hacks, or external tools', '#8B0000', 4),
    ('Spawn Camping', 'Excessively camping spawns or safe zones', '#FF8C00', 2),
    ('Cross-teaming', 'Teaming with opponents in solo games or betraying team rules', '#FF6347', 3),
    ('Game Throwing', 'Intentionally losing or not trying to win', '#DC143C', 3),
    ('Server Rules', 'General server rule violations not covered by other categories', '#B22222', 1)
ON CONFLICT (name) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 1, 'warn', NULL, 'Warning for game exploiting. Please play fair and report bugs instead.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 2, 'temp_ban', 720, 'Ban for continued exploiting.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 3, 'temp_ban', 4320, 'Ban for repeated exploiting.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 4, 'perm_ban', NULL, 'Ban for excessive exploiting. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 1, 'warn', NULL, 'Warning for team griefing. Work with your team, not against them.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 2, 'temp_ban', 360, 'Ban for team griefing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 3, 'temp_ban', 1440, 'Ban for continued team griefing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 4, 'temp_ban', 7200, 'Ban for excessive team griefing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 5, 'perm_ban', NULL, 'Ban for persistent team griefing. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 1, 'warn', NULL, 'Warning for chat abuse. Keep chat respectful and family-friendly.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 2, 'mute', 120, 'Muted for chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 3, 'mute', 720, 'Muted for continued chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 4, 'temp_ban', 1440, 'Ban for severe chat abuse.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 5, 'perm_ban', NULL, 'Ban for extreme chat abuse. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 1, 'temp_ban', 10080, 'Ban for cheating/hacking. Remove all unauthorized mods.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 2, 'perm_ban', NULL, 'Ban for repeated cheating. Appeal on our forum with proof of clean client.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 1, 'warn', NULL, 'Warning for spawn camping. Give other players a fair chance.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 2, 'kick', NULL, 'Kicked for spawn camping. Play more fairly.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 3, 'temp_ban', 360, 'Ban for continued spawn camping.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 4, 'temp_ban', 1440, 'Ban for excessive spawn camping.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 1, 'warn', NULL, 'Warning for cross-teaming. Follow the game rules and team assignments.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 2, 'temp_ban', 180, 'Ban for cross-teaming.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 3, 'temp_ban', 720, 'Ban for continued cross-teaming.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 4, 'temp_ban', 2880, 'Ban for repeated cross-teaming.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 1, 'warn', NULL, 'Warning for game throwing. Please try your best in all games.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 2, 'temp_ban', 180, 'Ban for game throwing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 3, 'temp_ban', 720, 'Ban for continued game throwing.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 4, 'temp_ban', 2880, 'Ban for repeated game throwing.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 1, 'warn', NULL, 'Warning for rule violation. Please read /rules and follow server guidelines.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 2, 'kick', NULL, 'Kicked for rule violation. Read the rules and rejoin.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 3, 'temp_ban', 360, 'Ban for continued rule violations.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 4, 'temp_ban', 1440, 'Ban for repeated rule violations.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 5, 'perm_ban', NULL, 'Ban for excessive rule violations. Appeal on our forum.')
ON CONFLICT (category_id, offense_number) DO NOTHING;

INSERT INTO punishment_messages (message_type, name, description, message_content, is_default)
SELECT 'mute', 'Default Mute Message', 'Standard mute notification message',
       '§r§7§m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n§r§6§l🔇 You are muted§r\n§r§eReason: §f{reason}{expires_text}§r\n\n§r§7Contact support if this was issued in error\n§r§7§m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
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

