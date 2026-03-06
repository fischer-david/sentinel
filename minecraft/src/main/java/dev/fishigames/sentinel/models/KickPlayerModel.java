package dev.fishigames.sentinel.models;

import java.util.UUID;

public record KickPlayerModel(UUID playerId, String reason) {}