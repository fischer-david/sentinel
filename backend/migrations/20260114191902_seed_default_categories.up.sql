-- password_hash for 'FishiGames' generated using SHA-256

INSERT INTO players (uuid, username, password_hash,
                     skin_signature, skin_value, first_join,
                     last_seen, password_change_required) VALUES
    ('e0251b43-351c-4318-a742-aa350627df60', 'FishiGames',
     '26fd07e1e0b80176afee967a824af6a4aa102555b0f3efd89d4b0e3c2d4baa30',NOW(),
     NOW(), FALSE)
ON CONFLICT (uuid) DO NOTHING;