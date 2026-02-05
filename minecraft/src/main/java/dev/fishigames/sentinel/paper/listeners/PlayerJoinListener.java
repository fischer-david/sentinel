package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;

public record PlayerJoinListener(GrpcService grpcService) implements Listener {

    @EventHandler
    public void onPlayerJoin(PlayerJoinEvent playerJoinEvent) {
        var uniqueId = playerJoinEvent.getPlayer().getUniqueId();
        var playerLoginResponse = grpcService.handlePlayerLogin(uniqueId);

        if (playerLoginResponse != null) {
            CacheService.INSTANCE.playerConnected(uniqueId);
            grpcService.handlePlayerStatusChange(uniqueId, true);
            CacheService.INSTANCE.addPunishment(
                    uniqueId,
                    playerLoginResponse
            );
        }
    }
}