package dev.fishigames.sentinel.models;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public class PunishmentModel {
    private UUID id;
    private String type;
    private String reason;
    private UUID playerId;
    private Long issuedAt;
    private boolean active;
    private Optional<Long> expiresAt;

    public static ArrayList<PunishmentModel> from(List<PunishmentOuterClass.Punishment> punishments) {
        ArrayList<PunishmentModel> models = new ArrayList<>();
        for (PunishmentOuterClass.Punishment punishment : punishments) {
            models.add(from(punishment));
        }
        return models;
    }

    public static PunishmentModel from(PunishmentOuterClass.Punishment punishment) {
        return new PunishmentModel()
                .setId(UUID.fromString(punishment.getId()))
                .setType(punishment.getType())
                .setReason(punishment.getReason())
                .setPlayerId(UUID.fromString(punishment.getPlayerId()))
                .setIssuedAt(punishment.getIssuedAt())
                .setActive(punishment.getActive())
                .setExpiresAt(punishment.getExpiresAt());
    }

    public PunishmentModel setId(UUID id) {
        this.id = id;
        return this;
    }

    public PunishmentModel setType(String type) {
        this.type = type;
        return this;
    }

    public PunishmentModel setReason(String reason) {
        this.reason = reason;
        return this;
    }

    public PunishmentModel setPlayerId(UUID playerId) {
        this.playerId = playerId;
        return this;
    }

    public PunishmentModel setIssuedAt(Long issuedAt) {
        this.issuedAt = issuedAt;
        return this;
    }

    public PunishmentModel setActive(boolean active) {
        this.active = active;
        return this;
    }

    public PunishmentModel setExpiresAt(Long expiresAt) {
        this.expiresAt = Optional.of(expiresAt);
        return this;
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

    public Long getIssuedAt() {
        return issuedAt;
    }

    public boolean isActive() {
        return active;
    }

    public Optional<Long> getExpiresAt() {
        return expiresAt;
    }
}