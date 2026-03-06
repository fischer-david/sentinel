package dev.fishigames.sentinel.models;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

public class PunishmentModel {
    private final UUID id;
    private final String type;
    private final String reason;
    private final UUID playerId;
    private final boolean active;
    private final long issuedAt;
    private final Optional<Long> expiresAt;

    public static List<PunishmentModel> fromList(List<PunishmentOuterClass.Punishment> punishments) {
        return punishments.stream()
                .map(PunishmentModel::new)
                .collect(Collectors.toList());
    }

    public PunishmentModel(UUID id, String type, String reason, UUID playerId, boolean active, long issuedAt, Optional<Long> expiresAt) {
        this.id = id;
        this.type = type;
        this.reason = reason;
        this.playerId = playerId;
        this.active = active;
        this.issuedAt = issuedAt;
        this.expiresAt = expiresAt;
    }

    public PunishmentModel(PunishmentOuterClass.Punishment punishment) {
        this(
            UUID.fromString(punishment.getId()),
            punishment.getType(),
            punishment.getReason(),
            UUID.fromString(punishment.getPlayerId()),
            punishment.getActive(),
            punishment.getIssuedAt(),
            punishment.hasExpiresAt() ? Optional.of(punishment.getExpiresAt()) : Optional.empty()
        );
    }

    public UUID getId() {
        return id;
    }

    public String getType() {
        return type;
    }

    public String getReason() {
        return reason;
    }

    public UUID getPlayerId() {
        return playerId;
    }

    public boolean isActive() {
        return active;
    }

    public long getIssuedAt() {
        return issuedAt;
    }

    public Optional<Long> getExpiresAt() {
        return expiresAt;
    }
}