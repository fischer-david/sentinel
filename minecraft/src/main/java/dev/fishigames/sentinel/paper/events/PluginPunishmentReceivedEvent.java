package dev.fishigames.sentinel.paper.events;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;
import org.bukkit.event.Event;
import org.bukkit.event.HandlerList;
import org.jetbrains.annotations.NotNull;

public class PluginPunishmentReceivedEvent extends Event {
    private static final HandlerList HANDLER_LIST = new HandlerList();

    private final PunishmentOuterClass.GetLivePunishmentsResponse response;

    public PluginPunishmentReceivedEvent(PunishmentOuterClass.GetLivePunishmentsResponse response) {
        this.response = response;
    }

    @Override
    public @NotNull HandlerList getHandlers() {
        return HANDLER_LIST;
    }

    public PunishmentOuterClass.GetLivePunishmentsResponse getResponse() {
        return response;
    }
}