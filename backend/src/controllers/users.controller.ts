import { Request, Response } from 'express';
import { prisma } from '../db';

export async function me(req: Request, res: Response) {
  if (!req.userId) return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Not authenticated' } });
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
  return res.json(user);
}

export async function show(req: Request, res: Response) {
  const id = BigInt(String(req.params.id));
  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
  return res.json(user);
}

export async function update(req: Request, res: Response) {
  const id = req.params.id ? BigInt(String(req.params.id)) : req.userId!;
  if (id !== req.userId) {
    return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot update other user' } });
  }
  const data = req.body || {};
  const updated = await prisma.user.update({ where: { id }, data });
  return res.json(updated);
}

export async function destroy(req: Request, res: Response) {
  const id = BigInt(String(req.params.id));
  if (id !== req.userId) {
    return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete other user' } });
  }
  await prisma.user.delete({ where: { id } });
  return res.json({ message: 'User deleted' });
}

export async function checkUsernameAvailability(req: Request, res: Response) {
  const { username } = req.body || {};
  if (!username) return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'username required' } });
  const exists = await prisma.user.findFirst({ where: { username } });
  return res.json({ available: !exists });
}

export async function updateUsername(req: Request, res: Response) {
  const { username } = req.body || {};
  if (!username) return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'username required' } });
  const updated = await prisma.user.update({ where: { id: req.userId! }, data: { username } });
  return res.json(updated);
}

export async function store(req: Request, res: Response) {
  try {
    const data = req.body || {};
    const created = await prisma.user.create({ data });
    return res.status(201).json(created);
  } catch (e: any) {
    return res.status(400).json({ error: { code: 'USER_CREATE_FAILED', message: e?.message || 'Failed to create user' } });
  }
}

export async function uploadProfileImage(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Profile image upload not implemented' } });
}

export async function uploadCoverImage(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Cover image upload not implemented' } });
}
