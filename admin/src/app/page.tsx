'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api, UserStats, PostStats } from '@/lib/api';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

interface Stats {
  users: UserStats | null;
  posts: PostStats | null;
}

export default function DashboardPage() {
  const { token } = useAuth();
  const [stats, setStats] = useState<Stats>({ users: null, posts: null });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      if (!token) return;
      try {
        const [userStats, postStats] = await Promise.all([
          api.getUserStats(token),
          api.getPostStats(token),
        ]);
        setStats({ users: userStats, posts: postStats });
      } catch (error) {
        console.error('Failed to fetch stats:', error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchStats();
  }, [token]);

  const statCards = [
    {
      title: '総ユーザー数',
      value: stats.users?.total_users ?? 0,
      description: '登録済みユーザー',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
      color: 'from-blue-500 to-cyan-500',
    },
    {
      title: '総投稿数',
      value: stats.posts?.total_posts ?? 0,
      description: '全ての投稿',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
      ),
      color: 'from-purple-500 to-pink-500',
    },
    {
      title: '今日の新規ユーザー',
      value: stats.users?.new_users_today ?? 0,
      description: '本日の登録',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
        </svg>
      ),
      color: 'from-amber-500 to-orange-500',
    },
    {
      title: '今日の新規投稿',
      value: stats.posts?.new_posts_today ?? 0,
      description: '本日の投稿',
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
        </svg>
      ),
      color: 'from-emerald-500 to-teal-500',
    },
  ];

  const weeklyStats = [
    { label: '今週の新規ユーザー', value: stats.users?.new_users_this_week ?? 0 },
    { label: '今週の新規投稿', value: stats.posts?.new_posts_this_week ?? 0 },
    { label: '今月の新規ユーザー', value: stats.users?.new_users_this_month ?? 0 },
    { label: '今月の新規投稿', value: stats.posts?.new_posts_this_month ?? 0 },
    { label: '管理者数', value: stats.users?.admin_users ?? 0 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">ダッシュボード</h1>
        <p className="text-muted-foreground">kumatomoアプリの管理画面へようこそ</p>
      </div>

      {/* Main Stats */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat, index) => (
          <Card key={index} className="overflow-hidden">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className={`p-2 rounded-lg bg-gradient-to-br ${stat.color} text-white shadow-md`}>
                {stat.icon}
              </div>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-8 w-20 bg-gray-200 rounded animate-pulse" />
              ) : (
                <div className="text-3xl font-bold">{stat.value.toLocaleString()}</div>
              )}
              <p className="text-xs text-muted-foreground mt-1">{stat.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Secondary Stats */}
      <Card>
        <CardHeader>
          <CardTitle>期間別統計</CardTitle>
          <CardDescription>週次・月次の統計情報</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-5">
            {weeklyStats.map((stat, index) => (
              <div key={index} className="text-center p-4 rounded-lg bg-amber-50 border border-amber-100">
                {isLoading ? (
                  <div className="h-8 w-16 bg-amber-200/50 rounded animate-pulse mx-auto mb-1" />
                ) : (
                  <div className="text-2xl font-bold text-amber-700">{stat.value.toLocaleString()}</div>
                )}
                <p className="text-sm text-amber-600">{stat.label}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
