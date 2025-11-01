import { Router } from 'express';

export const router = Router();

// Storage proxy placeholder for backward compatibility
router.get(/^\/storage\/.*/, async (_req, res) => {
  // In Laravel this served local storage; here we likely use S3.
  // Implement actual storage proxy if needed.
  return res.status(404).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Storage proxy not configured' } });
});
