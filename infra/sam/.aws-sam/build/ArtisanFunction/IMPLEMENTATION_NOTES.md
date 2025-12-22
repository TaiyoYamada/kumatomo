# Post Model Extension and Multiple Image Support Implementation

## Overview

This implementation extends the existing Post model to support multiple images and shop associations while maintaining backward compatibility with the existing single image URL approach.

## Key Components

### 1. ImageService (`app/Services/ImageService.php`)

A service class that handles:
- Multiple image uploads with automatic resizing
- Image deletion (single and multiple)
- File storage management
- Optional image processing with Intervention/Image

**Key Methods:**
- `uploadMultipleImages(array $images)`: Handles multiple image uploads
- `uploadAndProcessImage(UploadedFile $image)`: Processes single image
- `deleteMultipleImages(array $imageUrls)`: Deletes multiple images
- `resizeImage()`: Resizes images (requires Intervention/Image package)

### 2. Extended PostController (`app/Http/Controllers/PostController.php`)

Enhanced with:
- Multiple image upload support (max 5 images)
- Shop association
- CRUD operations (show, update, delete)
- Proper error handling and validation
- Backward compatibility with single image_url

**New Endpoints:**
- `GET /api/posts/{post}` - Get single post with relationships
- `PUT /api/posts/{post}` - Update post (owner only)
- `DELETE /api/posts/{post}` - Delete post with images (owner only)
- `GET /api/shops/{shopId}/posts` - Get posts by shop with pagination

### 3. Model Relationships

**Post Model:**
- `belongsTo(Shop::class)` - Post belongs to a shop
- `hasMany(PostImage::class)` - Post has multiple images
- `belongsTo(User::class)` - Post belongs to a user

**PostImage Model:**
- `belongsTo(Post::class)` - Image belongs to a post
- Ordered by `display_order` field

**User Model:**
- Added `posts()` method as alias to `stories()`

## Validation Rules

### Post Creation/Update:
- `content`: required, string, max 500 characters
- `shop_id`: nullable, integer, must exist in shops table
- `images`: nullable, array, max 5 files
- `images.*`: image file, mimes: jpeg,png,jpg,gif, max 5MB
- `tags`: nullable, array of strings (max 20 chars each)
- `image_url`: nullable, url, max 2048 chars (backward compatibility)

## Backward Compatibility

The implementation maintains full backward compatibility:
- Existing `image_url` field is preserved
- Old API calls continue to work
- New `images` relationship provides multiple image support
- Both approaches can coexist

## Error Handling

Comprehensive error handling with specific error codes:
- `VALIDATION_ERROR`: Input validation failures
- `FORBIDDEN`: Authorization errors (editing/deleting others' posts)
- `POST_CREATION_FAILED`: Post creation errors
- `POST_DELETION_FAILED`: Post deletion errors

## Database Transactions

All multi-step operations (create/delete with images) use database transactions to ensure data consistency.

## Testing

### Unit Tests (`tests/Unit/ImageServiceTest.php`)
- Image service functionality
- File upload/deletion operations
- Multiple image handling

### Feature Tests (`tests/Feature/PostTest.php`)
- Complete CRUD operations
- Multiple image uploads
- Validation testing
- Authorization testing
- Relationship loading

## Usage Examples

### Creating a post with multiple images:
```php
POST /api/posts
Content-Type: multipart/form-data

{
    "content": "Great meal at this restaurant!",
    "shop_id": 1,
    "images": [file1.jpg, file2.jpg, file3.jpg],
    "tags": ["food", "restaurant"]
}
```

### Creating a post with legacy image URL:
```php
POST /api/posts
Content-Type: application/json

{
    "content": "Great meal!",
    "image_url": "https://example.com/image.jpg"
}
```

### Getting posts with all relationships:
```php
GET /api/posts

Response includes:
- user: { id, name, ... }
- shop: { id, name, address, ... }
- images: [{ id, image_url, display_order }, ...]
```

## Requirements Fulfilled

This implementation addresses all requirements from the task:

✅ **1.1-1.5**: Post creation with multiple images, shop selection, validation
✅ **2.1-2.5**: Post editing and deletion with proper authorization
✅ **Backward Compatibility**: Existing functionality preserved
✅ **Image Processing**: Service class with resize capabilities
✅ **Error Handling**: Comprehensive error responses
✅ **Testing**: Unit and feature tests included

## Next Steps

1. Install Intervention/Image package for advanced image processing:
   ```bash
   composer require intervention/image
   ```

2. Configure image storage settings in `config/filesystems.php`

3. Set up proper image optimization and CDN if needed

4. Add image validation for file types and sizes based on requirements

5. Consider adding image metadata storage (EXIF data, dimensions, etc.)