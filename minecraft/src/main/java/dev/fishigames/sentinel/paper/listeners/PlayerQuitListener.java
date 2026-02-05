package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerQuitEvent;

public record PlayerQuitListener(GrpcService grpcService) implements Listener {

    @EventHandler
    public void onPlayerQuit(PlayerQuitEvent playerQuitEvent) {
        var uniqueId = playerQuitEvent.getPlayer().getUniqueId();

        CacheService.INSTANCE.playerDisconnected(uniqueId);
        grpcService.handlePlayerStatusChange(uniqueId, false);
    }
}