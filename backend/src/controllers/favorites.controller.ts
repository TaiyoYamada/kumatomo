import { Request, Response } from 'express';
import { prisma } from '../db';

export async function index(req: Request, res: Response) {
  const userId = req.userId!;
  const favorites = await prisma.favorite.findMany({ where: { user_id: userId }, include: { shop: true } });
  return res.json(favorites);
}

export async function toggle(req: Request, res: Response) {
  const userId = req.userId!;
  const shopId = BigInt(String(req.params.shopId));
  const existing = await prisma.favorite.findFirst({ where: { user_id: userId, shop_id: shopId } });
  if (existing) {
    await prisma.favorite.delete({ where: { id: existing.id } });
    return res.json({ message: 'Unfavorited' });
  }
  const created = await prisma.favorite.create({ data: { user_id: userId, shop_id: shopId } });
  return res.status(201).json(created);
}

export async function destroy(req: Request, res: Response) {
  const id = BigInt(String(req.params.favoriteId));
  await prisma.favorite.delete({ where: { id } });
  return res.json({ message: 'Favorite deleted' });
}

export async function check(req: Request, res: Response) {
  const userId = req.userId!;
  const shopId = BigInt(String(req.params.shopId));
  const exists = await prisma.favorite.findFirst({ where: { user_id: userId, shop_id: shopId } });
  return res.json({ favorited: !!exists });
}

export async function stats(req: Request, res: Response) {
  const userId = req.userId!;
  const [count, shops] = await Promise.all([
    prisma.favorite.count({ where: { user_id: userId } }),
    prisma.favorite.findMany({ where: { user_id: userId }, include: { shop: true } }),
  ]);
  return res.json({ count, shops });
}
