package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;
import dev.fishigames.sentinel.protos.PunishmentServiceGrpc;
import io.grpc.stub.StreamObserver;

import java.util.HashMap;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;
import java.util.logging.Logger;

public class GrpcService {
    private static final Logger LOGGER = Logger.getLogger(GrpcService.class.getName());
    private static final long RECONNECT_INITIAL_DELAY_SECONDS = 5;
    private static final long RECONNECT_MAX_DELAY_SECONDS = 60;

    private final PunishmentServiceGrpc.PunishmentServiceBlockingStub punishmentServiceBlockingStub;
    private final PunishmentServiceGrpc.PunishmentServiceStub punishmentServiceStub;

    private StreamObserver<PunishmentOuterClass.GetLivePunishmentsRequest> livePunishmentsStreamObserver;
    private final boolean proxy;

    private final HashMap<UUID, Consumer<PunishmentOuterClass.GetLivePunishmentsResponse>> punishmentStreams = new HashMap<>();
    private final AtomicBoolean isReconnecting = new AtomicBoolean(false);
    private final AtomicInteger reconnectAttempts = new AtomicInteger(0);

    private final CacheService cacheService;
    private final ScheduledExecutorService reconnectScheduler = Executors.newSingleThreadScheduledExecutor(runnable -> {
        var thread = new Thread(runnable, "sentinel-reconnect");
        thread.setDaemon(true);
        return thread;
    });

    private Runnable onReconnectCallback;

    public GrpcService(ConnectionService connectionService, CacheService cacheService,
                       boolean proxy) {
        this.proxy = proxy;
        this.cacheService = cacheService;

        punishmentServiceBlockingStub =
                PunishmentServiceGrpc.newBlockingStub(connectionService.getManagedChannel());
        punishmentServiceStub = PunishmentServiceGrpc.newStub(connectionService.getManagedChannel());

        LOGGER.info("[Sentinel] GRPC Service initialized and connected");
    }

    public void setOnReconnectCallback(Runnable onReconnectCallback) {
        this.onReconnectCallback = onReconnectCallback;
    }

    public UUID addStreamListener(Consumer<PunishmentOuterClass.GetLivePunishmentsResponse> consumer) {
        var id = UUID.randomUUID();
        punishmentStreams.put(id, consumer);
        return id;
    }

    public PunishmentOuterClass.GetPlayerLoginResponse handlePlayerLogin(UUID playerId) {
        try {
            return punishmentServiceBlockingStub
                    .getPlayerLogin(PunishmentOuterClass.GetPlayerLoginRequest.newBuilder()
                            .setPlayerId(playerId.toString())
                            .build());
        } catch (Exception exception) {
            LOGGER.warning("[Sentinel] Failed to handle player login for " + playerId + ": " + exception.getMessage());
            return null;
        }
    }

    public void handlePlayerStatusChange(UUID playerId, boolean online) {
        try {
            if (livePunishmentsStreamObserver != null) {
                livePunishmentsStreamObserver.onNext(PunishmentOuterClass.GetLivePunishmentsRequest.newBuilder()
                        .setPlayerId(playerId.toString())
                        .setOnline(online)
                        .setProxy(proxy)
                        .build());
            }
        } catch (Exception exception) {
            LOGGER.warning("[Sentinel] Error sending player status change: " + exception.getMessage());
        }
    }

    public void registerStreams() {
        isReconnecting.set(false);
        reconnectAttempts.set(0);
        livePunishmentsStreamObserver = punishmentServiceStub.getLivePunishments(new StreamObserver<>() {
            @Override
            public void onNext(PunishmentOuterClass.GetLivePunishmentsResponse response) {
                punishmentStreams.forEach((id, consumer) -> consumer.accept(response));
                cacheService.addPunishment(UUID.fromString(response.getPunishments().getPlayerId()), response);
            }

            @Override
            public void onError(Throwable throwable) {
                LOGGER.warning("[Sentinel] Live punishments stream error: " + throwable.getMessage());
                scheduleReconnect();
            }

            @Override
            public void onCompleted() {
                LOGGER.info("[Sentinel] Live punishments stream completed");
                scheduleReconnect();
            }
        });
    }

    private void scheduleReconnect() {
        if (!isReconnecting.compareAndSet(false, true)) {
            return; // already scheduling a reconnect
        }

        int attempt = reconnectAttempts.incrementAndGet();
        long delaySeconds = Math.min(RECONNECT_INITIAL_DELAY_SECONDS * attempt, RECONNECT_MAX_DELAY_SECONDS);

        LOGGER.info("[Sentinel] Scheduling reconnect attempt #" + attempt + " in " + delaySeconds + "s...");
        reconnectScheduler.schedule(this::attemptReconnect, delaySeconds, TimeUnit.SECONDS);
    }

    private void attemptReconnect() {
        isReconnecting.set(false);
        LOGGER.info("[Sentinel] Attempting to reconnect to backend (attempt #" + reconnectAttempts.get() + ")...");
        try {
            registerStreams();
            LOGGER.info("[Sentinel] Reconnected to backend successfully");
            reconnectAttempts.set(0);

            if (onReconnectCallback != null) {
                try {
                    onReconnectCallback.run();
                } catch (Exception exception) {
                    LOGGER.warning("[Sentinel] Error in reconnect callback: " + exception.getMessage());
                }
            }
        } catch (Exception exception) {
            LOGGER.warning("[Sentinel] Reconnect attempt failed: " + exception.getMessage());
            scheduleReconnect();
        }
    }

    public void shutdown() {
        reconnectScheduler.shutdownNow();
    }
}
