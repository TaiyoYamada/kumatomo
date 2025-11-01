"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.upload = upload;
exports.uploadMultiple = uploadMultiple;
exports.store = store;
exports.storeMultiple = storeMultiple;
async function upload(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Unified upload not implemented' } });
}
async function uploadMultiple(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Unified upload multiple not implemented' } });
}
async function store(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Legacy upload not implemented' } });
}
async function storeMultiple(_req, res) {
    return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Legacy upload multiple not implemented' } });
}
//# sourceMappingURL=images.controller.js.map