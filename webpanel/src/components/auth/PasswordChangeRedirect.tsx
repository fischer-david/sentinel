"use client";

import {useSession} from "next-auth/react";
import {usePathname, useRouter} from "next/navigation";
import {useEffect} from "react";

export default function PasswordChangeRedirect() {
    const { data: session, status } = useSession();
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        if (status === "loading") return;

        if (session?.passwordChangeRequired) {
            if (pathname !== "/me" && pathname !== "/auth/signout") {
                router.push("/me");
            }
        }
    }, [session, pathname, router, status]);

    return null;
}
