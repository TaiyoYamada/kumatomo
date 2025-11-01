"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createApp = void 0;
const express_1 = __importDefault(require("express"));
// @ts-ignore - local ambient types or any
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const user_1 = require("./routes/user");
const admin_1 = require("./routes/admin");
const web_1 = require("./routes/web");
dotenv_1.default.config();
const createApp = () => {
    const app = (0, express_1.default)();
    app.use((0, cors_1.default)({ origin: true, credentials: true }));
    app.use(express_1.default.json({ limit: '10mb' }));
    app.use(express_1.default.urlencoded({ extended: true }));
    // Health
    app.get('/', (_req, res) => {
        res.json({ message: 'kumatomo API (Express) is working!', version: '1.0.0', timestamp: new Date().toISOString() });
    });
    // Web (static-ish) routes
    app.use('/', web_1.router);
    // Admin routes under /api/admin
    app.use('/api/admin', admin_1.router);
    // User API routes under /api
    app.use('/api', user_1.router);
    // Fallback 404
    app.use((_req, res) => {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found' } });
    });
    return app;
};
exports.createApp = createApp;
//# sourceMappingURL=app.js.map