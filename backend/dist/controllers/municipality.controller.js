"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
// Simple static example list; replace with DB if needed
const municipalities = [
    '熊本市',
    '熊本市中央区',
    '熊本市東区',
    '熊本市西区',
    '熊本市南区',
    '熊本市北区',
];
async function index(_req, res) {
    return res.json(municipalities);
}
//# sourceMappingURL=municipality.controller.js.map