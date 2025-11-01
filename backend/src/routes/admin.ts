import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import * as AdminShops from '../controllers/adminShop.controller';
import * as Proposals from '../controllers/shopProposals.controller';
import * as Images from '../controllers/images.controller';

export const router = Router();

router.use(authMiddleware);

// Shop management
router.get('/shops', AdminShops.index);
router.post('/shops', AdminShops.store);
router.get('/shops/:id', AdminShops.show);
router.put('/shops/:id', AdminShops.update);
router.delete('/shops/:id', AdminShops.destroy);

// Shop proposals moderation
router.get('/shop-proposals', Proposals.adminIndex);
router.post('/shop-proposals/:proposalId/approve', Proposals.approve);
router.post('/shop-proposals/:proposalId/reject', Proposals.reject);

// Shop image upload
router.post('/shops/upload-image', Images.upload);

