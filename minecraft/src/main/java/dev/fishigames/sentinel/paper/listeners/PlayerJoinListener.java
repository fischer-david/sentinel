package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;

public class PlayerJoinListener implements Listener {

    private final GrpcService grpcService;
    private final CacheService cacheService;

    public PlayerJoinListener(GrpcService grpcService, CacheService cacheService) {
        this.grpcService = grpcService;
        this.cacheService = cacheService;
    }

    @EventHandler
    public void onPlayerJoin(PlayerJoinEvent playerJoinEvent) {
        var uniqueId = playerJoinEvent.getPlayer().getUniqueId();
        cacheService.playerConnected(uniqueId);

        var playerLoginResponse = grpcService.handlePlayerLogin(uniqueId);

        if (playerLoginResponse != null) {
            grpcService.handlePlayerStatusChange(uniqueId, true);
            cacheService.addPunishment(uniqueId, playerLoginResponse);
        }
    }
}