package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.models.KickPlayerModel;
import dev.fishigames.sentinel.protos.PunishmentOuterClass;
import dev.fishigames.sentinel.protos.PunishmentServiceGrpc;
import io.grpc.stub.StreamObserver;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

public class GrpcService {
    private final PunishmentServiceGrpc.PunishmentServiceBlockingStub punishmentServiceBlockingStub;
    private final PunishmentServiceGrpc.PunishmentServiceStub punishmentServiceStub;

    private StreamObserver<PunishmentOuterClass.GetLivePunishmentsRequest> livePunishmentsStreamObserver;
    private final Consumer<KickPlayerModel> kickPlayer;
    private final Consumer<PunishmentOuterClass.GetLivePunishmentsResponse> punishmentStream;
    private final boolean proxy;

    // Reconnection logic fields
    private final AtomicBoolean isConnected = new AtomicBoolean(false);

    public GrpcService(ConnectionService connectionService,
                       Consumer<KickPlayerModel> kickPlayer,
                       Consumer<PunishmentOuterClass.GetLivePunishmentsResponse> punishmentStream,
                       boolean proxy) {
        this.kickPlayer = kickPlayer;
        this.punishmentStream = punishmentStream;
        this.proxy = proxy;

        punishmentServiceBlockingStub =
                PunishmentServiceGrpc.newBlockingStub(connectionService.getManagedChannel());
        punishmentServiceStub = PunishmentServiceGrpc.newStub(connectionService.getManagedChannel());

        // Initialize as connected
        isConnected.set(true);
        System.out.println("[SentinelProxy] GRPC Service initialized and connected");
    }

    public PunishmentOuterClass.GetPlayerLoginResponse handlePlayerLogin(UUID playerId) {
        return punishmentServiceBlockingStub
                .getPlayerLogin(PunishmentOuterClass.GetPlayerLoginRequest.newBuilder()
                        .setPlayerId(playerId.toString())
                        .build());
    }

    public void handlePlayerStatusChange(UUID playerId, boolean online) {
        try {
            if (livePunishmentsStreamObserver != null && isConnected.get()) {
                livePunishmentsStreamObserver.onNext(PunishmentOuterClass.GetLivePunishmentsRequest.newBuilder()
                        .setPlayerId(playerId.toString())
                        .setOnline(online)
                        .setProxy(proxy)
                        .build());
            } else if (!isConnected.get()) {
                System.out.println("[SentinelProxy] Skipping player status change for " + playerId +
                                 " (online=" + online + ") - not connected to backend");
            }
        } catch (Exception e) {
            System.err.println("[SentinelProxy] Error sending player status change: " + e.getMessage());
        }
    }

    public void registerStreams() {
        livePunishmentsStreamObserver = punishmentServiceStub.getLivePunishments(new StreamObserver<>() {
            @Override
            public void onNext(PunishmentOuterClass.GetLivePunishmentsResponse getLivePunishmentsResponse) {
                var uniqueId = UUID.fromString(getLivePunishmentsResponse.getPunishments().getPlayerId());

                if(getLivePunishmentsResponse.getPunishments().hasDisconnectMessage()) {
                    kickPlayer.accept(
                            new KickPlayerModel()
                                    .setPlayerId(uniqueId)
                                    .setReason(getLivePunishmentsResponse.getPunishments()
                                            .getDisconnectMessage().getMessage())
                    );
                    return;
                }

                punishmentStream.accept(getLivePunishmentsResponse);
            }

            @Override
            public void onError(Throwable throwable) {
                System.err.println("[SentinelProxy] Live punishments stream error: " + throwable.getMessage());
            }

            @Override
            public void onCompleted() {
                System.out.println("[SentinelProxy] Live punishments stream completed");
                isConnected.set(false);
            }
        });
    }
}
