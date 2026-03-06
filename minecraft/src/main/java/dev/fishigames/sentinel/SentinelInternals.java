package dev.fishigames.sentinel;

import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.ConfigService;
import dev.fishigames.sentinel.services.ConnectionService;
import dev.fishigames.sentinel.services.GrpcService;

import java.io.File;

public class SentinelInternals {

    private final ConfigService configService;
    private final ConnectionService connectionService;
    private final GrpcService grpcService;
    private final CacheService cacheService;

    private SentinelInternals(File dataFolder, boolean proxy) {
        this.cacheService = new CacheService();
        this.configService = new ConfigService(dataFolder);
        this.connectionService = new ConnectionService(this.configService);
        this.grpcService = new GrpcService(this.connectionService, this.cacheService, proxy);
    }

    public static SentinelInternals create(File dataFolder, boolean proxy) {
        return new SentinelInternals(dataFolder, proxy);
    }

    public ConfigService getConfigService() {
        return configService;
    }

    public ConnectionService getConnectionService() {
        return connectionService;
    }

    public GrpcService getGrpcService() {
        return grpcService;
    }

    public CacheService getCacheService() {
        return cacheService;
    }
}