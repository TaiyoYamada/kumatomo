"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.store = store;
exports.show = show;
exports.update = update;
exports.destroy = destroy;
const db_1 = require("../db");
async function index(_req, res) {
    const shops = await db_1.prisma.shop.findMany({ orderBy: { created_at: 'desc' } });
    return res.json(shops);
}
async function store(req, res) {
    try {
        const shop = await db_1.prisma.shop.create({ data: req.body });
        return res.status(201).json(shop);
    }
    catch (e) {
        return res.status(400).json({ error: { code: 'SHOP_CREATE_FAILED', message: e?.message || 'Failed to create shop' } });
    }
}
async function show(req, res) {
    const shop = await db_1.prisma.shop.findUnique({ where: { id: BigInt(String(req.params.id)) } });
    if (!shop)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Shop not found' } });
    return res.json(shop);
}
async function update(req, res) {
    try {
        const id = BigInt(String(req.params.id));
        const shop = await db_1.prisma.shop.update({ where: { id }, data: req.body });
        return res.json(shop);
    }
    catch (e) {
        return res.status(400).json({ error: { code: 'SHOP_UPDATE_FAILED', message: e?.message || 'Failed to update shop' } });
    }
}
async function destroy(req, res) {
    try {
        const id = BigInt(String(req.params.id));
        await db_1.prisma.shop.delete({ where: { id } });
        return res.json({ message: 'Shop deleted' });
    }
    catch (e) {
        return res.status(400).json({ error: { code: 'SHOP_DELETE_FAILED', message: e?.message || 'Failed to delete shop' } });
    }
}
//# sourceMappingURL=adminShop.controller.js.map