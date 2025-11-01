import express from 'express';
// @ts-ignore - local ambient types or any
import cors from 'cors';
import dotenv from 'dotenv';

import { router as userRouter } from './routes/user';
import { router as adminRouter } from './routes/admin';
import { router as webRouter } from './routes/web';

dotenv.config();

export const createApp = () => {
  const app = express();

  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Health
  app.get('/', (_req, res) => {
    res.json({ message: 'kumatomo API (Express) is working!', version: '1.0.0', timestamp: new Date().toISOString() });
  });

  // Web (static-ish) routes
  app.use('/', webRouter);

  // Admin routes under /api/admin
  app.use('/api/admin', adminRouter);

  // User API routes under /api
  app.use('/api', userRouter);

  // Fallback 404
  app.use((_req, res) => {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found' } });
  });

  return app;
};
