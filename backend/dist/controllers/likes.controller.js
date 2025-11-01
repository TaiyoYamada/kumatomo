"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toggle = toggle;
exports.destroy = destroy;
exports.likedPosts = likedPosts;
const db_1 = require("../db");
async function toggle(req, res) {
    const userId = req.userId;
    const postId = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.like.findFirst({ where: { user_id: userId, post_id: postId } });
    if (existing) {
        await db_1.prisma.like.delete({ where: { id: existing.id } });
        return res.json({ message: 'Unliked' });
    }
    const created = await db_1.prisma.like.create({ data: { user_id: userId, post_id: postId } });
    return res.status(201).json(created);
}
async function destroy(req, res) {
    const userId = req.userId;
    const postId = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.like.findFirst({ where: { user_id: userId, post_id: postId } });
    if (!existing)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Like not found' } });
    await db_1.prisma.like.delete({ where: { id: existing.id } });
    return res.json({ message: 'Like deleted' });
}
async function likedPosts(req, res) {
    const userId = req.userId;
    const likes = await db_1.prisma.like.findMany({ where: { user_id: userId }, include: { post: { include: { user: true, images: true, shop: true } } } });
    return res.json(likes.map((l) => l.post));
}
//# sourceMappingURL=likes.controller.js.map