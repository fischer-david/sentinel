package dev.fishigames.sentinel.proxy.listeners;

import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.connection.PostLoginEvent;
import com.velocitypowered.api.event.connection.PreLoginEvent;
import dev.fishigames.sentinel.models.PunishmentsWithDetailsModel;
import dev.fishigames.sentinel.services.CacheService;
import dev.fishigames.sentinel.services.GrpcService;
import net.kyori.adventure.text.Component;

import java.util.logging.Logger;

public class PreLoginListener {
    private static final Logger LOGGER = Logger.getLogger(PreLoginListener.class.getName());

    private final GrpcService grpcService;
    private final CacheService cacheService;

    public PreLoginListener(GrpcService grpcService, CacheService cacheService) {
        this.grpcService = grpcService;
        this.cacheService = cacheService;
    }

    @Subscribe
    public void onPreLogin(PreLoginEvent preLoginEvent) {
        LOGGER.info("[Sentinel] Handling login event for player: " + preLoginEvent.getUsername());

        var uniqueId = preLoginEvent.getUniqueId();
        cacheService.playerConnected(uniqueId);

        try {
            var playerLoginResponse = grpcService.handlePlayerLogin(uniqueId);

            if (playerLoginResponse != null) {
                var punishments = new PunishmentsWithDetailsModel(playerLoginResponse.getPunishments());

                if (punishments.hasDisconnectMessage()) {
                    LOGGER.info("[Sentinel] Got a disconnect message for player: " + preLoginEvent.getUsername());

                    preLoginEvent.setResult(
                            PreLoginEvent.PreLoginComponentResult.denied(Component.text(
                                    punishments.getDisconnectMessage().orElse("")
                            )));
                    return;
                }

                grpcService.handlePlayerStatusChange(uniqueId, true);
                cacheService.addPunishment(uniqueId, playerLoginResponse);
            }
        } catch (Exception exception) {
            exception.printStackTrace();
        }
    }

    @Subscribe
    public void onPostLogin(PostLoginEvent postLoginEvent) {
        var uniqueId = postLoginEvent.getPlayer().getUniqueId();
        cacheService.getPunishments(uniqueId).stream()
                .filter(PunishmentsWithDetailsModel::hasChatMessage)
                .findFirst().ifPresent(punishmentsWithDetails ->
                        punishmentsWithDetails.getChatMessage()
                                .ifPresent(message -> message.lines().forEach(line ->
                                        postLoginEvent.getPlayer()
                                                .sendMessage(Component.text(line)))));
    }
}