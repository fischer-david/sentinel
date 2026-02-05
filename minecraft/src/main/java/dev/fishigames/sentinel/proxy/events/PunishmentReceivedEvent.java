package dev.fishigames.sentinel.proxy.events;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

public record PunishmentReceivedEvent(PunishmentOuterClass.GetLivePunishmentsResponse punishment) {
}