"use server";

import * as grpc from '@grpc/grpc-js';

import {AuthenticationServiceClient} from '@/generated/authentication_grpc_pb';
import {
    ChangePasswordRequest as GrpcChangePasswordRequest,
    LoginRequest as GrpcLoginRequest,
    RefreshRequest as GrpcRefreshRequest,
} from "@/generated/authentication_pb";
import {getApplicationSession} from "@/lib/auth/auth";

interface ChangePasswordResponse {
    accessToken: string;
    refreshToken: string | undefined;
}

interface LoginResponse {
    accessToken: string;
    refreshToken: string | undefined;
}

interface RefreshResponse {
    accessToken: string;
    refreshToken: string | undefined;
}

const authenticationServiceClient = new AuthenticationServiceClient(
    process.env.BACKEND_GRPC_URL,
    grpc.credentials.createInsecure()
);

export async function login(username: string, password: string): Promise<LoginResponse> {
    return await new Promise((resolve, reject) => {
        const request = new GrpcLoginRequest();
        request.setUsername(username);
        request.setPassword(password);

        authenticationServiceClient.login(request, (err, response) => {
            if (err) {
                reject(err);
            } else {
                resolve({
                    accessToken: response.getAccessToken(),
                    refreshToken: response.getRefreshToken(),
                });
            }
        });
    });
}

export async function refresh(refreshToken: string): Promise<RefreshResponse> {
    return await new Promise((resolve, reject) => {
        const request = new GrpcRefreshRequest();
        request.setRefreshToken(refreshToken);

        authenticationServiceClient.refresh(request, (err, response) => {
            if (err) {
                reject(err);
            } else {
                resolve({
                    accessToken: response.getAccessToken(),
                    refreshToken: response.getRefreshToken(),
                });
            }
        });
    });
}

export async function changePassword(newPassword: string): Promise<ChangePasswordResponse> {
    return await new Promise(async (resolve, reject) => {
        const request = new GrpcChangePasswordRequest();
        request.setNewPassword(newPassword);

        const metadata = new grpc.Metadata();
        const session = await getApplicationSession();

        if(!session?.accessToken) {
            throw new Error("No access token available");
        }

        metadata.add("authorization", `Bearer ${session.accessToken}`);

        authenticationServiceClient.changePassword(request, metadata, (err, response) => {
            if (err) {
                reject(err);
            } else {
                resolve({
                    accessToken: response.getAccessToken(),
                    refreshToken: response.getRefreshToken(),
                });
            }
        });
    });
}
