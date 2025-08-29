# Shop Search and Filtering API Documentation

This document describes the shop search and filtering functionality implemented in the ShopController.

## Endpoints

### 1. Shop List with Filtering
```
GET /api/shops
```

#### Query Parameters:
- `genre` (string, optional): Filter shops by genre
- `lat` (float, optional): Latitude for location-based search
- `lng` (float, optional): Longitude for location-based search  
- `radius` (integer, optional): Search radius in kilometers (default: 10km)
- `q` (string, optional): Keyword search (searches name, description, address)
- `page` (integer, optional): Page number for pagination
- `per_page` (integer, optional): Items per page (default: 10, max: 50)

#### Examples:

**Filter by genre:**
```
GET /api/shops?genre=レストラン
```

**Location-based search:**
```
GET /api/shops?lat=35.6812&lng=139.7671&radius=5
```

**Keyword search:**
```
GET /api/shops?q=ラーメン
```

**Combined filters:**
```
GET /api/shops?genre=レストラン&lat=35.6812&lng=139.7671&radius=10&q=美味しい&page=1&per_page=20
```

#### Response Format:
```json
{
    "data": [
        {
            "id": 1,
            "name": "美味しいラーメン店",
            "description": "醤油ラーメンが自慢のお店です",
            "address": "東京都渋谷区渋谷1-1-1",
            "phone": "03-1234-5678",
            "business_hours": "11:00-22:00",
            "genre": "ラーメン",
            "latitude": "35.6812000",
            "longitude": "139.7671000",
            "image_url": "https://example.com/shop1.jpg",
            "created_at": "2025-01-01T00:00:00.000000Z",
            "updated_at": "2025-01-01T00:00:00.000000Z",
            "distance": 2.5
        }
    ],
    "pagination": {
        "current_page": 1,
        "last_page": 3,
        "per_page": 10,
        "total": 25
    }
}
```

### 2. Shop Search
```
GET /api/shops/search
```

#### Query Parameters:
- `q` (string, required): Search keyword (min: 1, max: 100 characters)
- `page` (integer, optional): Page number for pagination
- `per_page` (integer, optional): Items per page (default: 10, max: 50)

#### Examples:

**Basic search:**
```
GET /api/shops/search?q=ラーメン
```

**Search with pagination:**
```
GET /api/shops/search?q=カフェ&page=2&per_page=5
```

#### Response Format:
Same as shop list endpoint.

### 3. Shop Details
```
GET /api/shops/{id}
```

#### Response Format:
```json
{
    "data": {
        "id": 1,
        "name": "美味しいラーメン店",
        "description": "醤油ラーメンが自慢のお店です",
        "address": "東京都渋谷区渋谷1-1-1",
        "phone": "03-1234-5678",
        "business_hours": "11:00-22:00",
        "genre": "ラーメン",
        "latitude": "35.6812000",
        "longitude": "139.7671000",
        "image_url": "https://example.com/shop1.jpg",
        "created_at": "2025-01-01T00:00:00.000000Z",
        "updated_at": "2025-01-01T00:00:00.000000Z",
        "posts": [
            {
                "id": 1,
                "content": "とても美味しかったです！",
                "user": {
                    "id": 1,
                    "name": "田中太郎"
                },
                "images": [
                    {
                        "id": 1,
                        "image_url": "https://example.com/post1.jpg",
                        "display_order": 1
                    }
                ]
            }
        ]
    }
}
```

### 4. Shop Posts
```
GET /api/shops/{id}/posts
```

#### Query Parameters:
- `page` (integer, optional): Page number for pagination
- `per_page` (integer, optional): Items per page (default: 10)

#### Response Format:
```json
{
    "data": [
        {
            "id": 1,
            "content": "とても美味しかったです！",
            "shop_id": 1,
            "user": {
                "id": 1,
                "name": "田中太郎"
            },
            "images": [
                {
                    "id": 1,
                    "image_url": "https://example.com/post1.jpg",
                    "display_order": 1
                }
            ]
        }
    ],
    "pagination": {
        "current_page": 1,
        "last_page": 2,
        "per_page": 10,
        "total": 15
    }
}
```

## Search Features

### 1. Genre Filtering
- Exact match filtering by shop genre
- Case-sensitive matching

### 2. Location-Based Search
- Uses Haversine formula to calculate distance
- Results include calculated distance in kilometers
- Results are ordered by distance (nearest first)
- Default radius is 10km, customizable via `radius` parameter

### 3. Keyword Search
- Searches across multiple fields:
  - Shop name (`name`)
  - Shop description (`description`)
  - Shop address (`address`)
- Uses LIKE operator with wildcards for partial matching
- Case-insensitive search

### 4. Pagination
- All endpoints support pagination
- Default page size: 10 items
- Maximum page size: 50 items
- Returns pagination metadata

## Error Handling

### Validation Errors (422)
```json
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "入力データに問題があります",
        "details": {
            "q": ["検索キーワードは必須です"]
        }
    }
}
```

### Shop Not Found (404)
```json
{
    "error": {
        "code": "SHOP_NOT_FOUND",
        "message": "お店が見つかりません"
    }
}
```

### Server Error (500)
```json
{
    "error": {
        "code": "SHOP_FETCH_ERROR",
        "message": "お店の取得に失敗しました",
        "details": "Detailed error message (only in debug mode)"
    }
}
```

## Implementation Details

### Database Indexes
The following indexes are recommended for optimal performance:
- `idx_genre` on `shops.genre`
- `idx_location` on `shops.latitude, shops.longitude`

### Query Optimization
- Location-based searches use spatial calculations
- Keyword searches use LIKE operators with proper indexing
- Results are paginated to prevent memory issues
- Related data (posts, users, images) are eager-loaded to prevent N+1 queries

### Authentication
All endpoints require authentication via Laravel Sanctum.