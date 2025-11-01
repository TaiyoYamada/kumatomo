import { Request, Response } from 'express';

export async function upload(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Unified upload not implemented' } });
}

export async function uploadMultiple(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Unified upload multiple not implemented' } });
}

export async function store(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Legacy upload not implemented' } });
}

export async function storeMultiple(_req: Request, res: Response) {
  return res.status(501).json({ error: { code: 'NOT_IMPLEMENTED', message: 'Legacy upload multiple not implemented' } });
}

