package dev.fishigames.sentinel.paper.listeners;

import dev.fishigames.sentinel.protos.PunishmentOuterClass;
import dev.fishigames.sentinel.services.CacheService;
import io.papermc.paper.event.player.AsyncChatEvent;
import net.kyori.adventure.text.Component;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;

public class AsyncChatListener implements Listener {

    @EventHandler
    public void onPlayerChat(AsyncChatEvent asyncChatEvent) {
        var player = asyncChatEvent.getPlayer();
        var uniqueId = player.getUniqueId();
        var punishments = CacheService.INSTANCE.getPunishments(uniqueId);
        punishments.stream().filter(PunishmentOuterClass.PunishmentsWithDetails::hasChatMessage)
                .findFirst().ifPresent(punishmentsWithDetails -> {
                    asyncChatEvent.setCancelled(true);

                    punishmentsWithDetails
                            .getChatMessage()
                            .getMessage()
                            .lines().forEach(message -> player.sendMessage(Component.text(message)));
                });
    }
}
