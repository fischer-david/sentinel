"use client";

import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Button} from "@/components/ui/button";
import Link from "next/link";
import {Shield} from "lucide-react";
import {useSession} from "next-auth/react";

interface MenuSection {
  title: string;
  description: string;
  icon: React.ComponentType<any>;
  href: string;
  color: string;
  available: boolean;
}

const menuSections: MenuSection[] = [];

export default function HomePage() {
  const {data: session} = useSession({
    required: true
  });

  if (!session) {
    return null;
  }

  return (
      <div className="min-h-[calc(100vh-5rem)] bg-linear-to-br from-background via-background to-muted p-6">
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="flex items-center justify-center mb-6">
              <div className="relative">
                <Shield className="w-16 h-16 text-primary mr-4 drop-shadow-lg" />
                <div className="absolute -inset-1 bg-primary/20 rounded-full blur-xl -z-10"></div>
              </div>
              <div>
                <h1 className="text-5xl font-bold bg-linear-to-r from-primary via-accent to-primary bg-clip-text text-transparent mb-2">
                  Sentinel
                </h1>
                <div className="h-1 w-24 bg-linear-to-r from-primary to-accent rounded-full mx-auto"></div>
              </div>
            </div>
            <p className="text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
              Comprehensive Minecraft server moderation and management system
            </p>
          </div>

          {/* Menu Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {menuSections.map((section) => {
              const IconComponent = section.icon;

              return (
                  <Card
                      key={section.title}
                      className={`group transition-all duration-300 hover:scale-105 hover:shadow-lg border-2 ${
                          section.available
                              ? 'hover:border-primary cursor-pointer'
                              : 'opacity-60 cursor-not-allowed border-muted'
                      }`}
                  >
                    <CardHeader className="pb-3">
                      <div className={`w-12 h-12 rounded-lg bg-linear-to-r ${section.color} p-2.5 mb-3 group-hover:shadow-md transition-shadow`}>
                        <IconComponent className="w-full h-full text-white" />
                      </div>
                      <CardTitle className="text-lg font-semibold">{section.title}</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-0">
                      <p className="text-sm text-muted-foreground mb-4 h-10 overflow-hidden">
                        {section.description}
                      </p>
                      {section.available ? (
                          <Link href={section.href}>
                            <Button className="w-full group-hover:bg-primary/90 transition-colors">
                              Enter
                            </Button>
                          </Link>
                      ) : (
                          <Button disabled className="w-full">
                            Coming Soon
                          </Button>
                      )}
                    </CardContent>
                  </Card>
              );
            })}
          </div>
        </div>
      </div>
  );
}
