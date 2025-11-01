import { createServer } from 'http';
import { createApp } from './app';

// Ensure BigInt can be serialized in JSON responses
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

const app = createApp();

const PORT = parseInt(process.env.PORT || '8080', 10);

const server = createServer(app);

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Express server listening on port ${PORT}`);
});
