import { Request, Response } from 'express';

export async function chat(_req: Request, res: Response) {
  // Implement your AI provider integration here (e.g., via API or local runtime)
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'AI chat not implemented' } });
}

export async function health(_req: Request, res: Response) {
  return res.json({ status: 'ok' });
}

