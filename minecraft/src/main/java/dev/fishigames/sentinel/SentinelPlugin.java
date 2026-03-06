package dev.fishigames.sentinel;

import dev.fishigames.sentinel.paper.events.PluginPunishmentReceivedEvent;
import dev.fishigames.sentinel.paper.listeners.AsyncChatListener;
import dev.fishigames.sentinel.paper.listeners.PlayerJoinListener;
import dev.fishigames.sentinel.paper.listeners.PlayerQuitListener;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.logging.Logger;

public final class SentinelPlugin extends JavaPlugin {
    private static final Logger LOGGER = Logger.getLogger(SentinelPlugin.class.getName());

    private GrpcService grpcService;

    @Override
    public void onEnable() {
        LOGGER.info("[Sentinel] Initializing Sentinel Plugin...");

        System.setProperty("java.net.preferIPv4Stack", "true");
        System.setProperty("java.net.preferIPv6Addresses", "false");

        var internals = SentinelInternals.create(getDataFolder(), false);

        grpcService = internals.getGrpcService();
        var cacheService = internals.getCacheService();

        registerGrpcListeners(grpcService, cacheService);

        getServer().getPluginManager().registerEvents(new AsyncChatListener(cacheService), this);
        getServer().getPluginManager().registerEvents(new PlayerQuitListener(grpcService, cacheService), this);
        getServer().getPluginManager().registerEvents(new PlayerJoinListener(grpcService, cacheService), this);

        LOGGER.info("[Sentinel] Plugin enabled successfully!");
    }

    @Override
    public void onDisable() {
        if (grpcService != null) {
            grpcService.shutdown();
        }
        LOGGER.info("[Sentinel] Plugin disabled successfully!");
    }

    private void registerGrpcListeners(GrpcService grpcService, CacheService cacheService) {
        grpcService.addStreamListener(response -> getServer().getPluginManager().callEvent(new PluginPunishmentReceivedEvent(response)));

        grpcService.setOnReconnectCallback(() -> {
            LOGGER.info("[Sentinel] Reconnected - re-checking punishments for all online players...");
            getServer().getOnlinePlayers().forEach(player -> {
                var uniqueId = player.getUniqueId();
                try {
                    var loginResponse = grpcService.handlePlayerLogin(uniqueId);
                    if (loginResponse != null) {
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