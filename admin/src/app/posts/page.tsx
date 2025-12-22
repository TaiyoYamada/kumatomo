'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { api, Post, PaginatedResponse } from '@/lib/api';
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

export default function PostsPage() {
    const { token } = useAuth();
    const [posts, setPosts] = useState<PaginatedResponse<Post> | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [selectedPost, setSelectedPost] = useState<Post | null>(null);
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
    const [isDeleting, setIsDeleting] = useState(false);

    const fetchPosts = useCallback(async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            const data = await api.getPosts(token, {
                page: String(page),
                per_page: '20',
                ...(search && { search }),
            });
            setPosts(data);
        } catch (error) {
            console.error('Failed to fetch posts:', error);
        } finally {
            setIsLoading(false);
        }
    }, [token, page, search]);

    useEffect(() => {
        fetchPosts();
    }, [fetchPosts]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
        fetchPosts();
    };

    const handleDelete = async () => {
        if (!token || !selectedPost) return;
        setIsDeleting(true);
        try {
            await api.deletePost(token, selectedPost.id);
            fetchPosts();
            setIsDeleteDialogOpen(false);
            setSelectedPost(null);
        } catch (error) {
            console.error('Failed to delete post:', error);
        } finally {
            setIsDeleting(false);
        }
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('ja-JP', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
        });
    };

    const truncateContent = (content: string, maxLength: number = 50) => {
        if (!content) return '-';
        return content.length > maxLength ? content.substring(0, maxLength) + '...' : content;
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">投稿管理</h1>
                    <p className="text-muted-foreground">ユーザー投稿一覧の管理</p>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <CardTitle>投稿一覧</CardTitle>
                        <form onSubmit={handleSearch} className="flex gap-2">
                            <Input
                                placeholder="投稿内容で検索"
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
                                        <TableHead>投稿者</TableHead>
                                        <TableHead className="w-[300px]">内容</TableHead>
                                        <TableHead>エンゲージメント</TableHead>
                                        <TableHead>投稿日時</TableHead>
                                        <TableHead className="text-right">アクション</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {posts?.data.map((post) => (
                                        <TableRow key={post.id}>
                                            <TableCell className="font-medium">
                                                <div className="flex items-center gap-3">
                                                    <Avatar className="h-8 w-8">
                                                        <AvatarImage src={post.user?.profile_image_url} />
                                                        <AvatarFallback className="bg-amber-100 text-amber-700">
                                                            {post.user?.name?.charAt(0) || '?'}
                                                        </AvatarFallback>
                                                    </Avatar>
                                                    <div>
                                                        <p className="font-medium">{post.user?.name}</p>
                                                        <p className="text-xs text-muted-foreground">@{post.user?.username}</p>
                                                    </div>
                                                </div>
                                            </TableCell>
                                            <TableCell>{truncateContent(post.content)}</TableCell>
                                            <TableCell>
                                                <div className="flex gap-2">
                                                    <Badge variant="outline" className="text-xs">
                                                        ❤️ {post.likes_count || 0}
                                                    </Badge>
                                                    <Badge variant="outline" className="text-xs">
                                                        💬 {post.comments_count || 0}
                                                    </Badge>
                                                    <Badge variant="outline" className="text-xs">
                                                        🔖 {post.bookmarks_count || 0}
                                                    </Badge>
                                                </div>
                                            </TableCell>
                                            <TableCell>{formatDate(post.created_at)}</TableCell>
                                            <TableCell className="text-right">
                                                <div className="flex gap-1 justify-end">
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        onClick={() => {
                                                            setSelectedPost(post);
                                                            setIsDialogOpen(true);
                                                        }}
                                                    >
                                                        詳細
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        size="sm"
                                                        className="text-red-500 hover:text-red-600 hover:bg-red-50"
                                                        onClick={() => {
                                                            setSelectedPost(post);
                                                            setIsDeleteDialogOpen(true);
                                                        }}
                                                    >
                                                        削除
                                                    </Button>
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>

                            {/* Pagination */}
                            {posts && posts.last_page > 1 && (
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
                                        {page} / {posts.last_page} ページ
                                    </span>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(page + 1)}
                                        disabled={page === posts.last_page}
                                    >
                                        次へ
                                    </Button>
                                </div>
                            )}
                        </>
                    )}
                </CardContent>
            </Card>

            {/* Post Detail Dialog */}
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>投稿詳細</DialogTitle>
                        <DialogDescription>投稿内容の確認</DialogDescription>
                    </DialogHeader>
                    {selectedPost && (
                        <div className="space-y-4">
                            <div className="flex items-center gap-4">
                                <Avatar className="h-12 w-12">
                                    <AvatarImage src={selectedPost.user?.profile_image_url} />
                                    <AvatarFallback className="bg-amber-100 text-amber-700">
                                        {selectedPost.user?.name?.charAt(0) || '?'}
                                    </AvatarFallback>
                                </Avatar>
                                <div>
                                    <h3 className="font-semibold">{selectedPost.user?.name}</h3>
                                    <p className="text-muted-foreground text-sm">@{selectedPost.user?.username}</p>
                                </div>
                                <div className="ml-auto text-sm text-muted-foreground">
                                    {formatDate(selectedPost.created_at)}
                                </div>
                            </div>
                            <div className="p-4 bg-gray-50 rounded-lg">
                                <p className="whitespace-pre-wrap">{selectedPost.content || '(内容なし)'}</p>
                            </div>
                            {selectedPost.images && selectedPost.images.length > 0 && (
                                <div className="grid grid-cols-2 gap-2">
                                    {selectedPost.images.map((image) => (
                                        <img
                                            key={image.id}
                                            src={image.image_url}
                                            alt=""
                                            className="rounded-lg w-full h-48 object-cover"
                                        />
                                    ))}
                                </div>
                            )}
                            <div className="flex gap-4 text-sm text-muted-foreground">
                                <span>❤️ {selectedPost.likes_count || 0} いいね</span>
                                <span>💬 {selectedPost.comments_count || 0} コメント</span>
                                <span>🔖 {selectedPost.bookmarks_count || 0} ブックマーク</span>
                            </div>
                        </div>
                    )}
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                            閉じる
                        </Button>
                        <Button
                            variant="destructive"
                            onClick={() => {
                                setIsDialogOpen(false);
                                setIsDeleteDialogOpen(true);
                            }}
                        >
                            削除
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>投稿を削除しますか？</DialogTitle>
                        <DialogDescription>
                            この操作は取り消せません。投稿とそれに関連するすべてのデータが削除されます。
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
                            キャンセル
                        </Button>
                        <Button variant="destructive" onClick={handleDelete} disabled={isDeleting}>
                            {isDeleting ? '削除中...' : '削除する'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
