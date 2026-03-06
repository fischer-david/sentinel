package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.models.PunishmentsWithDetailsModel;
import dev.fishigames.sentinel.services.CacheService;
import io.papermc.paper.event.player.AsyncChatEvent;
import net.kyori.adventure.text.Component;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;

public class AsyncChatListener implements Listener {

    private final CacheService cacheService;

    public AsyncChatListener(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @EventHandler
    public void onPlayerChat(AsyncChatEvent asyncChatEvent) {
        var player = asyncChatEvent.getPlayer();
        var uniqueId = player.getUniqueId();
        var punishments = cacheService.getPunishments(uniqueId);
        punishments.stream().filter(PunishmentsWithDetailsModel::hasChatMessage)
                .findFirst().ifPresent(punishmentsWithDetails -> {
                    asyncChatEvent.setCancelled(true);

                    punishmentsWithDetails
                            .getChatMessage()
                            .ifPresent(message -> message.lines()
                                    .forEach(line -> player.sendMessage(Component.text(line))));
                });
    }
}
