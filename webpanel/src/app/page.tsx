"use client";

import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Button} from "@/components/ui/button";
import Link from "next/link";
import {AlertTriangle, Crown, Eye, FileText, Shield, Users} from "lucide-react";
import {useSession} from "next-auth/react";

interface MenuSection {
  title: string;
  description: string;
  icon: React.ComponentType<any>;
  href: string;
  color: string;
  available: boolean;
  staffOnly: boolean;
}

const menuSections: MenuSection[] = [
  // Staff sections
  {
    title: "Moderation Panel",
    description: "Review reports and manage player punishments",
    icon: Shield,
    href: "/moderation",
    color: "from-red-500 to-red-600",
    available: true,
    staffOnly: true
  },
  {
    title: "Player Management",
    description: "View player profiles and history",
    icon: Users,
    href: "/players",
    color: "from-green-500 to-green-600",
    available: true,
    staffOnly: true
  },
  {
    title: "Audit Logs",
    description: "View system and staff action logs",
    icon: Eye,
    href: "/audit-logs",
    color: "from-gray-500 to-gray-600",
    available: true,
    staffOnly: true
  },

  // User sections
  {
    title: "My Reports",
    description: "View and manage your submitted reports",
    icon: FileText,
    href: "/reports",
    color: "from-blue-500 to-blue-600",
    available: true,
    staffOnly: false
  },
  {
    title: "Appeal Ban",
    description: "Submit an appeal for your ban or punishment",
    icon: AlertTriangle,
    href: "/appeals",
    color: "from-amber-500 to-orange-500",
    available: true,
    staffOnly: false
  },
];

export default function HomePage() {
  const {data: session} = useSession({
    required: true
  });

  if (!session?.user) {
    return null;
  }

  const isStaff = session.user.staff;
  const filteredMenuSections = menuSections.filter(section => !section.staffOnly || isStaff);

  return (
      <div className="min-h-[calc(100vh-5rem)] bg-linear-to-br from-background via-background to-muted/30 p-6">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="text-center mb-16">
            <div className="max-lg:hidden flex items-center justify-center mb-8">
              <div className="relative">
                <Shield className="w-20 h-20 text-primary mr-6 drop-shadow-lg" />
                <div className="absolute -inset-2 bg-primary/10 rounded-full blur-2xl -z-10"></div>
              </div>
              <div>
                <h1 className="text-6xl font-bold bg-linear-to-r from-primary via-accent to-primary bg-clip-text text-transparent mb-3">
                  Sentinel
                </h1>
                <div className="h-1.5 w-32 bg-linear-to-r from-primary to-accent rounded-full mx-auto"></div>
              </div>
            </div>
            <p className="text-2xl text-muted-foreground max-w-3xl mx-auto leading-relaxed mb-4">
              Comprehensive Minecraft server moderation and management system
            </p>
            <div className="inline-flex items-center px-4 py-2 bg-muted/50 rounded-full">
              <span className="text-sm text-muted-foreground">
                Welcome back, <span className="font-semibold text-foreground">{session?.user?.username || 'User'}</span>
                {isStaff && <span className="ml-2 px-2 py-1 bg-primary/10 text-primary text-xs rounded-full">Staff</span>}
              </span>
            </div>
          </div>

          {/* Menu Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-8 lg:gap-4">
            {filteredMenuSections.map((section, index) => {
              const IconComponent = section.icon;
              const totalItems = filteredMenuSections.length;
              const completeRows = Math.floor(totalItems / 3);
              const remainingItems = totalItems % 3;
              const isInLastRow = index >= completeRows * 3;

              let gridColumn = '';
              if (isInLastRow && remainingItems > 0) {
                const positionInLastRow = index - (completeRows * 3);
                if (remainingItems === 1) {
                  gridColumn = 'lg:col-span-2 lg:col-start-3';
                } else if (remainingItems === 2) {
                  if (positionInLastRow === 0) {
                    gridColumn = 'lg:col-span-2 lg:col-start-2';
                  } else {
                    gridColumn = 'lg:col-span-2 lg:col-start-4';
                  }
                }
              } else {
                gridColumn = 'lg:col-span-2';
              }

              return (
                  <Card
                      key={section.title}
                      className={`group transition-all duration-500 hover:scale-105 hover:shadow-2xl border-0 shadow-lg bg-linear-to-br from-card to-card/80 backdrop-blur-sm h-full flex flex-col w-full max-w-sm mx-auto ${gridColumn} ${
                          section.available
                              ? 'hover:shadow-primary/20 cursor-pointer'
                              : 'opacity-60 cursor-not-allowed'
                      }`}
                  >
                    <CardHeader className="-mb-4">
                      <div className={`w-16 h-16 rounded-2xl bg-linear-to-r ${section.color} p-3 mb-4 group-hover:shadow-lg transition-all duration-300 group-hover:scale-110`}>
                        <IconComponent className="w-full h-full text-white" />
                      </div>
                      <CardTitle className="text-xl font-bold group-hover:text-primary transition-colors">
                        {section.title}
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="pt-2 flex-1 flex flex-col">
                      <p className="text-muted-foreground mb-2 leading-relaxed flex-1">
                        {section.description}
                      </p>
                      <div className="mt-2">
                        {section.available ? (
                            <Link href={section.href}>
                              <Button className="w-full bg-linear-to-r from-primary to-accent hover:from-primary/90 hover:to-accent/90 transition-all duration-300 group-hover:shadow-lg text-white font-semibold py-3">
                                Access
                              </Button>
                            </Link>
                        ) : (
                            <Button disabled className="w-full py-3">
                              Coming Soon
                            </Button>
                        )}
                      </div>
                    </CardContent>
                  </Card>
              );
            })}
          </div>

          {/* Quick Stats or Info Section */}
          {isStaff && (
              <div className="mt-16 p-6 bg-linear-to-r from-muted/50 to-muted/30 rounded-2xl border">
                <h3 className="text-lg font-semibold mb-3 flex items-center">
                  <Crown className="w-5 h-5 mr-2 text-yellow-500" />
                  Staff Quick Access
                </h3>
                <p className="text-muted-foreground mb-4">
                  You have staff privileges. Access advanced moderation tools and analytics above.
                </p>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
                  <div className="p-3 bg-background/50 rounded-lg">
                    <div className="text-2xl font-bold text-primary">--</div>
                    <div className="text-sm text-muted-foreground">Pending Reports</div>
                  </div>
                  <div className="p-3 bg-background/50 rounded-lg">
                    <div className="text-2xl font-bold text-green-500">--</div>
                    <div className="text-sm text-muted-foreground">Online Players</div>
                  </div>
                  <div className="p-3 bg-background/50 rounded-lg">
                    <div className="text-2xl font-bold text-orange-500">--</div>
                    <div className="text-sm text-muted-foreground">Active Bans</div>
                  </div>
                </div>
              </div>
          )}
        </div>
      </div>
  );
}
