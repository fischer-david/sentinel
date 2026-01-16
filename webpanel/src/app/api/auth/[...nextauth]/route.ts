import NextAuth, {NextAuthOptions} from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import {JWT} from "next-auth/jwt";
import {login, refresh} from "@/lib/grpc/auth";
import {jwtDecode, JwtPayload} from "jwt-decode";

interface JwtDecoded extends JwtPayload {
    username: string;
    sub: string;
    token_type: TokenType;
    exp: number;
}

enum TokenType {
    Access = "Access",                              // Normal authenticated user
    PasswordChangeOnly = "PasswordChangeOnly",      // Limited access - only for password changes
    Refresh = "Refresh",                            // Refresh token
}

export const authOptions: NextAuthOptions = {
    providers: [
        CredentialsProvider({
            name: "Backend",
            credentials: {
                username: { label: "Username", type: "text" },
                password: { label: "Password", type: "password" },
            },
            async authorize(credentials) {
                if(!credentials?.username || !credentials?.password) return null;

                try {
                    const response = await login(credentials.username, credentials.password);
                    const decoded = jwtDecode<JwtDecoded>(response.accessToken);

                    return {
                        id: decoded.sub,
                        username: decoded.username,
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        passwordChangeRequired: decoded.token_type == TokenType.PasswordChangeOnly,
                        expires: decoded.exp,
                    };
                } catch(error: any) {
                    console.error("Error logging in", error);
                    return null;
                }
            },
        }),
    ],

    callbacks: {
        async jwt({ token, user, trigger, session }) {
            if (user && 'accessToken' in user && 'refreshToken' in user && 'username' in user && 'id' in user) {
                token.accessToken = user.accessToken as string;
                token.refreshToken = user.refreshToken as string;
                token.username = user.username as string;
                token.id = user.id as string;
                token.passwordChangeRequired = (user as any).passwordChangeRequired || false;
            }

            if (trigger === "update" && session) {
                if (session.accessToken) {
                    token.accessToken = session.accessToken;

                    try {
                        const decoded = jwtDecode<JwtDecoded>(session.accessToken);
                        token.passwordChangeRequired = decoded.token_type === TokenType.PasswordChangeOnly;
                    } catch (error) {
                        console.error("Error decoding updated token", error);
                    }
                }

                if (session.refreshToken) {
                    token.refreshToken = session.refreshToken;
                }

                if ('passwordChangeRequired' in session) {
                    token.passwordChangeRequired = session.passwordChangeRequired;
                }
            }

            if(!token.username || !token.id || !token.accessToken) {
                return {
                    error: "InvalidTokenError"
                } as JWT;
            }

            const now = Math.floor(Date.now() / 1000);
            let isExpired = false;

            if (token.accessToken) {
                try {
                    const decoded = jwtDecode<JwtDecoded>(token.accessToken as string);
                    isExpired = now >= decoded.exp;
                } catch (error) {
                    console.error("Error decoding token for expiration check", error);
                    isExpired = true;
                }
            }

            if (isExpired && token.refreshToken) {
                try {
                    const response = await refresh(token.refreshToken);
                    const newAccessToken = response.accessToken;
                    token.accessToken = newAccessToken;

                    try {
                        const decoded = jwtDecode<JwtDecoded>(newAccessToken);
                        token.passwordChangeRequired = decoded.token_type === TokenType.PasswordChangeOnly;
                    } catch (error) {
                        console.error("Error decoding refreshed token", error);
                    }

                    if (response.refreshToken) {
                        token.refreshToken = response.refreshToken;
                    }
                } catch (error) {
                    console.error("Error refreshing token", error);
                    return { ...token, error: "RefreshAccessTokenError" };
                }
            }

            return token;
        },

        async session({ session, token }) {
            if (token.error) {
                throw new Error('RefreshAccessTokenError');
            }

            session.user = {
                id: token.id,
                username: token.username,
            };
            session.accessToken = token.accessToken;
            session.refreshToken = token.refreshToken;
            session.passwordChangeRequired = token.passwordChangeRequired;

            if (token.error) {
                session.error = token.error;
            }

            return session;
        },
    },

    pages: {
        signIn: "/auth/signin",
    },
};


const handler = NextAuth(authOptions)
export {handler as GET, handler as POST}