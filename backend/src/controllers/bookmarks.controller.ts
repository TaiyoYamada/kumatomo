import { Request, Response } from 'express';
import { prisma } from '../db';

export async function toggle(req: Request, res: Response) {
  const userId = req.userId!;
  const postId = BigInt(String(req.params.postId));
  const existing = await prisma.bookmark.findFirst({ where: { user_id: userId, post_id: postId } });
  if (existing) {
    await prisma.bookmark.delete({ where: { id: existing.id } });
    return res.json({ message: 'Unbookmarked' });
  }
  const created = await prisma.bookmark.create({ data: { user_id: userId, post_id: postId } });
  return res.status(201).json(created);
}

export async function destroy(req: Request, res: Response) {
  const userId = req.userId!;
  const postId = BigInt(String(req.params.postId));
  const existing = await prisma.bookmark.findFirst({ where: { user_id: userId, post_id: postId } });
  if (!existing) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Bookmark not found' } });
  await prisma.bookmark.delete({ where: { id: existing.id } });
  return res.json({ message: 'Bookmark deleted' });
}

export async function bookmarkedPosts(req: Request, res: Response) {
  const userId = req.userId!;
  const bookmarks = await prisma.bookmark.findMany({ where: { user_id: userId }, include: { post: { include: { user: true, images: true, shop: true } } } });
  return res.json(bookmarks.map((b: any) => b.post));
}
