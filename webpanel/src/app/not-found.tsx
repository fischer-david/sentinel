"use client";

import Link from 'next/link'
import Image from "next/image";
import {Button} from "@/components/ui/button";
import {Card, CardContent, CardDescription, CardHeader, CardTitle} from "@/components/ui/card";
import {useEffect, useState} from 'react';
import {ArrowLeft, Home, User} from 'lucide-react';

function FloatingOrbs() {
    const [orbs, setOrbs] = useState<Array<{id: number, x: number, y: number, size: number, delay: number}>>([]);

    useEffect(() => {
        const newOrbs = Array.from({ length: 8 }, (_, i) => ({
            id: i,
            x: Math.random() * 100,
            y: Math.random() * 100,
            size: Math.random() * 60 + 40,
            delay: Math.random() * 4
        }));
        setOrbs(newOrbs);
    }, []);

    return (
        <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
            {orbs.map((orb) => (
                <div
                    key={orb.id}
                    className="absolute rounded-full bg-linear-to-br from-primary/5 to-primary/20 blur-xl"
                    style={{
                        left: `${orb.x}%`,
                        top: `${orb.y}%`,
                        width: `${orb.size}px`,
                        height: `${orb.size}px`,
                        animationDelay: `${orb.delay}s`,
                        animation: `pulse 8s ease-in-out infinite`
                    }}
                />
            ))}
        </div>
    );
}

export default function NotFound() {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    return (
        <div className="min-h-[calc(100vh-5rem)] flex items-center justify-center p-4 relative">
            {/* Simplified background */}
            <div className="absolute inset-0 bg-linear-to-br from-background via-muted/30 to-background" />

            {/* Floating orbs */}
            {mounted && <FloatingOrbs />}

            <div className="relative z-10 w-full max-w-2xl">
                <Card className="border-0 shadow-2xl backdrop-blur-sm bg-background/80">
                    <CardHeader className="text-center pb-8 pt-12">
                        {/* Main visual element */}
                        <div className="flex justify-center mb-8">
                            <div className="relative group">
                                <div className="absolute -inset-2 bg-primary/20 rounded-full blur-lg opacity-75 group-hover:opacity-100 transition-opacity duration-300" />
                                <div className="relative">
                                    <Image
                                        src="/question-head.png"
                                        width={120}
                                        height={120}
                                        alt="404 Character"
                                        className="pixelated transform group-hover:scale-105 transition-transform duration-300"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Typography */}
                        <CardTitle className="text-7xl font-bold text-primary mb-4 font-mono">
                            404
                        </CardTitle>
                        <CardDescription className="text-xl font-medium text-muted-foreground mb-2">
                            Page Not Found
                        </CardDescription>
                        <p className="text-muted-foreground max-w-md mx-auto leading-relaxed">
                            The page you're looking for doesn't exist or has been moved.
                        </p>
                    </CardHeader>

                    <CardContent className="text-center pb-12">
                        {/* Primary actions */}
                        <div className="flex flex-col sm:flex-row gap-3 justify-center mb-8">
                            <Button asChild size="lg" className="gap-2">
                                <Link href="/">
                                    <Home className="w-4 h-4" />
                                    Go Home
                                </Link>
                            </Button>
                            <Button asChild variant="outline" size="lg" className="gap-2">
                                <Link href="/me">
                                    <User className="w-4 h-4" />
                                    My Profile
                                </Link>
                            </Button>
                        </div>

                        {/* Secondary actions */}
                        <div className="pt-6 border-t border-border">
                            <p className="text-sm text-muted-foreground mb-4">
                                Need help? Try these options:
                            </p>
                            <div className="flex flex-wrap justify-center gap-4">
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => window.history.back()}
                                    className="gap-2 text-muted-foreground hover:text-foreground"
                                >
                                    <ArrowLeft className="w-3 h-3" />
                                    Go Back
                                </Button>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}