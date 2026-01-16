import type {Metadata} from "next";
import {Geist, Geist_Mono} from "next/font/google";
import "./globals.css";
import SessionProviderWrapper from "@/components/auth/SessionProviderWrapper";
import PasswordChangeRedirect from "@/components/auth/PasswordChangeRedirect";
import {getApplicationSession} from "@/lib/auth/auth";
import {ReactNode} from "react";
import Header from "@/components/layout/Header";
import {ThemeProvider} from "@/components/layout/ThemeProvider";

const geistSans = Geist({
    variable: "--font-geist-sans",
    subsets: ["latin"],
});

const geistMono = Geist_Mono({
    variable: "--font-geist-mono",
    subsets: ["latin"],
});

export const metadata: Metadata = {
    title: "Sentinel",
    description: "Sentinel is a minecraft server moderation software",
};

export default async function RootLayout({
                                             children,
                                         }: Readonly<{
    children: ReactNode;
}>) {
    const session = await getApplicationSession();

    return (
        <html lang="en" suppressHydrationWarning>
        <body
            className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        >
        <SessionProviderWrapper session={session}>
            <PasswordChangeRedirect />
            <ThemeProvider
                attribute="class"
                defaultTheme="system"
                enableSystem
                disableTransitionOnChange
            >
                <Header/>
                <div className={"mt-20"}>
                    {children}
                </div>
            </ThemeProvider>
        </SessionProviderWrapper>
        </body>
        </html>
    );
}
