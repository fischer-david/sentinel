package dev.fishigames.sentinel.proxy.listeners;

import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.connection.DisconnectEvent;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;

public class DisconnectListener {

    private final GrpcService grpcService;
    private final CacheService cacheService;

    public DisconnectListener(GrpcService grpcService, CacheService cacheService) {
        this.grpcService = grpcService;
        this.cacheService = cacheService;
    }

    @Subscribe(priority = 100)
    public void onDisconnect(DisconnectEvent disconnectEvent) {
        var uniqueId = disconnectEvent.getPlayer().getUniqueId();

        if (uniqueId == null) {
            return;
        }

        cacheService.playerDisconnected(uniqueId);
        grpcService.handlePlayerStatusChange(uniqueId, false);
    }
}