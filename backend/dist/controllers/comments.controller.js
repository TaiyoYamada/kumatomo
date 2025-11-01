"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.store = store;
exports.destroy = destroy;
const db_1 = require("../db");
async function index(req, res) {
    const postId = BigInt(String(req.params.postId));
    const comments = await db_1.prisma.comment.findMany({ where: { post_id: postId }, include: { user: true }, orderBy: { created_at: 'asc' } });
    return res.json(comments);
}
async function store(req, res) {
    const postId = BigInt(String(req.params.postId));
    const { content, image_url } = req.body || {};
    const created = await db_1.prisma.comment.create({ data: { post_id: postId, user_id: req.userId, content, image_url } });
    return res.status(201).json(created);
}
async function destroy(req, res) {
    const id = BigInt(String(req.params.commentId));
    const comment = await db_1.prisma.comment.findUnique({ where: { id } });
    if (!comment)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Comment not found' } });
    if (comment.user_id !== req.userId)
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete others\' comment' } });
    await db_1.prisma.comment.delete({ where: { id } });
    return res.json({ message: 'Comment deleted' });
}
//# sourceMappingURL=comments.controller.js.map