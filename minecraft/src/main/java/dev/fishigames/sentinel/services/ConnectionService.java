package dev.fishigames.sentinel.services;

import io.grpc.ManagedChannel;
import io.grpc.netty.shaded.io.grpc.netty.NettyChannelBuilder;
import io.grpc.netty.shaded.io.netty.channel.nio.NioEventLoopGroup;
import io.grpc.netty.shaded.io.netty.channel.socket.nio.NioSocketChannel;

import java.net.InetSocketAddress;

public class ConnectionService {
    private final ManagedChannel managedChannel;

    public ConnectionService(ConfigService configService) {
        var config = configService.getConfig();
        var backend = config.getBackend();

        var backendHost = backend.split(":")[0];
        var backendPort = Integer.parseInt(backend.split(":")[1]);

        System.out.println("[SentinelProxy] Backend host: " + backendHost + ", port: " + backendPort);

        managedChannel = NettyChannelBuilder
                .forAddress(new InetSocketAddress(backendHost, backendPort))
                .eventLoopGroup(new NioEventLoopGroup())
                .channelType(NioSocketChannel.class)
                .usePlaintext()
                .keepAliveTime(30, java.util.concurrent.TimeUnit.SECONDS)
                .keepAliveTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
                .keepAliveWithoutCalls(true)
                .maxInboundMessageSize(1024 * 1024) // 1MB
                .enableRetry()
                .build();

        System.out.println("[SentinelProxy] Attempting to connect to Sentinel gRPC server at " + config.getBackend());
    }

    public ManagedChannel getManagedChannel() {
        return managedChannel;
    }
}