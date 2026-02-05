package dev.fishigames.sentinel.utils;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Type;
import java.nio.file.Files;

public class JsonConfig<T> {
    private final File file;
    private final Gson gson;
    private final Type type;
    private T data;

    public JsonConfig(File dataFolder, String fileName, Class<T> clazz) {
        this.file = new File(dataFolder, fileName);
        this.gson = new GsonBuilder().setPrettyPrinting().create();
        this.type = clazz;
        load();
    }

    private void load() {
        try {
            if (!file.exists()) {
                file.getParentFile().mkdirs();
                file.createNewFile();
                data = null;
                return;
            }

            String content = Files.readString(file.toPath());
            if (content.trim().isEmpty() || content.trim().equals("{}")) {
                data = null;
                return;
            }

            data = gson.fromJson(content, type);
        } catch (IOException ioException) {
            ioException.printStackTrace();
        }
    }

    public T get() {
        return data;
    }

    public void set(T data) {
        this.data = data;
    }

    public void save() {
        try (var writer = Files.newBufferedWriter(file.toPath())) {
            if (data != null) {
                gson.toJson(data, writer);
            } else {
                writer.write("{}");
            }
        } catch (IOException ioException) {
            ioException.printStackTrace();
        }
    }
}