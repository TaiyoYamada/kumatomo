"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const http_1 = require("http");
const app_1 = require("./app");
// Ensure BigInt can be serialized in JSON responses
// eslint-disable-next-line @typescript-eslint/no-explicit-any
BigInt.prototype.toJSON = function () {
    return this.toString();
};
const app = (0, app_1.createApp)();
const PORT = parseInt(process.env.PORT || '8080', 10);
const server = (0, http_1.createServer)(app);
server.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`Express server listening on port ${PORT}`);
});
//# sourceMappingURL=index.js.map