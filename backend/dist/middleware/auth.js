"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
// Temporary lightweight auth to mimic Sanctum-protected endpoints.
// For development: set header `Authorization: Bearer <numericUserId>`
function authMiddleware(req, res, next) {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.substring('Bearer '.length) : undefined;
    const xUserId = req.headers['x-user-id'];
    const raw = (Array.isArray(xUserId) ? xUserId[0] : xUserId) || token;
    if (!raw) {
        return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing authentication' } });
    }
    const n = Number(raw);
    if (!Number.isFinite(n) || n <= 0) {
        return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid token' } });
    }
    req.userId = BigInt(n);
    return next();
}
//# sourceMappingURL=auth.js.map