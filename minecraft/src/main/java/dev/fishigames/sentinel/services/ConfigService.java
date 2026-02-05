package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.models.Config;
import dev.fishigames.sentinel.utils.JsonConfig;

import java.io.File;

public class ConfigService {
    private final JsonConfig<Config> jsonConfig;

    public ConfigService(File dataFolder) {
        jsonConfig = new JsonConfig<>(dataFolder, "config.json", Config.class);
        load();
    }

    public void load() {
        var config = jsonConfig.get();

        if (config == null) {
            config = new Config();
            jsonConfig.set(config);
            jsonConfig.save();
        }
    }

    public Config getConfig() {
        return jsonConfig.get();
    }
}