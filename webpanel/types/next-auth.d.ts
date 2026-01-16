import NextAuth from "next-auth";

declare module "next-auth" {
    interface Session {
        user: {
            id: string;
            username: string;
        };
        refreshToken?: string;
        accessToken?: string;
        expires: number;
        passwordChangeRequired?: boolean;
        error?: string;
    }
}

declare module "next-auth/jwt" {
    interface JWT {
        id: string;
        username: string;
        accessToken?: string;
        refreshToken?: string;
        error?: string;
        passwordChangeRequired?: boolean;
        expires: number;
    }
}
