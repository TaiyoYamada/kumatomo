"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.me = me;
exports.show = show;
exports.update = update;
exports.destroy = destroy;
exports.checkUsernameAvailability = checkUsernameAvailability;
exports.updateUsername = updateUsername;
exports.store = store;
exports.uploadProfileImage = uploadProfileImage;
exports.uploadCoverImage = uploadCoverImage;
const db_1 = require("../db");
async function me(req, res) {
    if (!req.userId)
        return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Not authenticated' } });
    const user = await db_1.prisma.user.findUnique({ where: { id: req.userId } });
    if (!user)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
    return res.json(user);
}
async function show(req, res) {
    const id = BigInt(String(req.params.id));
    const user = await db_1.prisma.user.findUnique({ where: { id } });
    if (!user)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
    return res.json(user);
}
async function update(req, res) {
    const id = req.params.id ? BigInt(String(req.params.id)) : req.userId;
    if (id !== req.userId) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot update other user' } });
    }
    const data = req.body || {};
    const updated = await db_1.prisma.user.update({ where: { id }, data });
    return res.json(updated);
}
async function destroy(req, res) {
    const id = BigInt(String(req.params.id));
    if (id !== req.userId) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete other user' } });
    }
    await db_1.prisma.user.delete({ where: { id } });
    return res.json({ message: 'User deleted' });
}
async function checkUsernameAvailability(req, res) {
    const { username } = req.body || {};
    if (!username)
        return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'username required' } });
    const exists = await db_1.prisma.user.findFirst({ where: { username } });
    return res.json({ available: !exists });
}
async function updateUsername(req, res) {
    const { username } = req.body || {};
    if (!username)
        return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'username required' } });
    const updated = await db_1.prisma.user.update({ where: { id: req.userId }, data: { username } });
    return res.json(updated);
}
async function store(req, res) {
    try {
        const data = req.body || {};
        const created = await db_1.prisma.user.create({ data });
        return res.status(201).json(created);
    }
    catch (e) {
        return res.status(400).json({ error: { code: 'USER_CREATE_FAILED', message: e?.message || 'Failed to create user' } });
    }
}
async function uploadProfileImage(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Profile image upload not implemented' } });
}
async function uploadCoverImage(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Cover image upload not implemented' } });
}
//# sourceMappingURL=users.controller.js.map