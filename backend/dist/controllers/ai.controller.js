"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.chat = chat;
exports.health = health;
async function chat(_req, res) {
    // Implement your AI provider integration here (e.g., via API or local runtime)
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'AI chat not implemented' } });
}
async function health(_req, res) {
    return res.json({ status: 'ok' });
}
//# sourceMappingURL=ai.controller.js.map