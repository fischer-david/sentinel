package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerQuitEvent;

public class PlayerQuitListener implements Listener {

    private final GrpcService grpcService;
    private final CacheService cacheService;

    public PlayerQuitListener(GrpcService grpcService, CacheService cacheService) {
        this.grpcService = grpcService;
        this.cacheService = cacheService;
    }

    @EventHandler
    public void onPlayerQuit(PlayerQuitEvent playerQuitEvent) {
        var uniqueId = playerQuitEvent.getPlayer().getUniqueId();
        cacheService.playerDisconnected(uniqueId);
        grpcService.handlePlayerStatusChange(uniqueId, false);
    }
}