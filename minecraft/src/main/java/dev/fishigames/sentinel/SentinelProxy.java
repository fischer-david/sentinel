package dev.fishigames.sentinel;

import com.google.inject.Inject;
import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.proxy.ProxyInitializeEvent;
import com.velocitypowered.api.event.proxy.ProxyShutdownEvent;
import com.velocitypowered.api.plugin.Plugin;
import com.velocitypowered.api.plugin.annotation.DataDirectory;
import com.velocitypowered.api.proxy.ProxyServer;
import dev.fishigames.sentinel.models.KickPlayerModel;
import dev.fishigames.sentinel.models.PunishmentsWithDetailsModel;
import dev.fishigames.sentinel.proxy.events.ProxyPunishmentReceivedEvent;
import dev.fishigames.sentinel.proxy.listeners.DisconnectListener;
import dev.fishigames.sentinel.proxy.listeners.PreLoginListener;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import net.kyori.adventure.text.Component;

import java.nio.file.Path;
import java.util.UUID;
import java.util.logging.Logger;

@Plugin(id = "sentinel-proxy")
public class SentinelProxy {
    private static final Logger LOGGER = Logger.getLogger(SentinelProxy.class.getName());

    private final ProxyServer proxyServer;
    private final Path dataFolder;

    private GrpcService grpcService;

    @Inject
    public SentinelProxy(@DataDirectory Path dataFolder, ProxyServer proxyServer) {
        this.proxyServer = proxyServer;
        this.dataFolder = dataFolder;
    }

    @Subscribe
    public void onProxyInitialization(ProxyInitializeEvent proxyInitializeEvent) {
        LOGGER.info("[Sentinel] Initializing Sentinel Proxy Plugin...");

        System.setProperty("java.net.preferIPv4Stack", "true");
        System.setProperty("java.net.preferIPv6Addresses", "false");

        var internals = SentinelInternals.create(dataFolder.toFile(), true);

        grpcService = internals.getGrpcService();
        var cacheService = internals.getCacheService();

        registerGrpcListeners(grpcService, cacheService);

        proxyServer.getEventManager().register(this, new PreLoginListener(grpcService, cacheService));
        proxyServer.getEventManager().register(this, new DisconnectListener(grpcService, cacheService));

        LOGGER.info("[Sentinel] Proxy Plugin enabled successfully!");
    }

    @Subscribe
    public void onProxyShutdown(ProxyShutdownEvent proxyShutdownEvent) {
        if (grpcService != null) {
            grpcService.shutdown();
        }
        LOGGER.info("[Sentinel] Proxy Plugin disabled successfully!");
    }

    private void registerGrpcListeners(GrpcService grpcService, CacheService cacheService) {
        grpcService.addStreamListener(response -> {
            proxyServer.getEventManager().fireAndForget(new ProxyPunishmentReceivedEvent(response));

            if (response.getPunishments().hasDisconnectMessage()) {
                var kickPlayerModel = new KickPlayerModel(
                        UUID.fromString(response.getPunishments().getPlayerId()),
                        response.getPunishments().getDisconnectMessage().getMessage()
                );

                proxyServer.getPlayer(kickPlayerModel.playerId())
                        .ifPresent(player -> player.disconnect(Component.text(kickPlayerModel.reason())));
            }
        });

        grpcService.setOnReconnectCallback(() -> {
            LOGGER.info("[Sentinel] Reconnected - re-checking punishments for all online players...");
            proxyServer.getAllPlayers().forEach(player -> {
                var uniqueId = player.getUniqueId();
                try {
                    var loginResponse = grpcService.handlePlayerLogin(uniqueId);
                    if (loginResponse != null) {
                        var punishments = new PunishmentsWithDetailsModel(loginResponse.getPunishments());

                        if (punishments.hasDisconnectMessage()) {
                            punishments.getDisconnectMessage().ifPresent(message ->
                                    player.disconnect(Component.text(message)));
                            return;
                        }

                        cacheService.clearPunishments(uniqueId);
                        cacheService.addPunishment(uniqueId, loginResponse);
                        grpcService.handlePlayerStatusChange(uniqueId, true);
                    }
                } catch (Exception exception) {
                    LOGGER.warning("[Sentinel] Failed to re-check punishment for " + uniqueId + ": " + exception.getMessage());
                }
            });
        });

        grpcService.registerStreams();
    }
}