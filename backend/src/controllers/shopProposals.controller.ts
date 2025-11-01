import { Request, Response } from 'express';
import { prisma } from '../db';

export async function index(req: Request, res: Response) {
  const userId = req.userId!;
  const proposals = await prisma.shopProposal.findMany({ where: { user_id: userId }, orderBy: { created_at: 'desc' } });
  return res.json(proposals);
}

export async function adminIndex(_req: Request, res: Response) {
  const proposals = await prisma.shopProposal.findMany({ orderBy: { created_at: 'desc' } });
  return res.json(proposals);
}

export async function store(req: Request, res: Response) {
  const userId = req.userId!;
  const created = await prisma.shopProposal.create({ data: { ...req.body, user_id: userId } });
  return res.status(201).json(created);
}

export async function show(req: Request, res: Response) {
  const id = BigInt(String((req.params as any).proposalId || (req.params as any).proposal));
  const proposal = await prisma.shopProposal.findUnique({ where: { id } });
  if (!proposal) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
  return res.json(proposal);
}

export async function update(req: Request, res: Response) {
  const id = BigInt(String((req.params as any).proposalId || (req.params as any).proposal));
  const proposal = await prisma.shopProposal.findUnique({ where: { id } });
  if (!proposal) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
  if (proposal.user_id !== req.userId) return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot update others\' proposal' } });
  const updated = await prisma.shopProposal.update({ where: { id }, data: req.body });
  return res.json(updated);
}

export async function destroy(req: Request, res: Response) {
  const id = BigInt(String((req.params as any).proposalId || (req.params as any).proposal));
  const proposal = await prisma.shopProposal.findUnique({ where: { id } });
  if (!proposal) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
  if (proposal.user_id !== req.userId) return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete others\' proposal' } });
  await prisma.shopProposal.delete({ where: { id } });
  return res.json({ message: 'Proposal deleted' });
}

export async function status(_req: Request, res: Response) {
  // Placeholder: aggregate by status
  const [pending, approved, rejected] = await Promise.all([
    prisma.shopProposal.count({ where: { status: 'pending' } }),
    prisma.shopProposal.count({ where: { status: 'approved' } }),
    prisma.shopProposal.count({ where: { status: 'rejected' } }),
  ]);
  return res.json({ pending, approved, rejected });
}

export async function approve(req: Request, res: Response) {
  const id = BigInt(String(req.params.proposalId));
  const updated = await prisma.shopProposal.update({ where: { id }, data: { status: 'approved', admin_notes: req.body?.admin_notes } });
  return res.json(updated);
}

export async function reject(req: Request, res: Response) {
  const id = BigInt(String(req.params.proposalId));
  const updated = await prisma.shopProposal.update({ where: { id }, data: { status: 'rejected', admin_notes: req.body?.admin_notes } });
  return res.json(updated);
}
