import { Request, Response, NextFunction } from 'express';

declare global {
  namespace Express {
    interface Request {
      userId?: bigint;
    }
  }
}

// Temporary lightweight auth to mimic Sanctum-protected endpoints.
// For development: set header `Authorization: Bearer <numericUserId>`
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
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
