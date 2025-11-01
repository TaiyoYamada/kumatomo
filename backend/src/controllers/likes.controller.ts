import { Request, Response } from 'express';
import { prisma } from '../db';

export async function toggle(req: Request, res: Response) {
  const userId = req.userId!;
  const postId = BigInt(String(req.params.postId));
  const existing = await prisma.like.findFirst({ where: { user_id: userId, post_id: postId } });
  if (existing) {
    await prisma.like.delete({ where: { id: existing.id } });
    return res.json({ message: 'Unliked' });
  }
  const created = await prisma.like.create({ data: { user_id: userId, post_id: postId } });
  return res.status(201).json(created);
}

export async function destroy(req: Request, res: Response) {
  const userId = req.userId!;
  const postId = BigInt(String(req.params.postId));
  const existing = await prisma.like.findFirst({ where: { user_id: userId, post_id: postId } });
  if (!existing) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Like not found' } });
  await prisma.like.delete({ where: { id: existing.id } });
  return res.json({ message: 'Like deleted' });
}

export async function likedPosts(req: Request, res: Response) {
  const userId = req.userId!;
  const likes = await prisma.like.findMany({ where: { user_id: userId }, include: { post: { include: { user: true, images: true, shop: true } } } });
  return res.json(likes.map((l: any) => l.post));
}
