package dev.fishigames.sentinel.proxy.listeners;

import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.connection.DisconnectEvent;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;

public record DisconnectListener(GrpcService grpcService) {

    @Subscribe(priority = 100)
    public void onDisconnect(DisconnectEvent disconnectEvent) {
        var uniqueId = disconnectEvent.getPlayer().getUniqueId();

        if(uniqueId == null) {
            return;
        }

        CacheService.INSTANCE.playerDisconnected(uniqueId);
        grpcService.handlePlayerStatusChange(uniqueId, false);
    }
}