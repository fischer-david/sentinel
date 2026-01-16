export declare global {
    namespace NodeJS {
        interface ProcessEnv {
            BACKEND_GRPC_URL: string;
        }
    }
}