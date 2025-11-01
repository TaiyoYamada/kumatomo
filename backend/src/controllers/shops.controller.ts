import { Request, Response } from 'express';
import { prisma } from '../db';

export async function index(req: Request, res: Response) {
  try {
    const { genre, q, page = '1', per_page = '20' } = req.query as Record<string, string>;
    const pageNum = Math.max(1, parseInt(page || '1', 10));
    const take = Math.min(50, Math.max(1, parseInt(per_page || '20', 10)));
    const skip = (pageNum - 1) * take;

    const where: any = {};
    if (genre) where.genre = String(genre);
    if (q) {
      where.OR = [
        { name: { contains: String(q) } },
        { description: { contains: String(q) } },
        { address: { contains: String(q) } },
      ];
    }

    const [items, total] = await Promise.all([
      prisma.shop.findMany({ where, skip, take, orderBy: { created_at: 'desc' } }),
      prisma.shop.count({ where }),
    ]);

    return res.json({ data: items, meta: { total, page: pageNum, per_page: take } });
  } catch (e: any) {
    return res.status(500).json({ error: { code: 'SHOP_INDEX_FAILED', message: e?.message || 'Failed to list shops' } });
  }
}

export async function search(req: Request, res: Response) {
  const { q } = req.query as Record<string, string>;
  if (!q) return res.json({ data: [] });
  req.query.q = String(q);
  return index(req, res);
}

export async function show(req: Request, res: Response) {
  const id = BigInt(String(req.params.id));
  const shop = await prisma.shop.findUnique({ where: { id }, include: { posts: true } });
  if (!shop) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Shop not found' } });
  return res.json(shop);
}

export async function posts(req: Request, res: Response) {
  try {
    const shopId = BigInt(String(req.params.id));
    const posts = await prisma.post.findMany({
      where: { shop_id: shopId },
      orderBy: { created_at: 'desc' },
      include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
    });
    return res.json(posts);
  } catch (e: any) {
    return res.status(500).json({ error: { code: 'SHOP_POSTS_FAILED', message: e?.message || 'Failed to get posts' } });
  }
}

// Admin operations (simple baseline)
export async function adminCreate(data: any) {
  return prisma.shop.create({ data });
}
