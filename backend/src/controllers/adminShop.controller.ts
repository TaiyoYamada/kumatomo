import { Request, Response } from 'express';
import { prisma } from '../db';

export async function index(_req: Request, res: Response) {
  const shops = await prisma.shop.findMany({ orderBy: { created_at: 'desc' } });
  return res.json(shops);
}

export async function store(req: Request, res: Response) {
  try {
    const shop = await prisma.shop.create({ data: req.body });
    return res.status(201).json(shop);
  } catch (e: any) {
    return res.status(400).json({ error: { code: 'SHOP_CREATE_FAILED', message: e?.message || 'Failed to create shop' } });
  }
}

export async function show(req: Request, res: Response) {
  const shop = await prisma.shop.findUnique({ where: { id: BigInt(String(req.params.id)) } });
  if (!shop) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Shop not found' } });
  return res.json(shop);
}

export async function update(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id));
    const shop = await prisma.shop.update({ where: { id }, data: req.body });
    return res.json(shop);
  } catch (e: any) {
    return res.status(400).json({ error: { code: 'SHOP_UPDATE_FAILED', message: e?.message || 'Failed to update shop' } });
  }
}

export async function destroy(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id));
    await prisma.shop.delete({ where: { id } });
    return res.json({ message: 'Shop deleted' });
  } catch (e: any) {
    return res.status(400).json({ error: { code: 'SHOP_DELETE_FAILED', message: e?.message || 'Failed to delete shop' } });
  }
}
