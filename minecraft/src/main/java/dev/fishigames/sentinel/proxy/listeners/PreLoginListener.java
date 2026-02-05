package dev.fishigames.sentinel.proxy.listeners;

import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.connection.PostLoginEvent;
import com.velocitypowered.api.event.connection.PreLoginEvent;
import dev.fishigames.sentinel.protos.PunishmentOuterClass;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import net.kyori.adventure.text.Component;

public record PreLoginListener(GrpcService grpcService) {

    @Subscribe
    public void onPreLogin(PreLoginEvent preLoginEvent) {
        System.out.println("[SentinelProxy] Handling login event for player: " + preLoginEvent.getUsername());

        var uniqueId = preLoginEvent.getUniqueId();

        if (uniqueId == null) {
            return;
        }

        try {
            var playerLoginResponse = grpcService.handlePlayerLogin(uniqueId);

            if (playerLoginResponse != null) {
                if(playerLoginResponse.getPunishments().hasDisconnectMessage()) {
                    System.out.println("[SentinelProxy] Got a disconnect message for player: " + preLoginEvent.getUsername());

                    preLoginEvent.setResult(
                            PreLoginEvent.PreLoginComponentResult.denied(Component.text(playerLoginResponse
                                    .getPunishments()
                                    .getDisconnectMessage()
                                    .getMessage()
                            )));
                    return;
                }

                CacheService.INSTANCE.playerConnected(uniqueId);
                grpcService.handlePlayerStatusChange(uniqueId, true);
                CacheService.INSTANCE.addPunishment(
                        uniqueId,
                        playerLoginResponse
                );
            }
        } catch (Exception exception) {
            exception.printStackTrace();
        }
    }

    @Subscribe
    public void onPostLogin(PostLoginEvent postLoginEvent) {
        var uniqueId = postLoginEvent.getPlayer().getUniqueId();
        CacheService.INSTANCE.getPunishments(uniqueId).stream()
                .filter(PunishmentOuterClass.PunishmentsWithDetails::hasChatMessage)
                .findFirst().ifPresent(punishmentsWithDetails ->
                        punishmentsWithDetails.getChatMessage().getMessage()
                                .lines().forEach(message ->
                                        postLoginEvent.getPlayer()
                                                .sendMessage(Component.text(message))));
    }
}