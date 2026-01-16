"use client";

import {getSession, signIn} from "next-auth/react";
import {FormEvent, Suspense, useEffect, useState} from "react";
import {useRouter, useSearchParams} from "next/navigation";
import {Card, CardContent, CardDescription, CardHeader, CardTitle} from "@/components/ui/card";
import {Input} from "@/components/ui/input";
import {Button} from "@/components/ui/button";
import {Label} from "@/components/ui/label";
import {Alert, AlertDescription} from "@/components/ui/alert";
import {Loader2, Lock, User} from "lucide-react";

export default function SignIn() {
  return (
      <Suspense fallback={
        <div className="min-h-[calc(100vh-5rem)] flex items-center justify-center ">
          <div className="text-gray-600">Loading...</div>
        </div>
      }>
        <SignInForm />
      </Suspense>
  );
}

function SignInForm() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [username, setUsername] = useState(searchParams.get("username") || "");
  const [password, setPassword] = useState(searchParams.get("password") || "");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const callbackUrl = searchParams.get("callbackUrl") || "/";

  useEffect(() => {
    getSession().then((session) => {
      if (session) {
        router.push(callbackUrl);
      }
    });
  }, [callbackUrl, router]);

  const handleSubmit = async (formEvent: FormEvent) => {
    formEvent.preventDefault();
    setLoading(true);
    setError("");

    try {
      try {
        const result = await signIn("credentials", {
          username,
          password,
          redirect: false,
        });

        if(result?.ok) {
          router.push(callbackUrl);
        } else {
          setError("Invalid credentials");
        }
      } catch {
        setError("An error occurred");
      }
    } catch (err) {
      setError("An error occurred");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
      <div className="min-h-[calc(100vh-5rem)] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <Card className="w-full max-w-md">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl font-bold text-center">Sign In</CardTitle>
            <CardDescription className="text-center">
              To your Minecraft Account
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="username">Username</Label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input
                      id="username"
                      name="username"
                      type="text"
                      autoComplete="username"
                      required
                      placeholder="Username"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      disabled={loading}
                      className="pl-10"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                      id="password"
                      name="password"
                      type="password"
                      autoComplete="current-password"
                      required
                      placeholder="Password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      disabled={loading}
                      className="pl-10"
                  />
                </div>
              </div>

              {error && (
                  <Alert variant="destructive">
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
              )}

              <Button
                  type="submit"
                  disabled={loading}
                  className="w-full"
              >
                {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {loading ? "Signing in..." : "Sign In"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
  );
}
