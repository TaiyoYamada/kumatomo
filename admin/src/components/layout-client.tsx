'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth, AuthProvider } from '@/lib/auth';
import { SidebarProvider, SidebarInset, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/app-sidebar';
import { Separator } from '@/components/ui/separator';

function DashboardLayoutInner({ children }: { children: React.ReactNode }) {
    const { user, isLoading } = useAuth();
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        if (!isLoading && !user && pathname !== '/login') {
            router.push('/login');
        }
    }, [user, isLoading, router, pathname]);

    // Show loading state
    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-amber-50">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-12 h-12 border-4 border-amber-200 border-t-amber-500 rounded-full animate-spin" />
                    <p className="text-muted-foreground">読み込み中...</p>
                </div>
            </div>
        );
    }

    // Don't show sidebar on login page
    if (pathname === '/login') {
        return children;
    }

    // Redirect to login if not authenticated
    if (!user) {
        return null;
    }

    return (
        <SidebarProvider>
            <AppSidebar />
            <SidebarInset>
                <header className="flex h-14 shrink-0 items-center gap-2 border-b border-amber-100 px-4 bg-white/50 backdrop-blur-sm sticky top-0 z-10">
                    <SidebarTrigger className="-ml-1 hover:bg-amber-100" />
                    <Separator orientation="vertical" className="mr-2 h-4 bg-amber-200" />
                    <div className="flex-1" />
                </header>
                <main className="flex-1 p-6 bg-gradient-to-br from-amber-50/50 to-orange-50/30 min-h-[calc(100vh-3.5rem)]">
                    {children}
                </main>
            </SidebarInset>
        </SidebarProvider>
    );
}

export default function RootLayoutClient({ children }: { children: React.ReactNode }) {
    return (
        <AuthProvider>
            <DashboardLayoutInner>{children}</DashboardLayoutInner>
        </AuthProvider>
    );
}
