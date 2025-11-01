"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.adminIndex = adminIndex;
exports.store = store;
exports.show = show;
exports.update = update;
exports.destroy = destroy;
exports.status = status;
exports.approve = approve;
exports.reject = reject;
const db_1 = require("../db");
async function index(req, res) {
    const userId = req.userId;
    const proposals = await db_1.prisma.shopProposal.findMany({ where: { user_id: userId }, orderBy: { created_at: 'desc' } });
    return res.json(proposals);
}
async function adminIndex(_req, res) {
    const proposals = await db_1.prisma.shopProposal.findMany({ orderBy: { created_at: 'desc' } });
    return res.json(proposals);
}
async function store(req, res) {
    const userId = req.userId;
    const created = await db_1.prisma.shopProposal.create({ data: { ...req.body, user_id: userId } });
    return res.status(201).json(created);
}
async function show(req, res) {
    const id = BigInt(String(req.params.proposalId || req.params.proposal));
    const proposal = await db_1.prisma.shopProposal.findUnique({ where: { id } });
    if (!proposal)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
    return res.json(proposal);
}
async function update(req, res) {
    const id = BigInt(String(req.params.proposalId || req.params.proposal));
    const proposal = await db_1.prisma.shopProposal.findUnique({ where: { id } });
    if (!proposal)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
    if (proposal.user_id !== req.userId)
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot update others\' proposal' } });
    const updated = await db_1.prisma.shopProposal.update({ where: { id }, data: req.body });
    return res.json(updated);
}
async function destroy(req, res) {
    const id = BigInt(String(req.params.proposalId || req.params.proposal));
    const proposal = await db_1.prisma.shopProposal.findUnique({ where: { id } });
    if (!proposal)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Proposal not found' } });
    if (proposal.user_id !== req.userId)
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Cannot delete others\' proposal' } });
    await db_1.prisma.shopProposal.delete({ where: { id } });
    return res.json({ message: 'Proposal deleted' });
}
async function status(_req, res) {
    // Placeholder: aggregate by status
    const [pending, approved, rejected] = await Promise.all([
        db_1.prisma.shopProposal.count({ where: { status: 'pending' } }),
        db_1.prisma.shopProposal.count({ where: { status: 'approved' } }),
        db_1.prisma.shopProposal.count({ where: { status: 'rejected' } }),
    ]);
    return res.json({ pending, approved, rejected });
}
async function approve(req, res) {
    const id = BigInt(String(req.params.proposalId));
    const updated = await db_1.prisma.shopProposal.update({ where: { id }, data: { status: 'approved', admin_notes: req.body?.admin_notes } });
    return res.json(updated);
}
async function reject(req, res) {
    const id = BigInt(String(req.params.proposalId));
    const updated = await db_1.prisma.shopProposal.update({ where: { id }, data: { status: 'rejected', admin_notes: req.body?.admin_notes } });
    return res.json(updated);
}
//# sourceMappingURL=shopProposals.controller.js.map