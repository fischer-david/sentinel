package dev.fishigames.sentinel.models;

import java.util.UUID;

public class KickPlayerModel {
    private UUID playerId;
    private String reason;

    public String getReason() {
        return reason;
    }

    public UUID getPlayerId() {
        return playerId;
    }

    public KickPlayerModel setPlayerId(UUID playerId) {
        this.playerId = playerId;
        return this;
    }

    public KickPlayerModel setReason(String reason) {
        this.reason = reason;
        return this;
    }
}