package dev.fishigames.sentinel.proxy.events;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

public record ProxyPunishmentReceivedEvent(PunishmentOuterClass.GetLivePunishmentsResponse punishment) {}