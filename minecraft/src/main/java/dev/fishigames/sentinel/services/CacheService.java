package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;

public class CacheService {
    public static final CacheService INSTANCE = new CacheService();
    private final HashMap<UUID, ArrayList<PunishmentOuterClass.PunishmentsWithDetails>> punishments = new HashMap<>();

    public void playerConnected(UUID uuid) {
        punishments.putIfAbsent(uuid, new ArrayList<>());
    }

    public void playerDisconnected(UUID uuid) {
        punishments.remove(uuid);
    }

    public void addPunishment(UUID uuid, PunishmentOuterClass.GetPlayerLoginResponse punishment) {
        this.punishments.computeIfPresent(uuid, (k, existingPunishments) -> {
            existingPunishments.add(punishment.getPunishments());
            return existingPunishments;
        });
    }

    public void addPunishment(UUID uuid, PunishmentOuterClass.GetLivePunishmentsResponse punishment) {
        this.punishments.computeIfPresent(uuid, (k, existingPunishments) -> {
            existingPunishments.add(punishment.getPunishments());
            return existingPunishments;
        });
    }

    public ArrayList<PunishmentOuterClass.PunishmentsWithDetails> getPunishments(UUID uuid) {
        return punishments.get(uuid);
    }
}
