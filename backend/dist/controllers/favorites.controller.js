"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.toggle = toggle;
exports.destroy = destroy;
exports.check = check;
exports.stats = stats;
const db_1 = require("../db");
async function index(req, res) {
    const userId = req.userId;
    const favorites = await db_1.prisma.favorite.findMany({ where: { user_id: userId }, include: { shop: true } });
    return res.json(favorites);
}
async function toggle(req, res) {
    const userId = req.userId;
    const shopId = BigInt(String(req.params.shopId));
    const existing = await db_1.prisma.favorite.findFirst({ where: { user_id: userId, shop_id: shopId } });
    if (existing) {
        await db_1.prisma.favorite.delete({ where: { id: existing.id } });
        return res.json({ message: 'Unfavorited' });
    }
    const created = await db_1.prisma.favorite.create({ data: { user_id: userId, shop_id: shopId } });
    return res.status(201).json(created);
}
async function destroy(req, res) {
    const id = BigInt(String(req.params.favoriteId));
    await db_1.prisma.favorite.delete({ where: { id } });
    return res.json({ message: 'Favorite deleted' });
}
async function check(req, res) {
    const userId = req.userId;
    const shopId = BigInt(String(req.params.shopId));
    const exists = await db_1.prisma.favorite.findFirst({ where: { user_id: userId, shop_id: shopId } });
    return res.json({ favorited: !!exists });
}
async function stats(req, res) {
    const userId = req.userId;
    const [count, shops] = await Promise.all([
        db_1.prisma.favorite.count({ where: { user_id: userId } }),
        db_1.prisma.favorite.findMany({ where: { user_id: userId }, include: { shop: true } }),
    ]);
    return res.json({ count, shops });
}
//# sourceMappingURL=favorites.controller.js.map