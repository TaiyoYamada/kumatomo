"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.search = search;
const db_1 = require("../db");
async function search(req, res) {
    const { q } = req.query;
    if (!q)
        return res.json({ posts: [], shops: [] });
    const [posts, shops] = await Promise.all([
        db_1.prisma.post.findMany({
            where: { OR: [{ content: { contains: q } }, { tags: { array_contains: [q] } }] },
            include: { user: true, images: true, shop: true },
            orderBy: { created_at: 'desc' },
        }),
        db_1.prisma.shop.findMany({
            where: { OR: [{ name: { contains: q } }, { description: { contains: q } }, { address: { contains: q } }] },
            orderBy: { created_at: 'desc' },
        }),
    ]);
    return res.json({ posts, shops });
}
//# sourceMappingURL=search.controller.js.map