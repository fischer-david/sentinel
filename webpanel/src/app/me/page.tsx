"use client";

import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle
} from "@/components/ui/alert-dialog";
import {useRouter} from "next/navigation";
import {signOut, useSession} from "next-auth/react";
import {useEffect, useState} from "react";
import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Alert, AlertDescription} from "@/components/ui/alert";
import {Calendar, CheckCircle2, Loader2, Lock, LogOut, Settings, Shield, User, XCircle} from "lucide-react";
import {changePassword} from "@/lib/grpc/auth";

export const dynamic = 'force-dynamic';

export default function Me() {
    const { data: session, status, update } = useSession();
    const router = useRouter();
    const [newPassword, setNewPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [isChangingPassword, setIsChangingPassword] = useState(false);
    const [passwordError, setPasswordError] = useState("");
    const [passwordSuccess, setPasswordSuccess] = useState(false);

    const [dialogOpen, setDialogOpen] = useState(session?.passwordChangeRequired ?? false);

    useEffect(() => {
        if (status === "unauthenticated") {
            router.push("/auth/signin");
        }
    }, [status, session?.passwordChangeRequired, router]);

    const handlePasswordChange = async (e: React.FormEvent) => {
        e.preventDefault();
        setPasswordError("");
        setPasswordSuccess(false);

        if (newPassword !== confirmPassword) {
            setPasswordError("New passwords don't match");
            return;
        }

        if (newPassword.length < 8) {
            setPasswordError("New password must be at least 8 characters long");
            return;
        }

        setIsChangingPassword(true);

        try {
            const response = await changePassword(newPassword);

            // Update session with new tokens and remove password change requirement
            await update({
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                passwordChangeRequired: false,
            });

            setPasswordSuccess(true);
            setNewPassword("");
            setConfirmPassword("");
            setTimeout(() => {
                setPasswordSuccess(false);
            }, 2000);
        } catch (err) {
            setPasswordError(err instanceof Error ? err.message : "An error occurred");
        } finally {
            setIsChangingPassword(false);
        }
    };

    if (status === "loading") {
        return (
            <div className="min-h-[calc(100vh-5rem)] bg-gradient-to-br from-background via-background to-muted flex items-center justify-center">
                <Card className="w-full max-w-sm">
                    <CardContent className="flex items-center justify-center p-6">
                        <Loader2 className="w-6 h-6 animate-spin mr-2" />
                        <span className="text-muted-foreground">Loading your profile...</span>
                    </CardContent>
                </Card>
            </div>
        );
    }

    if (!session) {
        return null;
    }

    return (
        <>
            <div className="min-h-[calc(100vh-5rem)] bg-gradient-to-br from-background via-background to-muted p-6">
                <div className="max-w-6xl mx-auto">
                    {/* Header */}
                    <div className="text-center mb-12">
                        <div className="flex items-center justify-center mb-6">
                            <div className="relative">
                                <User className="w-16 h-16 text-primary mr-4 drop-shadow-lg"/>
                                <div className="absolute -inset-1 bg-primary/20 rounded-full blur-xl -z-10"></div>
                            </div>
                            <div>
                                <h1 className="text-5xl font-bold bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent mb-2">
                                    My Account
                                </h1>
                                <div
                                    className="h-1 w-24 bg-gradient-to-r from-primary to-accent rounded-full mx-auto"></div>
                            </div>
                        </div>
                        <p className="text-xl text-muted-foreground max-w-2xl mx-auto leading-relaxed">
                            Manage your profile, security settings, and account preferences
                        </p>
                    </div>

                    {/* Main Content Grid */}
                    <div className="grid grid-cols-1 lg:grid-cols-1 w-1/2 m-auto gap-6 mb-8 items-stretch">
                        {/* User Profile Card */}
                        <div className="lg:col-span-1 flex">
                            <Card
                                className="group transition-all duration-300 hover:scale-105 hover:shadow-lg border-2 hover:border-primary w-full flex flex-col">
                                <CardHeader>
                                    <CardTitle className="flex items-center">
                                        <User className="mr-2 h-5 w-5"/>
                                        Profile Information
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="space-y-4 flex-1">
                                    <div className="space-y-3">
                                        <div className="flex items-center space-x-2">
                                            <User className="w-4 h-4 text-muted-foreground"/>
                                            <span className="text-sm text-muted-foreground">Username:</span>
                                            <span className="font-semibold">{session.user?.username}</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <User className="w-4 h-4 text-muted-foreground"/>
                                            <span className="text-sm text-muted-foreground">Account Type:</span>
                                            <span className="font-semibold">{session.user?.staff ? "Staff" : "User"}</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <Shield className="w-4 h-4 text-muted-foreground"/>
                                            <span className="text-sm text-muted-foreground">User ID:</span>
                                            <span className="font-mono text-sm">{session.user?.id}</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <Calendar className="w-4 h-4 text-muted-foreground"/>
                                            <span className="text-sm text-muted-foreground">Session Status:</span>
                                            <span
                                                className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
                                            Active
                                        </span>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        </div>

                        {/* Password Change Form */}
                        <div className="lg:col-span-1 flex">
                            <Card
                                className="group transition-all duration-300 hover:scale-105 hover:shadow-lg border-2 hover:border-primary w-full flex flex-col">
                                <CardHeader>
                                    <CardTitle className="flex items-center">
                                        <Lock className="mr-2 h-5 w-5"/>
                                        Change Password
                                    </CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <form onSubmit={handlePasswordChange} className="space-y-4">
                                        <div className="space-y-2">
                                            <Label htmlFor="new-password">New Password</Label>
                                            <div className="relative">
                                                <Lock
                                                    className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground"/>
                                                <Input
                                                    id="new-password"
                                                    type="password"
                                                    required
                                                    placeholder="Enter new password"
                                                    value={newPassword}
                                                    onChange={(e) => setNewPassword(e.target.value)}
                                                    disabled={isChangingPassword}
                                                    className="pl-10"/>
                                            </div>
                                        </div>

                                        <div className="space-y-2">
                                            <Label htmlFor="confirm-password">Confirm New Password</Label>
                                            <div className="relative">
                                                <Lock
                                                    className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground"/>
                                                <Input
                                                    id="confirm-password"
                                                    type="password"
                                                    required
                                                    placeholder="Confirm new password"
                                                    value={confirmPassword}
                                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                                    disabled={isChangingPassword}
                                                    className="pl-10"/>
                                            </div>
                                        </div>

                                        {passwordError && (
                                            <Alert variant="destructive">
                                                <XCircle className="h-4 w-4"/>
                                                <AlertDescription>{passwordError}</AlertDescription>
                                            </Alert>
                                        )}

                                        {passwordSuccess && (
                                            <Alert
                                                className="border-green-200 bg-green-50 text-green-800 dark:border-green-800 dark:bg-green-950 dark:text-green-300">
                                                <CheckCircle2 className="h-4 w-4"/>
                                                <AlertDescription>Password changed successfully!</AlertDescription>
                                            </Alert>
                                        )}

                                        <div className="flex space-x-3 pt-4">
                                            <Button
                                                type="submit"
                                                disabled={isChangingPassword}
                                                className="flex-1"
                                            >
                                                {isChangingPassword && <Loader2 className="mr-2 h-4 w-4 animate-spin"/>}
                                                {isChangingPassword ? "Changing..." : "Change Password"}
                                            </Button>
                                        </div>
                                    </form>
                                </CardContent>
                            </Card>
                        </div>

                        {/* Quick Actions Card */}
                        <div className="lg:col-span-1 flex">
                            <Card
                                className="group transition-all duration-300 hover:scale-105 hover:shadow-lg border-2 hover:border-primary w-full flex flex-col">
                                <CardHeader>
                                    <CardTitle className="flex items-center">
                                        <Settings className="mr-2 h-5 w-5"/>
                                        Quick Actions
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="flex-1 flex flex-col">
                                    <div className="flex-1"></div>
                                    <div className="space-y-4">
                                        <Button
                                            onClick={() => router.push("/")}
                                            variant="outline"
                                            className="w-full"
                                        >
                                            <Shield className="mr-2 h-4 w-4"/>
                                            Back to Dashboard
                                        </Button>
                                        <Button
                                            onClick={() => signOut({callbackUrl: "/auth/signin"})}
                                            variant="destructive"
                                            className="w-full"
                                        >
                                            <LogOut className="mr-2 h-4 w-4"/>
                                            Sign Out
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        </div>
                    </div>
                </div>
            </div>

            <AlertDialog open={dialogOpen}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Password change required</AlertDialogTitle>
                        <AlertDialogDescription>
                            You must change your password before you can continue.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogAction onClick={() => setDialogOpen(false)}>Continue</AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </>
    );
}
