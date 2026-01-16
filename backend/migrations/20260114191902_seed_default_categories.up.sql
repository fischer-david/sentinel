-- password_hash for 'FishiGames' generated using SHA-256

INSERT INTO players (uuid, username,
                     password_hash, password_change_required,
                     staff) VALUES
    ('e0251b43-351c-4318-a742-aa350627df60', 'FishiGames',
     '26fd07e1e0b80176afee967a824af6a4aa102555b0f3efd89d4b0e3c2d4baa30',
     FALSE, TRUE)
ON CONFLICT (uuid) DO NOTHING;

-- Insert default punishment categories for minigame server
INSERT INTO punishment_categories (name, description, color) VALUES
    ('Game Exploiting', 'Exploiting game mechanics, glitches, or bugs for unfair advantage', '#8800FF'),
    ('Team Griefing', 'Sabotaging teammates or intentionally helping enemies', '#FF4444'),
    ('Chat Abuse', 'Spam, toxicity, inappropriate language, or advertising', '#FF8800'),
    ('Cheating/Hacking', 'Use of unauthorized mods, hacks, or external tools', '#FF0000'),
    ('Spawn Camping', 'Excessively camping spawns or safe zones', '#CC3300'),
    ('Cross-teaming', 'Teaming with opponents in solo games or betraying team rules', '#9900CC'),
    ('Game Throwing', 'Intentionally losing or not trying to win', '#FF6600'),
    ('Server Rules', 'General server rule violations not covered by other categories', '#999999')
ON CONFLICT (name) DO NOTHING;

-- Insert escalation templates for each category
-- Game Exploiting escalation (strict for competitive integrity)
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 1, 'warn', NULL, 'Warning for game exploiting: {details}. Please play fair and report bugs instead.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 2, 'temp_ban', 720, 'Temporary ban for continued exploiting: {details}. 12 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 3, 'temp_ban', 4320, 'Temporary ban for repeated exploiting: {details}. 3 day ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Exploiting'), 4, 'perm_ban', NULL, 'Permanent ban for excessive exploiting: {details}. Appeal on our forum.');

-- Team Griefing escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 1, 'warn', NULL, 'Warning for team griefing: {details}. Work with your team, not against them.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 2, 'temp_ban', 360, 'Temporary ban for team griefing: {details}. 6 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 3, 'temp_ban', 1440, 'Temporary ban for continued team griefing: {details}. 1 day ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 4, 'temp_ban', 7200, 'Temporary ban for excessive team griefing: {details}. 5 day ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Team Griefing'), 5, 'perm_ban', NULL, 'Permanent ban for persistent team griefing: {details}. Appeal on our forum.');

-- Chat Abuse escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 1, 'warn', NULL, 'Warning for chat abuse: {details}. Keep chat respectful and family-friendly.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 2, 'mute', 120, 'Muted for chat abuse: {details}. 2 hour mute.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 3, 'mute', 720, 'Muted for continued chat abuse: {details}. 12 hour mute.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 4, 'temp_ban', 1440, 'Temporary ban for severe chat abuse: {details}. 1 day ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Chat Abuse'), 5, 'perm_ban', NULL, 'Permanent ban for extreme chat abuse: {details}. Appeal on our forum.');

-- Cheating/Hacking escalation (zero tolerance)
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 1, 'temp_ban', 10080, 'Temporary ban for cheating/hacking: {details}. 1 week ban - remove all unauthorized mods.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cheating/Hacking'), 2, 'perm_ban', NULL, 'Permanent ban for repeated cheating: {details}. Appeal on our forum with proof of clean client.');

-- Spawn Camping escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 1, 'warn', NULL, 'Warning for spawn camping: {details}. Give other players a fair chance.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 2, 'kick', NULL, 'Kicked for spawn camping: {details}. Play more fairly.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 3, 'temp_ban', 360, 'Temporary ban for continued spawn camping: {details}. 6 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Spawn Camping'), 4, 'temp_ban', 1440, 'Temporary ban for excessive spawn camping: {details}. 1 day ban.');

-- Cross-teaming escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 1, 'warn', NULL, 'Warning for cross-teaming: {details}. Follow the game rules and team assignments.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 2, 'temp_ban', 180, 'Temporary ban for cross-teaming: {details}. 3 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 3, 'temp_ban', 720, 'Temporary ban for continued cross-teaming: {details}. 12 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Cross-teaming'), 4, 'temp_ban', 2880, 'Temporary ban for repeated cross-teaming: {details}. 2 day ban.');

-- Game Throwing escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 1, 'warn', NULL, 'Warning for game throwing: {details}. Please try your best in all games.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 2, 'temp_ban', 180, 'Temporary ban for game throwing: {details}. 3 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 3, 'temp_ban', 720, 'Temporary ban for continued game throwing: {details}. 12 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Game Throwing'), 4, 'temp_ban', 2880, 'Temporary ban for repeated game throwing: {details}. 2 day ban.');

-- General Server Rules escalation
INSERT INTO punishment_templates (category_id, offense_number, punishment_type, duration_minutes, reason_template) VALUES
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 1, 'warn', NULL, 'Warning for rule violation: {details}. Please read /rules and follow server guidelines.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 2, 'kick', NULL, 'Kicked for rule violation: {details}. Read the rules and rejoin.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 3, 'temp_ban', 360, 'Temporary ban for continued rule violations: {details}. 6 hour ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 4, 'temp_ban', 1440, 'Temporary ban for repeated rule violations: {details}. 1 day ban.'),
    ((SELECT id FROM punishment_categories WHERE name = 'Server Rules'), 5, 'perm_ban', NULL, 'Permanent ban for excessive rule violations: {details}. Appeal on our forum.');