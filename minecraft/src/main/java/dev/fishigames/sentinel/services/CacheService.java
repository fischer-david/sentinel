package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.models.PunishmentsWithDetailsModel;
import dev.fishigames.sentinel.protos.PunishmentOuterClass;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;

public class CacheService {
    private final HashMap<UUID, ArrayList<PunishmentsWithDetailsModel>> punishments = new HashMap<>();

    public void playerConnected(UUID uuid) {
        punishments.putIfAbsent(uuid, new ArrayList<>());
    }

    public void playerDisconnected(UUID uuid) {
        punishments.remove(uuid);
    }

    public void addPunishment(UUID uuid, PunishmentOuterClass.GetPlayerLoginResponse punishment) {
        this.punishments.computeIfPresent(uuid, (k, existingPunishments) -> {
            existingPunishments.add(new PunishmentsWithDetailsModel(punishment.getPunishments()));
            return existingPunishments;
        });
    }

    public void addPunishment(UUID uuid, PunishmentOuterClass.GetLivePunishmentsResponse punishment) {
        this.punishments.computeIfPresent(uuid, (k, existingPunishments) -> {
            existingPunishments.add(new PunishmentsWithDetailsModel(punishment.getPunishments()));
            return existingPunishments;
        });
    }

    public void clearPunishments(UUID uuid) {
        punishments.computeIfPresent(uuid, (k, v) -> {
            v.clear();
            return v;
        });
    }

    public ArrayList<PunishmentsWithDetailsModel> getPunishments(UUID uuid) {
        return punishments.get(uuid);
    }
}
