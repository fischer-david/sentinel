package dev.fishigames.sentinel.models;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public class PunishmentsWithDetailsModel {
    private final UUID playerId;
    private final List<PunishmentModel> punishments;
    private final Optional<String> disconnectMessage;
    private final Optional<String> chatMessage;

    public PunishmentsWithDetailsModel(PunishmentOuterClass.PunishmentsWithDetails punishmentsWithDetails) {
        this(
            UUID.fromString(punishmentsWithDetails.getPlayerId()),
            PunishmentModel.fromList(punishmentsWithDetails.getPunishmentList()),
            punishmentsWithDetails.hasDisconnectMessage() ? Optional.of(punishmentsWithDetails.getDisconnectMessage().getMessage()) : Optional.empty(),
            punishmentsWithDetails.hasChatMessage() ? Optional.of(punishmentsWithDetails.getChatMessage().getMessage()) : Optional.empty()
        );
    }

    public PunishmentsWithDetailsModel(UUID playerId, List<PunishmentModel> punishments, Optional<String> disconnectMessage, Optional<String> chatMessage) {
        this.playerId = playerId;
        this.punishments = punishments;
        this.disconnectMessage = disconnectMessage;
        this.chatMessage = chatMessage;
    }

    public boolean hasDisconnectMessage() {
        return disconnectMessage.isPresent();
    }

    public boolean hasChatMessage() {
        return chatMessage.isPresent();
    }

    public UUID getPlayerId() {
        return playerId;
    }

    public List<PunishmentModel> getPunishments() {
        return punishments;
    }

    public Optional<String> getDisconnectMessage() {
        return disconnectMessage;
    }

    public Optional<String> getChatMessage() {
        return chatMessage;
    }
}