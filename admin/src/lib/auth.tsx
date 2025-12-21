'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { api, User, ApiError } from '@/lib/api';

interface AuthContextType {
    user: User | null;
    token: string | null;
    isLoading: boolean;
    login: (email: string, password: string) => Promise<void>;
    logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const TOKEN_KEY = 'admin_token';
const USER_KEY = 'admin_user';

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Load from localStorage on mount
        const storedToken = localStorage.getItem(TOKEN_KEY);
        const storedUser = localStorage.getItem(USER_KEY);

        if (storedToken && storedUser) {
            setToken(storedToken);
            try {
                const parsedUser = JSON.parse(storedUser);
                if (parsedUser.is_admin) {
                    setUser(parsedUser);
                } else {
                    // Not an admin, clear storage
                    localStorage.removeItem(TOKEN_KEY);
                    localStorage.removeItem(USER_KEY);
                }
            } catch {
                localStorage.removeItem(TOKEN_KEY);
                localStorage.removeItem(USER_KEY);
            }
        }
        setIsLoading(false);
    }, []);

    const login = async (email: string, password: string) => {
        try {
            const response = await api.login(email, password);

            // Check if user is admin
            if (!response.user.isAdmin) {
                throw new Error('管理者権限がありません。');
            }

            setToken(response.access_token);
            setUser(response.user);
            localStorage.setItem(TOKEN_KEY, response.access_token);
            localStorage.setItem(USER_KEY, JSON.stringify(response.user));
        } catch (error) {
            if (error instanceof ApiError) {
                throw new Error(error.message || 'ログインに失敗しました。');
            }
            throw error;
        }
    };

    const logout = () => {
        setToken(null);
        setUser(null);
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
    };

    return (
        <AuthContext.Provider value={{ user, token, isLoading, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}
