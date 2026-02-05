package dev.fishigames.sentinel.models;

public class Config {
    private String backend = "172.17.0.1:50051";
    private String baseWebUrl = "http://localhost:3000";

    public String getBackend() {
        return backend;
    }

    public String getBaseWebUrl() {
        return baseWebUrl;
    }
}