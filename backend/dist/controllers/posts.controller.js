"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.index = index;
exports.store = store;
exports.show = show;
exports.update = update;
exports.destroy = destroy;
exports.indexByMunicipality = indexByMunicipality;
exports.indexByUser = indexByUser;
exports.indexByShop = indexByShop;
const db_1 = require("../db");
async function index(req, res) {
    const posts = await db_1.prisma.post.findMany({
        orderBy: { created_at: 'desc' },
        include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
    });
    const userId = req.userId;
    if (userId) {
        // attach engagement data
        const result = await Promise.all(posts.map(async (p) => {
            const [likeCount, bookmarkCount, commentCount, liked, bookmarked] = await Promise.all([
                db_1.prisma.like.count({ where: { post_id: p.id } }),
                db_1.prisma.bookmark.count({ where: { post_id: p.id } }),
                db_1.prisma.comment.count({ where: { post_id: p.id } }),
                db_1.prisma.like.findFirst({ where: { post_id: p.id, user_id: userId } }),
                db_1.prisma.bookmark.findFirst({ where: { post_id: p.id, user_id: userId } }),
            ]);
            return {
                ...p,
                like_count: likeCount,
                bookmark_count: bookmarkCount,
                comment_count: commentCount,
                is_liked_by_current_user: !!liked,
                is_bookmarked_by_current_user: !!bookmarked,
            };
        }));
        return res.json(result);
    }
    return res.json(posts);
}
async function store(req, res) {
    try {
        const { content, shop_id, tags, image_urls } = req.body || {};
        const hasContent = typeof content === 'string' && content.length > 0;
        const hasImages = Array.isArray(image_urls) && image_urls.length > 0;
        if (!hasContent && !hasImages) {
            return res.status(422).json({
                error: {
                    code: 'VALIDATION_FAILED',
                    message: '投稿内容または画像のいずれかが必要です',
                    details: { content_or_images: ['投稿内容または画像のいずれかを入力してください'] },
                },
            });
        }
        const post = await db_1.prisma.post.create({
            data: {
                user_id: req.userId,
                content: content ?? '',
                shop_id: shop_id ? BigInt(shop_id) : null,
                tags: tags ?? null,
            },
        });
        if (Array.isArray(image_urls) && image_urls.length) {
            await db_1.prisma.postImage.createMany({
                data: image_urls.map((url, index) => ({
                    post_id: post.id,
                    image_url: url,
                    display_order: index + 1,
                })),
            });
        }
        const created = await db_1.prisma.post.findUnique({
            where: { id: post.id },
            include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
        });
        return res.status(201).json(created);
    }
    catch (e) {
        return res.status(500).json({ error: { code: 'POST_CREATION_FAILED', message: e?.message || 'Failed to create post' } });
    }
}
async function show(req, res) {
    const id = BigInt(String(req.params.postId));
    const post = await db_1.prisma.post.findUnique({
        where: { id },
        include: {
            user: true,
            shop: true,
            images: { orderBy: { display_order: 'asc' } },
            comments: { include: { user: { select: { id: true, name: true, username: true, profile_image_url: true } } }, orderBy: { created_at: 'asc' } },
        },
    });
    if (!post)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Post not found' } });
    const userId = req.userId;
    if (userId) {
        const [likeCount, bookmarkCount, commentCount, liked, bookmarked] = await Promise.all([
            db_1.prisma.like.count({ where: { post_id: post.id } }),
            db_1.prisma.bookmark.count({ where: { post_id: post.id } }),
            db_1.prisma.comment.count({ where: { post_id: post.id } }),
            db_1.prisma.like.findFirst({ where: { post_id: post.id, user_id: userId } }),
            db_1.prisma.bookmark.findFirst({ where: { post_id: post.id, user_id: userId } }),
        ]);
        return res.json({
            ...post,
            like_count: likeCount,
            bookmark_count: bookmarkCount,
            comment_count: commentCount,
            is_liked_by_current_user: !!liked,
            is_bookmarked_by_current_user: !!bookmarked,
        });
    }
    return res.json(post);
}
async function update(req, res) {
    const id = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.post.findUnique({ where: { id } });
    if (!existing)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Post not found' } });
    if (existing.user_id !== req.userId) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'この投稿を編集する権限がありません' } });
    }
    const { content, shop_id, tags } = req.body || {};
    const updated = await db_1.prisma.post.update({ where: { id }, data: { content, shop_id: shop_id ? BigInt(shop_id) : null, tags } });
    const withRelations = await db_1.prisma.post.findUnique({ where: { id: updated.id }, include: { user: true, shop: true, images: true } });
    return res.json(withRelations);
}
async function destroy(req, res) {
    const id = BigInt(String(req.params.postId));
    const existing = await db_1.prisma.post.findUnique({ where: { id }, include: { images: true } });
    if (!existing)
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Post not found' } });
    if (existing.user_id !== req.userId) {
        return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'この投稿を削除する権限がありません' } });
    }
    // If using S3 or external storage, delete images there as needed.
    await db_1.prisma.post.delete({ where: { id } });
    return res.json({ message: '投稿が削除されました' });
}
async function indexByMunicipality(req, res) {
    const name = req.params.name;
    if (!name)
        return res.json([]);
    // Approximate: tags JSON array contains an item starting with name
    // For PG JSON array search, consider GIN index and @> operator.
    // Prisma doesn't provide JSON_SEARCH; emulate with contains match (may differ per DB)
    const posts = await db_1.prisma.post.findMany({
        where: { tags: { array_contains: [name] } },
        orderBy: { created_at: 'desc' },
        include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
    });
    return res.json(posts);
}
async function indexByUser(req, res) {
    const userId = BigInt(String(req.params.userId));
    const { page = '1', limit = '20' } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10));
    const take = Math.min(50, Math.max(1, parseInt(limit, 10)));
    const skip = (pageNum - 1) * take;
    const posts = await db_1.prisma.post.findMany({
        where: { user_id: userId },
        orderBy: { created_at: 'desc' },
        skip,
        take,
        include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
    });
    return res.json(posts);
}
async function indexByShop(req, res) {
    const shopId = BigInt(String(req.params.shopId));
    const { page = '1', per_page = '10' } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10));
    const take = Math.min(50, Math.max(1, parseInt(per_page, 10)));
    const skip = (pageNum - 1) * take;
    const [items, total] = await Promise.all([
        db_1.prisma.post.findMany({
            where: { shop_id: shopId },
            orderBy: { created_at: 'desc' },
            skip,
            take,
            include: { user: true, shop: true, images: { orderBy: { display_order: 'asc' } } },
        }),
        db_1.prisma.post.count({ where: { shop_id: shopId } }),
    ]);
    return res.json({ data: items, meta: { total, page: pageNum, per_page: take } });
}
//# sourceMappingURL=posts.controller.js.map