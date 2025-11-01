"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = require("express");
exports.router = (0, express_1.Router)();
// Storage proxy placeholder for backward compatibility
exports.router.get(/^\/storage\/.*/, async (_req, res) => {
    // In Laravel this served local storage; here we likely use S3.
    // Implement actual storage proxy if needed.
    return res.status(404).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Storage proxy not configured' } });
});
//# sourceMappingURL=web.js.map