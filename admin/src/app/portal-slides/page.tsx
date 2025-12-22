'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/lib/auth';
import { api, PortalSlide } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';

export default function PortalSlidesPage() {
    const { token } = useAuth();
    const [slides, setSlides] = useState<PortalSlide[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
    const [selectedSlide, setSelectedSlide] = useState<PortalSlide | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [formData, setFormData] = useState({
        image_url: '',
        title: '',
        link_url: '',
        is_active: true,
    });

    const fetchSlides = useCallback(async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            const data = await api.getPortalSlides(token);
            setSlides(data);
        } catch (error) {
            console.error('Failed to fetch slides:', error);
        } finally {
            setIsLoading(false);
        }
    }, [token]);

    useEffect(() => {
        fetchSlides();
    }, [fetchSlides]);

    const handleOpenDialog = (slide?: PortalSlide) => {
        if (slide) {
            setSelectedSlide(slide);
            setFormData({
                image_url: slide.image_url,
                title: slide.title || '',
                link_url: slide.link_url || '',
                is_active: slide.is_active,
            });
        } else {
            setSelectedSlide(null);
            setFormData({
                image_url: '',
                title: '',
                link_url: '',
                is_active: true,
            });
        }
        setIsDialogOpen(true);
    };

    const handleSave = async () => {
        if (!token) return;
        setIsSaving(true);
        try {
            if (selectedSlide) {
                await api.updatePortalSlide(token, selectedSlide.id, formData);
            } else {
                await api.createPortalSlide(token, formData as Omit<PortalSlide, 'id'>);
            }
            fetchSlides();
            setIsDialogOpen(false);
        } catch (error) {
            console.error('Failed to save slide:', error);
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!token || !selectedSlide) return;
        setIsSaving(true);
        try {
            await api.deletePortalSlide(token, selectedSlide.id);
            fetchSlides();
            setIsDeleteDialogOpen(false);
            setSelectedSlide(null);
        } catch (error) {
            console.error('Failed to delete slide:', error);
        } finally {
            setIsSaving(false);
        }
    };

    const handleToggleActive = async (slide: PortalSlide) => {
        if (!token) return;
        try {
            await api.updatePortalSlide(token, slide.id, { is_active: !slide.is_active });
            fetchSlides();
        } catch (error) {
            console.error('Failed to toggle slide:', error);
        }
    };

    const handleMoveUp = async (index: number) => {
        if (index === 0 || !token) return;
        const newOrder = slides.map((s) => s.id);
        [newOrder[index - 1], newOrder[index]] = [newOrder[index], newOrder[index - 1]];
        try {
            await api.reorderPortalSlides(token, newOrder);
            fetchSlides();
        } catch (error) {
            console.error('Failed to reorder:', error);
        }
    };

    const handleMoveDown = async (index: number) => {
        if (index === slides.length - 1 || !token) return;
        const newOrder = slides.map((s) => s.id);
        [newOrder[index], newOrder[index + 1]] = [newOrder[index + 1], newOrder[index]];
        try {
            await api.reorderPortalSlides(token, newOrder);
            fetchSlides();
        } catch (error) {
            console.error('Failed to reorder:', error);
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">ポータルスライド管理</h1>
                    <p className="text-muted-foreground">iOSアプリのトップページに表示されるスライドショーの管理</p>
                </div>
                <Button
                    onClick={() => handleOpenDialog()}
                    className="bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white"
                >
                    <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    新規追加
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>スライド一覧</CardTitle>
                    <CardDescription>表示順序は上から順になります。矢印ボタンで順序を変更できます。</CardDescription>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <div className="grid gap-4">
                            {[...Array(3)].map((_, i) => (
                                <div key={i} className="h-32 bg-gray-100 rounded-lg animate-pulse" />
                            ))}
                        </div>
                    ) : slides.length === 0 ? (
                        <div className="text-center py-12 text-muted-foreground">
                            <svg className="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <p>スライドがありません</p>
                            <p className="text-sm mt-1">「新規追加」ボタンからスライドを追加してください</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {slides.map((slide, index) => (
                                <div
                                    key={slide.id}
                                    className={`flex items-center gap-4 p-4 rounded-lg border ${slide.is_active ? 'border-amber-200 bg-amber-50/50' : 'border-gray-200 bg-gray-50 opacity-60'
                                        }`}
                                >
                                    <div className="flex flex-col gap-1">
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-8 w-8"
                                            onClick={() => handleMoveUp(index)}
                                            disabled={index === 0}
                                        >
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
                                            </svg>
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-8 w-8"
                                            onClick={() => handleMoveDown(index)}
                                            disabled={index === slides.length - 1}
                                        >
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                                            </svg>
                                        </Button>
                                    </div>

                                    <div className="w-40 h-24 rounded-lg overflow-hidden bg-gray-200 flex-shrink-0">
                                        {slide.image_url ? (
                                            <img
                                                src={slide.imageURL || slide.image_url}
                                                alt={slide.title || ''}
                                                className="w-full h-full object-cover"
                                                onError={(e) => {
                                                    (e.target as HTMLImageElement).src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="160" height="96" viewBox="0 0 160 96"><rect fill="%23f3f4f6" width="160" height="96"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="%239ca3af" font-size="12">No Image</text></svg>';
                                                }}
                                            />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                                                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                                </svg>
                                            </div>
                                        )}
                                    </div>

                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2 mb-1">
                                            <h3 className="font-medium truncate">{slide.title || '(タイトルなし)'}</h3>
                                            <Badge variant={slide.is_active ? 'default' : 'secondary'} className={slide.is_active ? 'bg-green-500' : ''}>
                                                {slide.is_active ? '有効' : '無効'}
                                            </Badge>
                                        </div>
                                        <p className="text-sm text-muted-foreground truncate">{slide.image_url}</p>
                                        {slide.link_url && (
                                            <p className="text-sm text-blue-500 truncate mt-1">リンク: {slide.link_url}</p>
                                        )}
                                    </div>

                                    <div className="flex items-center gap-2">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => handleToggleActive(slide)}
                                        >
                                            {slide.is_active ? '無効にする' : '有効にする'}
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => handleOpenDialog(slide)}
                                        >
                                            編集
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            className="text-red-500 hover:text-red-600 hover:bg-red-50"
                                            onClick={() => {
                                                setSelectedSlide(slide);
                                                setIsDeleteDialogOpen(true);
                                            }}
                                        >
                                            削除
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Add/Edit Dialog */}
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>{selectedSlide ? 'スライドを編集' : '新しいスライドを追加'}</DialogTitle>
                        <DialogDescription>スライドショーに表示する画像の情報を入力してください</DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="image_url">画像URL *</Label>
                            <Input
                                id="image_url"
                                placeholder="https://example.com/image.jpg"
                                value={formData.image_url}
                                onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                            />
                            <p className="text-xs text-muted-foreground">
                                画像は事前にアップロードしてURLを入力してください
                            </p>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="title">タイトル（任意）</Label>
                            <Input
                                id="title"
                                placeholder="スライドのタイトル"
                                value={formData.title}
                                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="link_url">リンクURL（任意）</Label>
                            <Input
                                id="link_url"
                                placeholder="https://example.com/page"
                                value={formData.link_url}
                                onChange={(e) => setFormData({ ...formData, link_url: e.target.value })}
                            />
                        </div>
                        <div className="flex items-center gap-2">
                            <input
                                type="checkbox"
                                id="is_active"
                                checked={formData.is_active}
                                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                                className="h-4 w-4 rounded border-gray-300"
                            />
                            <Label htmlFor="is_active">有効にする</Label>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                            キャンセル
                        </Button>
                        <Button
                            onClick={handleSave}
                            disabled={isSaving || !formData.image_url}
                            className="bg-amber-500 hover:bg-amber-600"
                        >
                            {isSaving ? '保存中...' : '保存'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>スライドを削除しますか？</DialogTitle>
                        <DialogDescription>
                            この操作は取り消せません。スライドが削除されます。
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
                            キャンセル
                        </Button>
                        <Button variant="destructive" onClick={handleDelete} disabled={isSaving}>
                            {isSaving ? '削除中...' : '削除する'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
