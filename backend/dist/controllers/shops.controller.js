"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.search = search;
exports.show = show;
exports.posts = posts;
exports.adminCreate = adminCreate;
const db_1 = require("../db");
async function index(req, res) {
    try {
        const { genre, q, page = '1', per_page = '20' } = req.query;
        const pageNum = Math.max(1, parseInt(page || '1', 10));
        const take = Math.min(50, Math.max(1, parseInt(per_page || '20', 10)));
        const skip = (pageNum - 1) * take;
        const where = {};
        if (genre)
            where.genre = String(genre);
        if (q) {
            where.OR = [
                { name: { contains: String(q) } },
                { description: { contains: String(q) } },
                { address: { contains: String(q) } },
            ];
        }
        const [items, total] = await Promise.all([
            db_1.prisma.shop.findMany({ where, skip, take, orderBy: { created_at: 'desc' } }),
            db_1.prisma.shop.count({ where }),
        ]);
        return res.json({ data: items, meta: { total, page: pageNum, per_page: take } });
    }
    catch (e) {
        return res.status(500).json({ error: { code: 'SHOP_INDEX_FAILED', message: e?.message || 'Failed to list shops' } });
    }
}
async function search(req, res) {
    const { q } = req.query;
    if (!q)
        return res.json({ data: [] });
    req.query.q = String(q);
    return index(req, res);
}
async function show(req, res) {
    const id = BigInt(String(req.params.id));
    const shop = await db_1.prisma.shop.findUnique({ where: { id }, include: { posts: true } });
    if (!shop)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Shop not found' } });
    return res.json(shop);
}
async function posts(req, res) {
    try {
        const shopId = BigInt(String(req.params.id));
        const posts = await db_1.prisma.post.findMany({
            where: { shop_id: shopId },
            orderBy: { created_at: 'desc' },
            include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
        });
        return res.json(posts);
    }
    catch (e) {
        return res.status(500).json({ error: { code: 'SHOP_POSTS_FAILED', message: e?.message || 'Failed to get posts' } });
    }
}
// Admin operations (simple baseline)
async function adminCreate(data) {
    return db_1.prisma.shop.create({ data });
}
//# sourceMappingURL=shops.controller.js.map