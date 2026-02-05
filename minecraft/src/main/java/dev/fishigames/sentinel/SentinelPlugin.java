package dev.fishigames.sentinel;

import dev.fishigames.sentinel.paper.listeners.AsyncChatListener;
import dev.fishigames.sentinel.paper.listeners.PlayerJoinListener;
import dev.fishigames.sentinel.paper.listeners.PlayerQuitListener;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.ConfigService;
import dev.fishigames.sentinel.services.ConnectionService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.UUID;

public final class SentinelPlugin extends JavaPlugin {

    @Override
    public void onEnable() {
        System.setProperty("java.net.preferIPv4Stack", "true");
        System.setProperty("java.net.preferIPv6Addresses", "false");

        var configService = new ConfigService(getDataFolder());
        var connectionService = new ConnectionService(configService);

        var grpcService = new GrpcService(connectionService,
                kickPlayerModel -> {},
                punishmentModel -> CacheService.INSTANCE.addPunishment(
                        UUID.fromString(punishmentModel.getPunishments().getPlayerId()),
                        punishmentModel
                ),
                false);

        grpcService.registerStreams();

        getServer().getPluginManager().registerEvents(new AsyncChatListener(), this);
        getServer().getPluginManager().registerEvents(new PlayerQuitListener(grpcService), this);
        getServer().getPluginManager().registerEvents(new PlayerJoinListener(grpcService), this);

        System.out.println("[SentinelPlugin] Sentinel Plugin enabled successfully!");
    }

    @Override
    public void onDisable() {
        System.out.println("[SentinelPlugin] Sentinel Plugin disabled successfully!");
    }
}