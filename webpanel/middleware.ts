import {withAuth} from "next-auth/middleware"
import {NextResponse} from "next/server"

export default withAuth(
    function middleware(req) {
        const token = req.nextauth.token;
        const pathname = req.nextUrl.pathname;

        if (pathname.startsWith('/_next/') || pathname.startsWith('/api/auth/') || pathname === '/favicon.ico') {
            return NextResponse.next();
        }

        if (token?.passwordChangeRequired) {
            if (pathname !== "/me" && pathname !== "/auth/signout") {
                const redirectUrl = new URL("/me", req.url);
                return NextResponse.redirect(redirectUrl, 307);
            }
        }

        return NextResponse.next()
    },
    {
        callbacks: {
            authorized: ({ token, req }) => {
                if (req.nextUrl.pathname === "/auth/signin") {
                    return true;
                }

                if (req.nextUrl.pathname === "/me") {
                    return true;
                }

                return !!token;
            }
        },
    }
)

export const config = {
    matcher: [
        "/",
        "/((?!_next/static|_next/image|favicon.ico|public/).*)",
    ],
}
