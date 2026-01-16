"use client";

import {useSession} from "next-auth/react";
import {Shield} from "lucide-react";
import Image from 'next/image'
import Link from "next/link";

export default function Header() {
    const session = useSession();

    return (
        <header className={`${session?.data?.user?.username ? 'border-b' : 'mt-20 -mb-20'} fixed top-0 left-0 right-0 z-50 bg-background/95 backdrop-blur supports-backdrop-filter:bg-background/60`}>
            <div className={`container flex h-16 items-center px-4 m-auto ${session?.data?.user?.username ? 'justify-between' : 'justify-center'}`}>
                <Link href={"/"} className="flex items-center space-x-3">
                    <Shield className={`${session?.data?.user?.username ? 'h-8 w-8' : 'h-10 w-10'} text-primary`} />
                    <h1 className={`${session?.data?.user?.username ? 'text-2xl' : 'text-4xl'} font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent`}>Sentinel</h1>
                </Link>

                {session?.data?.user?.username &&
                    <Link href="/me" passHref>
                        <div className="flex items-center space-x-4">
                            <div className="flex items-center space-x-2 cursor-pointer p-2 rounded-md hover:bg-muted transition-colors">
                                <Image
                                    className={"bg-gray-300 rounded-sm flex items-center justify-center"}
                                    src={`https://mc-heads.net/avatar/${session.data.user.id}/32`}
                                    alt={`${session.data.user.username}'s Minecraft avatar`}
                                    width={32}
                                    height={32}
                                />
                                <span className="text-sm font-medium">{session?.data?.user?.username}</span>
                            </div>
                        </div>
                    </Link>
                }
            </div>
        </header>
    )
}