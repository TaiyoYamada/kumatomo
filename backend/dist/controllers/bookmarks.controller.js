"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toggle = toggle;
exports.destroy = destroy;
exports.bookmarkedPosts = bookmarkedPosts;
const db_1 = require("../db");
async function toggle(req, res) {
    const userId = req.userId;
    const postId = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.bookmark.findFirst({ where: { user_id: userId, post_id: postId } });
    if (existing) {
        await db_1.prisma.bookmark.delete({ where: { id: existing.id } });
        return res.json({ message: 'Unbookmarked' });
    }
    const created = await db_1.prisma.bookmark.create({ data: { user_id: userId, post_id: postId } });
    return res.status(201).json(created);
}
async function destroy(req, res) {
    const userId = req.userId;
    const postId = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.bookmark.findFirst({ where: { user_id: userId, post_id: postId } });
    if (!existing)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Bookmark not found' } });
    await db_1.prisma.bookmark.delete({ where: { id: existing.id } });
    return res.json({ message: 'Bookmark deleted' });
}
async function bookmarkedPosts(req, res) {
    const userId = req.userId;
    const bookmarks = await db_1.prisma.bookmark.findMany({ where: { user_id: userId }, include: { post: { include: { user: true, images: true, shop: true } } } });
    return res.json(bookmarks.map((b) => b.post));
}
//# sourceMappingURL=bookmarks.controller.js.map