-- Remove seeded punishment messages
DELETE FROM punishment_messages
WHERE message_type IN ('mute', 'ban', 'kick', 'warn') AND is_default = true;

-- Remove seeded punishment templates
DELETE FROM punishment_templates
WHERE category_id IN (
    SELECT id FROM punishment_categories
    WHERE name IN ('Game Exploiting', 'Team Griefing', 'Chat Abuse', 'Cheating/Hacking',
                   'Spawn Camping', 'Cross-teaming', 'Game Throwing', 'Server Rules')
);

-- Remove seeded punishment categories
DELETE FROM punishment_categories
WHERE name IN ('Game Exploiting', 'Team Griefing', 'Chat Abuse', 'Cheating/Hacking',
               'Spawn Camping', 'Cross-teaming', 'Game Throwing', 'Server Rules');

-- Remove seeded player
DELETE FROM players
WHERE uuid = 'e0251b43-351c-4318-a742-aa350627df60';

