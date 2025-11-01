import { Request, Response } from 'express';

// Simple static example list; replace with DB if needed
const municipalities = [
  '熊本市',
  '熊本市中央区',
  '熊本市東区',
  '熊本市西区',
  '熊本市南区',
  '熊本市北区',
];

export async function index(_req: Request, res: Response) {
  return res.json(municipalities);
}

