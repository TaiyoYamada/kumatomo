import { Request, Response } from 'express';
import { prisma } from '../db';

export async function index(req: Request, res: Response) {
  const postId = BigInt(String(req.params.postId));
  const comments = await prisma.comment.findMany({ where: { post_id: postId }, include: { user: true }, orderBy: { created_at: 'asc' } });
  return res.json(comments);
}

export async function store(req: Request, res: Response) {
  const postId = BigInt(String(req.params.postId));
  const { content, image_url } = req.body || {};
  const created = await prisma.comment.create({ data: { post_id: postId, user_id: req.userId!, content, image_url } });
  return res.status(201).json(created);
}

export async function destroy(req: Request, res: Response) {
  const id = BigInt(String(req.params.commentId));
  const comment = await prisma.comment.findUnique({ where: { id } });
  if (!comment) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Comment not found' } });
  if (comment.user_id !== req.userId) return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete others\' comment' } });
  await prisma.comment.delete({ where: { id } });
  return res.json({ message: 'Comment deleted' });
}
