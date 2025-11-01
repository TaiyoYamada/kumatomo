import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import * as Posts from '../controllers/posts.controller';
import * as Shops from '../controllers/shops.controller';
import * as Favorites from '../controllers/favorites.controller';
import * as Users from '../controllers/users.controller';
import * as Auth from '../controllers/auth.controller';
import * as Comments from '../controllers/comments.controller';
import * as Likes from '../controllers/likes.controller';
import * as Bookmarks from '../controllers/bookmarks.controller';
import * as AI from '../controllers/ai.controller';
import * as Search from '../controllers/search.controller';
import * as Images from '../controllers/images.controller';
import * as Proposals from '../controllers/shopProposals.controller';
import * as Municipality from '../controllers/municipality.controller';

export const router = Router();

// Public health/test
router.get('/', (_req, res) => {
  res.json({ message: 'kumatomo API is working!', version: '1.0.0', timestamp: new Date().toISOString() });
});

// Municipalities (public)
router.get('/municipalities', Municipality.index);

// Auth (public)
router.post('/register', Auth.register);
router.post('/login', Auth.login);

// Protected routes
router.use(authMiddleware);

// Current user
router.get('/user', Users.me);

// Users
router.get('/users/:id', Users.show);
router.put('/user/update', Users.update);
router.put('/users/:id', Users.update);
router.delete('/users/:id', Users.destroy);
router.post('/users/check-username', Users.checkUsernameAvailability);
router.put('/users/update-username', Users.updateUsername);
router.post('/users', Users.store);

// Unified image upload
router.post('/images/upload', Images.upload);
router.post('/images/upload-multiple', Images.uploadMultiple);
// Backward compatibility
router.post('/upload-profile-image', Users.uploadProfileImage);
router.post('/upload-cover-image', Users.uploadCoverImage);
router.post('/upload-image', Images.store);
router.post('/upload-images', Images.storeMultiple);

// Posts
router.get('/posts', Posts.index);
router.post('/posts', Posts.store);
router.get('/posts/:postId', Posts.show);
router.get('/posts/municipality/:name', Posts.indexByMunicipality);
router.put('/posts/:postId', Posts.update);
router.delete('/posts/:postId', Posts.destroy);
router.get('/users/:userId/posts', Posts.indexByUser);
router.get('/shops/:shopId/posts', Posts.indexByShop);

// Comments
router.get('/posts/:postId/comments', Comments.index);
router.post('/posts/:postId/comments', Comments.store);
router.delete('/comments/:commentId', Comments.destroy);

// Likes
router.post('/posts/:postId/like', Likes.toggle);
router.delete('/posts/:postId/like', Likes.destroy);
router.get('/user/liked-posts', Likes.likedPosts);

// Bookmarks
router.post('/posts/:postId/bookmark', Bookmarks.toggle);
router.delete('/posts/:postId/bookmark', Bookmarks.destroy);
router.get('/user/bookmarked-posts', Bookmarks.bookmarkedPosts);

// Favorites
router.get('/favorites', Favorites.index);
router.post('/favorites/toggle/:shopId', Favorites.toggle);
router.delete('/favorites/:favoriteId', Favorites.destroy);
router.get('/favorites/stats', Favorites.stats);
router.get('/favorites/check/:shopId', Favorites.check);

// Unified search
router.get('/search', Search.search);

// AI
router.post('/ai/chat', AI.chat);
router.get('/ai/health', AI.health);

// Shop proposals (user)
router.get('/shop-proposals', Proposals.index);
router.post('/shop-proposals', Proposals.store);
router.get('/shop-proposals/:proposal', Proposals.show);
router.put('/shop-proposals/:proposal', Proposals.update);
router.delete('/shop-proposals/:proposal', Proposals.destroy);
router.get('/shop-proposals-status', Proposals.status);

// Shops (public)
router.get('/shops', Shops.index);
router.get('/shops/search', Shops.search);
router.get('/shops/:id', Shops.show);
router.get('/shops/:id/posts', Shops.posts);
