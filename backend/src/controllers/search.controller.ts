import { Request, Response } from 'express';
import { prisma } from '../db';

export async function search(req: Request, res: Response) {
  const { q } = req.query as Record<string, string>;
  if (!q) return res.json({ posts: [], shops: [] });
  const [posts, shops] = await Promise.all([
    prisma.post.findMany({
      where: { OR: [{ content: { contains: q } }, { tags: { array_contains: [q] } as any }] },
      include: { user: true, images: true, shop: true },
      orderBy: { created_at: 'desc' },
    }),
    prisma.shop.findMany({
      where: { OR: [{ name: { contains: q } }, { description: { contains: q } }, { address: { contains: q } }] },
      orderBy: { created_at: 'desc' },
    }),
  ]);
  return res.json({ posts, shops });
}

