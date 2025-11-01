"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.register = register;
exports.login = login;
const db_1 = require("../db");
async function register(req, res) {
    try {
        const { email, password, name, username } = req.body || {};
        if (!email || !password)
            return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'email and password required' } });
        const exists = await db_1.prisma.user.findFirst({ where: { email } });
        if (exists)
            return res.status(409).json({ error: { code: 'CONFLICT', message: 'Email already in use' } });
        const user = await db_1.prisma.user.create({ data: { email, password, name, username } });
        // Placeholder: return a fake token = user id (for dev middleware)
        return res.status(201).json({ user, token: String(user.id) });
    }
    catch (e) {
        return res.status(500).json({ error: { code: 'REGISTER_FAILED', message: e?.message || 'Failed to register' } });
    }
}
async function login(req, res) {
    const { email, password } = req.body || {};
    if (!email || !password)
        return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'email and password required' } });
    const user = await db_1.prisma.user.findFirst({ where: { email } });
    if (!user)
        return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' } });
    // NOTE: Password verification omitted; integrate real auth later.
    return res.json({ user, token: String(user.id) });
}
//# sourceMappingURL=auth.controller.js.map