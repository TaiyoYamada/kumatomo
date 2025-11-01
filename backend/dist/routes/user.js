"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const Posts = __importStar(require("../controllers/posts.controller"));
const Shops = __importStar(require("../controllers/shops.controller"));
const Favorites = __importStar(require("../controllers/favorites.controller"));
const Users = __importStar(require("../controllers/users.controller"));
const Auth = __importStar(require("../controllers/auth.controller"));
const Comments = __importStar(require("../controllers/comments.controller"));
const Likes = __importStar(require("../controllers/likes.controller"));
const Bookmarks = __importStar(require("../controllers/bookmarks.controller"));
const AI = __importStar(require("../controllers/ai.controller"));
const Search = __importStar(require("../controllers/search.controller"));
const Images = __importStar(require("../controllers/images.controller"));
const Proposals = __importStar(require("../controllers/shopProposals.controller"));
const Municipality = __importStar(require("../controllers/municipality.controller"));
exports.router = (0, express_1.Router)();
// Public health/test
exports.router.get('/', (_req, res) => {
    res.json({ message: 'kumatomo API is working!', version: '1.0.0', timestamp: new Date().toISOString() });
});
// Municipalities (public)
exports.router.get('/municipalities', Municipality.index);
// Auth (public)
exports.router.post('/register', Auth.register);
exports.router.post('/login', Auth.login);
// Protected routes
exports.router.use(auth_1.authMiddleware);
// Current user
exports.router.get('/user', Users.me);
// Users
exports.router.get('/users/:id', Users.show);
exports.router.put('/user/update', Users.update);
exports.router.put('/users/:id', Users.update);
exports.router.delete('/users/:id', Users.destroy);
exports.router.post('/users/check-username', Users.checkUsernameAvailability);
exports.router.put('/users/update-username', Users.updateUsername);
exports.router.post('/users', Users.store);
// Unified image upload
exports.router.post('/images/upload', Images.upload);
exports.router.post('/images/upload-multiple', Images.uploadMultiple);
// Backward compatibility
exports.router.post('/upload-profile-image', Users.uploadProfileImage);
exports.router.post('/upload-cover-image', Users.uploadCoverImage);
exports.router.post('/upload-image', Images.store);
exports.router.post('/upload-images', Images.storeMultiple);
// Posts
exports.router.get('/posts', Posts.index);
exports.router.post('/posts', Posts.store);
exports.router.get('/posts/:postId', Posts.show);
exports.router.get('/posts/municipality/:name', Posts.indexByMunicipality);
exports.router.put('/posts/:postId', Posts.update);
exports.router.delete('/posts/:postId', Posts.destroy);
exports.router.get('/users/:userId/posts', Posts.indexByUser);
exports.router.get('/shops/:shopId/posts', Posts.indexByShop);
// Comments
exports.router.get('/posts/:postId/comments', Comments.index);
exports.router.post('/posts/:postId/comments', Comments.store);
exports.router.delete('/comments/:commentId', Comments.destroy);
// Likes
exports.router.post('/posts/:postId/like', Likes.toggle);
exports.router.delete('/posts/:postId/like', Likes.destroy);
exports.router.get('/user/liked-posts', Likes.likedPosts);
// Bookmarks
exports.router.post('/posts/:postId/bookmark', Bookmarks.toggle);
exports.router.delete('/posts/:postId/bookmark', Bookmarks.destroy);
exports.router.get('/user/bookmarked-posts', Bookmarks.bookmarkedPosts);
// Favorites
exports.router.get('/favorites', Favorites.index);
exports.router.post('/favorites/toggle/:shopId', Favorites.toggle);
exports.router.delete('/favorites/:favoriteId', Favorites.destroy);
exports.router.get('/favorites/stats', Favorites.stats);
exports.router.get('/favorites/check/:shopId', Favorites.check);
// Unified search
exports.router.get('/search', Search.search);
// AI
exports.router.post('/ai/chat', AI.chat);
exports.router.get('/ai/health', AI.health);
// Shop proposals (user)
exports.router.get('/shop-proposals', Proposals.index);
exports.router.post('/shop-proposals', Proposals.store);
exports.router.get('/shop-proposals/:proposal', Proposals.show);
exports.router.put('/shop-proposals/:proposal', Proposals.update);
exports.router.delete('/shop-proposals/:proposal', Proposals.destroy);
exports.router.get('/shop-proposals-status', Proposals.status);
// Shops (public)
exports.router.get('/shops', Shops.index);
exports.router.get('/shops/search', Shops.search);
exports.router.get('/shops/:id', Shops.show);
exports.router.get('/shops/:id/posts', Shops.posts);
//# sourceMappingURL=user.js.map