'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { api, User, PaginatedResponse } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';

export default function UsersPage() {
    const { token } = useAuth();
    const [users, setUsers] = useState<PaginatedResponse<User> | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [isUpdating, setIsUpdating] = useState(false);

    const fetchUsers = useCallback(async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            const data = await api.getUsers(token, {
                page: String(page),
                per_page: '20',
                ...(search && { search }),
            });
            setUsers(data);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setIsLoading(false);
        }
    }, [token, page, search]);

    useEffect(() => {
        fetchUsers();
    }, [fetchUsers]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
        fetchUsers();
    };

    const handleToggleAdmin = async (user: User) => {
        if (!token) return;
        setIsUpdating(true);
        try {
            await api.updateUser(token, user.id, { is_admin: !user.is_admin });
            fetchUsers();
            setIsDialogOpen(false);
        } catch (error) {
            console.error('Failed to update user:', error);
        } finally {
            setIsUpdating(false);
        }
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('ja-JP', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
        });
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">ユーザー管理</h1>
                    <p className="text-muted-foreground">登録ユーザー一覧の管理</p>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <CardTitle>ユーザー一覧</CardTitle>
                        <form onSubmit={handleSearch} className="flex gap-2">
                            <Input
                                placeholder="名前・ユーザー名・メールで検索"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="w-64"
                            />
                            <Button type="submit" variant="outline">
                                検索
                            </Button>
                        </form>
                    </div>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <div className="space-y-4">
                            {[...Array(5)].map((_, i) => (
                                <div key={i} className="h-16 bg-gray-100 rounded animate-pulse" />
                            ))}
                        </div>
                    ) : (
                        <>
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>ユーザー</TableHead>
                                        <TableHead>ユーザー名</TableHead>
                                        <TableHead>メール</TableHead>
                                        <TableHead className="text-center">フォロワー</TableHead>
                                        <TableHead className="text-center">フォロー中</TableHead>
                                        <TableHead>権限</TableHead>
                                        <TableHead>登録日</TableHead>
                                        <TableHead className="text-right">アクション</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {users?.data.map((user) => (
                                        <TableRow key={user.id}>
                                            <TableCell className="font-medium">
                                                <div className="flex items-center gap-3">
                                                    <Avatar className="h-8 w-8">
                                                        <AvatarImage src={user.profileImageURL || user.profile_image_url} />
                                                        <AvatarFallback className="bg-amber-100 text-amber-700">
                                                            {user.name?.charAt(0) || '?'}
                                                        </AvatarFallback>
                                                    </Avatar>
                                                    <span>{user.name}</span>
                                                </div>
                                            </TableCell>
                                            <TableCell>@{user.username}</TableCell>
                                            <TableCell>{user.email}</TableCell>
                                            <TableCell className="text-center">
                                                <span className="text-muted-foreground">{user.followers_count ?? 0}</span>
                                            </TableCell>
                                            <TableCell className="text-center">
                                                <span className="text-muted-foreground">{user.following_count ?? 0}</span>
                                            </TableCell>
                                            <TableCell>
                                                {user.is_admin ? (
                                                    <Badge className="bg-amber-500 hover:bg-amber-600">管理者</Badge>
                                                ) : (
                                                    <Badge variant="secondary">一般</Badge>
                                                )}
                                            </TableCell>
                                            <TableCell>{formatDate(user.created_at)}</TableCell>
                                            <TableCell className="text-right">
                                                <Button
                                                    variant="ghost"
                                                    size="sm"
                                                    onClick={() => {
                                                        setSelectedUser(user);
                                                        setIsDialogOpen(true);
                                                    }}
                                                >
                                                    詳細
                                                </Button>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>

                            {/* Pagination */}
                            {users && users.last_page > 1 && (
                                <div className="flex items-center justify-center gap-2 mt-6">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(page - 1)}
                                        disabled={page === 1}
                                    >
                                        前へ
                                    </Button>
                                    <span className="text-sm text-muted-foreground">
                                        {page} / {users.last_page} ページ
                                    </span>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(page + 1)}
                                        disabled={page === users.last_page}
                                    >
                                        次へ
                                    </Button>
                                </div>
                            )}
                        </>
                    )}
                </CardContent>
            </Card>

            {/* User Detail Dialog */}
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>ユーザー詳細</DialogTitle>
                        <DialogDescription>ユーザー情報の確認と権限の変更</DialogDescription>
                    </DialogHeader>
                    {selectedUser && (
                        <div className="space-y-4">
                            <div className="flex items-center gap-4">
                                <Avatar className="h-16 w-16">
                                    <AvatarImage src={selectedUser.profileImageURL || selectedUser.profile_image_url} />
                                    <AvatarFallback className="bg-amber-100 text-amber-700 text-xl">
                                        {selectedUser.name?.charAt(0) || '?'}
                                    </AvatarFallback>
                                </Avatar>
                                <div>
                                    <h3 className="font-semibold text-lg">{selectedUser.name}</h3>
                                    <p className="text-muted-foreground">@{selectedUser.username}</p>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4 text-sm">
                                <div>
                                    <span className="text-muted-foreground">メール:</span>
                                    <p>{selectedUser.email}</p>
                                </div>
                                <div>
                                    <span className="text-muted-foreground">登録日:</span>
                                    <p>{formatDate(selectedUser.created_at)}</p>
                                </div>
                                <div>
                                    <span className="text-muted-foreground">場所:</span>
                                    <p>{selectedUser.location || '-'}</p>
                                </div>
                                <div>
                                    <span className="text-muted-foreground">権限:</span>
                                    <p>{selectedUser.is_admin ? '管理者' : '一般ユーザー'}</p>
                                </div>
                            </div>
                            {selectedUser.bio && (
                                <div>
                                    <span className="text-muted-foreground text-sm">自己紹介:</span>
                                    <p className="text-sm mt-1">{selectedUser.bio}</p>
                                </div>
                            )}
                        </div>
                    )}
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                            閉じる
                        </Button>
                        {selectedUser && (
                            <Button
                                onClick={() => handleToggleAdmin(selectedUser)}
                                disabled={isUpdating}
                                variant={selectedUser.is_admin ? 'destructive' : 'default'}
                                className={!selectedUser.is_admin ? 'bg-amber-500 hover:bg-amber-600' : ''}
                            >
                                {isUpdating ? '更新中...' : selectedUser.is_admin ? '管理者権限を外す' : '管理者にする'}
                            </Button>
                        )}
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
