'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import { api, Announcement, PaginatedResponse } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Search, MoreHorizontal, Plus, Loader2, Calendar } from 'lucide-react';
import { format } from 'date-fns';
import { ja } from 'date-fns/locale';

export default function AnnouncementsPage() {
    const router = useRouter();
    const { token } = useAuth();
    const [announcements, setAnnouncements] = useState<Announcement[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [pagination, setPagination] = useState({
        current_page: 1,
        last_page: 1,
        total: 0,
    });

    // Modal State
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [editingAnnouncement, setEditingAnnouncement] = useState<Announcement | null>(null);
    const [formData, setFormData] = useState({
        title: '',
        content: '',
        published_at: '',
        is_active: true,
        priority: 0,
    });

    // Delete State
    const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
    const [deletingId, setDeletingId] = useState<number | null>(null);

    const fetchAnnouncements = async (page = 1) => {
        if (!token) return;
        setLoading(true);
        try {
            const response = await api.getAnnouncements(token, {
                page,
                search,
                per_page: 10,
            });
            setAnnouncements(response.data);
            setPagination({
                current_page: response.current_page,
                last_page: response.last_page,
                total: response.total,
            });
        } catch (error) {
            console.error('Failed to fetch announcements:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAnnouncements();
    }, [token]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        fetchAnnouncements(1);
    };

    const handleOpenDialog = (announcement?: Announcement) => {
        if (announcement) {
            setEditingAnnouncement(announcement);
            setFormData({
                title: announcement.title,
                content: announcement.content,
                // Convert strict ISO string to datetime-local friendly format if needed, 
                // but simple string is fine for now as long as it's handled correctly.
                published_at: announcement.published_at ? announcement.published_at.slice(0, 16) : '',
                is_active: announcement.is_active,
                priority: announcement.priority,
            });
        } else {
            setEditingAnnouncement(null);
            setFormData({
                title: '',
                content: '',
                published_at: '',
                is_active: true,
                priority: 0,
            });
        }
        setIsDialogOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!token) return;

        try {
            const data: any = { ...formData };
            if (!data.published_at) data.published_at = null;

            if (editingAnnouncement) {
                await api.updateAnnouncement(token, editingAnnouncement.id, data);
            } else {
                await api.createAnnouncement(token, data);
            }
            setIsDialogOpen(false);
            fetchAnnouncements(pagination.current_page);
        } catch (error) {
            console.error('Failed to save announcement:', error);
            alert('保存に失敗しました');
        }
    };

    const handleDelete = async () => {
        if (!token || !deletingId) return;
        try {
            await api.deleteAnnouncement(token, deletingId);
            setIsDeleteDialogOpen(false);
            setDeletingId(null);
            fetchAnnouncements(pagination.current_page);
        } catch (error) {
            console.error('Failed to delete announcement:', error);
            alert('削除に失敗しました');
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-gray-900">お知らせ管理</h1>
                    <p className="text-gray-500 mt-2">
                        アプリ内の「運営からのお知らせ」に表示されるコンテンツを管理します。
                    </p>
                </div>
                <Button
                    onClick={() => handleOpenDialog()}
                    className="bg-amber-500 hover:bg-amber-600 text-white"
                >
                    <Plus className="mr-2 h-4 w-4" />
                    新規作成
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>お知らせ一覧</CardTitle>
                    <div className="mt-4">
                        <form onSubmit={handleSearch} className="flex gap-2">
                            <div className="relative flex-1 max-w-sm">
                                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                                <Input
                                    placeholder="タイトルや内容で検索..."
                                    className="pl-9"
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                />
                            </div>
                            <Button type="submit" variant="outline">検索</Button>
                        </form>
                    </div>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <div className="flex justify-center p-8">
                            <Loader2 className="h-8 w-8 animate-spin text-amber-500" />
                        </div>
                    ) : (
                        <>
                            <div className="rounded-md border">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>ステータス</TableHead>
                                            <TableHead>タイトル</TableHead>
                                            <TableHead>公開日時</TableHead>
                                            <TableHead>優先度</TableHead>
                                            <TableHead className="text-right">アクション</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {announcements.length === 0 ? (
                                            <TableRow>
                                                <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                                                    お知らせが見つかりませんでした
                                                </TableCell>
                                            </TableRow>
                                        ) : (
                                            announcements.map((item) => (
                                                <TableRow key={item.id}>
                                                    <TableCell>
                                                        {item.is_active ? (
                                                            <Badge className="bg-green-500 hover:bg-green-600">公開中</Badge>
                                                        ) : (
                                                            <Badge variant="secondary">非公開</Badge>
                                                        )}
                                                    </TableCell>
                                                    <TableCell className="font-medium">{item.title}</TableCell>
                                                    <TableCell>
                                                        {item.published_at ? (
                                                            <div className="flex items-center gap-1 text-sm text-gray-600">
                                                                <Calendar className="h-3 w-3" />
                                                                {format(new Date(item.published_at), 'yyyy/MM/dd HH:mm', { locale: ja })}
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-400 text-sm">-</span>
                                                        )}
                                                    </TableCell>
                                                    <TableCell>
                                                        {item.priority > 0 && (
                                                            <Badge variant="outline" className="border-amber-500 text-amber-600">
                                                                Priority: {item.priority}
                                                            </Badge>
                                                        )}
                                                    </TableCell>
                                                    <TableCell className="text-right">
                                                        <DropdownMenu>
                                                            <DropdownMenuTrigger asChild>
                                                                <Button variant="ghost" className="h-8 w-8 p-0">
                                                                    <MoreHorizontal className="h-4 w-4" />
                                                                </Button>
                                                            </DropdownMenuTrigger>
                                                            <DropdownMenuContent align="end">
                                                                <DropdownMenuItem onClick={() => handleOpenDialog(item)}>
                                                                    編集
                                                                </DropdownMenuItem>
                                                                <DropdownMenuItem
                                                                    className="text-red-600"
                                                                    onClick={() => {
                                                                        setDeletingId(item.id);
                                                                        setIsDeleteDialogOpen(true);
                                                                    }}
                                                                >
                                                                    削除
                                                                </DropdownMenuItem>
                                                            </DropdownMenuContent>
                                                        </DropdownMenu>
                                                    </TableCell>
                                                </TableRow>
                                            ))
                                        )}
                                    </TableBody>
                                </Table>
                            </div>

                            {/* Pagination */}
                            {pagination.last_page > 1 && (
                                <div className="flex justify-center mt-4 gap-2">
                                    <Button
                                        variant="outline"
                                        disabled={pagination.current_page === 1}
                                        onClick={() => fetchAnnouncements(pagination.current_page - 1)}
                                    >
                                        前へ
                                    </Button>
                                    <span className="flex items-center px-4 text-sm text-gray-600">
                                        {pagination.current_page} / {pagination.last_page}
                                    </span>
                                    <Button
                                        variant="outline"
                                        disabled={pagination.current_page === pagination.last_page}
                                        onClick={() => fetchAnnouncements(pagination.current_page + 1)}
                                    >
                                        次へ
                                    </Button>
                                </div>
                            )}
                        </>
                    )}
                </CardContent>
            </Card>

            {/* Edit/Create Dialog */}
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent className="sm:max-w-[600px]">
                    <DialogHeader>
                        <DialogTitle>{editingAnnouncement ? 'お知らせを編集' : '新規お知らせ作成'}</DialogTitle>
                        <DialogDescription>
                            アプリのポータル画面に表示されるお知らせを作成・編集します。
                        </DialogDescription>
                    </DialogHeader>
                    <form onSubmit={handleSubmit}>
                        <div className="grid gap-4 py-4">
                            <div className="grid gap-2">
                                <Label htmlFor="title">タイトル</Label>
                                <Input
                                    id="title"
                                    value={formData.title}
                                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                    placeholder="例: 年末年始のサポートについて"
                                    required
                                />
                            </div>
                            <div className="grid gap-2">
                                <Label htmlFor="content">内容</Label>
                                <Textarea
                                    id="content"
                                    value={formData.content}
                                    onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                                    placeholder="お知らせの詳細内容を入力してください..."
                                    className="min-h-[150px]"
                                    required
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="grid gap-2">
                                    <Label htmlFor="published_at">公開日時 (任意)</Label>
                                    <Input
                                        id="published_at"
                                        type="datetime-local"
                                        value={formData.published_at}
                                        onChange={(e) => setFormData({ ...formData, published_at: e.target.value })}
                                    />
                                    <p className="text-xs text-gray-500">指定しない場合は即時公開</p>
                                </div>
                                <div className="grid gap-2">
                                    <Label htmlFor="priority">優先度 (数字が大きいほど上)</Label>
                                    <Input
                                        id="priority"
                                        type="number"
                                        value={formData.priority}
                                        onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                                    />
                                </div>
                            </div>
                            <div className="flex items-center space-x-2 pt-2">
                                <Switch
                                    id="is_active"
                                    checked={formData.is_active}
                                    onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
                                />
                                <Label htmlFor="is_active">有効 (公開する)</Label>
                            </div>
                        </div>
                        <DialogFooter>
                            <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                                キャンセル
                            </Button>
                            <Button type="submit" className="bg-amber-500 hover:bg-amber-600 text-white">
                                保存
                            </Button>
                        </DialogFooter>
                    </form>
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>お知らせを削除</DialogTitle>
                        <DialogDescription>
                            本当にこのお知らせを削除してもよろしいですか？この操作は取り消せません。
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
                            キャンセル
                        </Button>
                        <Button variant="destructive" onClick={handleDelete}>
                            削除する
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
