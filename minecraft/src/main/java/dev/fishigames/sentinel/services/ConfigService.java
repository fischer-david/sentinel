package dev.fishigames.sentinel.services;

import dev.fishigames.sentinel.models.Config;
import dev.fishigames.sentinel.utils.JsonConfig;

import java.io.File;
import java.lang.reflect.Field;
import java.util.logging.Logger;

public class ConfigService {
    private static final String ENV_PREFIX = "SENTINEL_CONFIG_";
    private static final Logger LOGGER = Logger.getLogger(ConfigService.class.getName());

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

        applyEnvOverrides(jsonConfig.get());
    }

    private void applyEnvOverrides(Config config) {
        for (Field field : Config.class.getDeclaredFields()) {
            String envKey = ENV_PREFIX + field.getName().toUpperCase();
            String envValue = System.getenv(envKey);

            if (envValue != null && !envValue.isEmpty()) {
                field.setAccessible(true);
                try {
                    if (field.getType() == String.class) {
                        field.set(config, envValue);
                    } else if (field.getType() == boolean.class) {
                        field.set(config, Boolean.parseBoolean(envValue));
                    } else if (field.getType() == int.class) {
                        field.set(config, Integer.parseInt(envValue));
                    } else if (field.getType() == long.class) {
                        field.set(config, Long.parseLong(envValue));
                    }
                } catch (IllegalAccessException illegalAccessException) {
                    LOGGER.warning("[Sentinel] Could not override config field '"
                            + field.getName() + "' from env variable '" + envKey + "': " + illegalAccessException.getMessage());
                }
            }
        }
    }

    public Config getConfig() {
        return jsonConfig.get();
    }
}