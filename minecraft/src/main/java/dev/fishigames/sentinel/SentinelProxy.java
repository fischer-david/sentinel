package dev.fishigames.sentinel;

import com.google.inject.Inject;
import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.proxy.ProxyInitializeEvent;
import com.velocitypowered.api.plugin.Plugin;
import com.velocitypowered.api.plugin.annotation.DataDirectory;
import com.velocitypowered.api.proxy.ProxyServer;
import dev.fishigames.sentinel.proxy.events.PunishmentReceivedEvent;
import dev.fishigames.sentinel.proxy.listeners.DisconnectListener;
import dev.fishigames.sentinel.proxy.listeners.PreLoginListener;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.ConfigService;
import dev.fishigames.sentinel.services.ConnectionService;
import dev.fishigames.sentinel.services.GrpcService;
import net.kyori.adventure.text.Component;

import java.nio.file.Path;
import java.util.UUID;

@Plugin(id = "sentinel-proxy")
public class SentinelProxy {
    private final ProxyServer proxyServer;
    private final Path dataFolder;

    private ConnectionService connectionService;
    private GrpcService grpcService;
    private ConfigService configService;

    @Inject
    public SentinelProxy(@DataDirectory Path dataFolder, ProxyServer proxyServer) {
        this.proxyServer = proxyServer;
        this.dataFolder = dataFolder;
    }

    @Subscribe
    public void onProxyInitialization(ProxyInitializeEvent event) {
        System.setProperty("java.net.preferIPv4Stack", "true");
        System.setProperty("java.net.preferIPv6Addresses", "false");

        configService = new ConfigService(dataFolder.toFile());
        connectionService = new ConnectionService(configService);

        grpcService = new GrpcService(connectionService,
                kickPlayerModel -> proxyServer.getPlayer(kickPlayerModel.getPlayerId())
                        .ifPresent(player -> player.disconnect(Component.text(kickPlayerModel.getReason()))),
                punishmentModel -> {
                    CacheService.INSTANCE.addPunishment(UUID.fromString(punishmentModel.getPunishments().getPlayerId()), punishmentModel);
                    proxyServer.getEventManager().fireAndForget(new PunishmentReceivedEvent(punishmentModel));
        }, false);

        System.out.println("[SentinelProxy] Initializing Sentinel Proxy Plugin...");

        grpcService.registerStreams();
        proxyServer.getEventManager().register(this, new PreLoginListener(grpcService));
        proxyServer.getEventManager().register(this, new DisconnectListener(grpcService));
    }
}