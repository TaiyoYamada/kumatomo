# EngagementViewModel

The `EngagementViewModel` is responsible for managing liked and bookmarked posts collections with proper loading states, error handling, and optimistic updates.

## Features

### Collections Management
- **Liked Posts**: Manages collection of posts the user has liked
- **Bookmarked Posts**: Manages collection of posts the user has bookmarked
- **Pagination**: Supports loading more posts with page tracking
- **Refresh**: Supports pull-to-refresh functionality

### Optimistic Updates
- **Like Toggle**: Immediate UI updates with server sync and rollback on failure
- **Bookmark Toggle**: Immediate UI updates with server sync and rollback on failure
- **Concurrent Protection**: Prevents multiple simultaneous operations on the same post

### State Management
- **Loading States**: Separate loading states for different operations
- **Error Handling**: Comprehensive error handling with user feedback
- **Success Feedback**: Success messages for user actions

## Usage

### Basic Setup
```swift
@StateObject private var engagementViewModel = EngagementViewModel()
```

### Loading Collections
```swift
// Load liked posts
await engagementViewModel.loadLikedPosts()

// Load bookmarked posts  
await engagementViewModel.loadBookmarkedPosts()

// Refresh collections
await engagementViewModel.refreshLikedPosts()
await engagementViewModel.refreshBookmarkedPosts()

// Load more (pagination)
await engagementViewModel.loadMoreLikedPosts()
await engagementViewModel.loadMoreBookmarkedPosts()
```

### Engagement Actions
```swift
// Toggle like with optimistic updates
await engagementViewModel.toggleLike(for: post)

// Toggle bookmark with optimistic updates
await engagementViewModel.toggleBookmark(for: post)
```

### State Checking
```swift
// Check if operations are in progress
if engagementViewModel.isLiking(postId: post.id) {
    // Show loading indicator
}

if engagementViewModel.isBookmarking(postId: post.id) {
    // Show loading indicator
}

// Check collection states
if engagementViewModel.hasLikedPosts {
    // Show liked posts
} else {
    // Show empty state
}
```

### Error Handling
```swift
// Monitor error state
.alert("エラー", isPresented: $engagementViewModel.showErrorAlert) {
    Button("OK") { }
} message: {
    Text(engagementViewModel.errorMessage ?? "")
}
```

### Success Feedback
```swift
// Monitor success messages
.overlay(
    Group {
        if engagementViewModel.showSuccessMessage {
            Text(engagementViewModel.successMessage)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
)
```

## Properties

### Collections
- `likedPosts: [Post]` - Array of liked posts
- `bookmarkedPosts: [Post]` - Array of bookmarked posts

### Loading States
- `isLoadingLikedPosts: Bool` - Loading liked posts
- `isLoadingBookmarkedPosts: Bool` - Loading bookmarked posts
- `isRefreshingLikedPosts: Bool` - Refreshing liked posts
- `isRefreshingBookmarkedPosts: Bool` - Refreshing bookmarked posts

### Action States
- `likingPostIds: Set<Int>` - Posts currently being liked/unliked
- `bookmarkingPostIds: Set<Int>` - Posts currently being bookmarked/unbookmarked

### Error & Success
- `errorMessage: String?` - Current error message
- `showErrorAlert: Bool` - Whether to show error alert
- `successMessage: String` - Current success message
- `showSuccessMessage: Bool` - Whether to show success message

### Pagination
- `hasMoreLikedPosts: Bool` - Whether more liked posts are available
- `hasMoreBookmarkedPosts: Bool` - Whether more bookmarked posts are available
- `likedPostsPage: Int` - Current page for liked posts
- `bookmarkedPostsPage: Int` - Current page for bookmarked posts

## Computed Properties

- `hasLikedPosts: Bool` - Whether user has any liked posts
- `hasBookmarkedPosts: Bool` - Whether user has any bookmarked posts
- `isPerformingAnyAction: Bool` - Whether any operation is in progress
- `hasNoEngagement: Bool` - Whether collections are empty
- `totalEngagementCount: Int` - Total number of engaged posts
- `formattedCounts: (likedPosts: String, bookmarkedPosts: String)` - Formatted count strings
- `engagementSummary: String` - Summary of engagement activity

## Methods

### Collection Management
- `loadLikedPosts(refresh: Bool = false)` - Load liked posts
- `loadBookmarkedPosts(refresh: Bool = false)` - Load bookmarked posts
- `refreshLikedPosts()` - Refresh liked posts
- `refreshBookmarkedPosts()` - Refresh bookmarked posts
- `loadMoreLikedPosts()` - Load more liked posts (pagination)
- `loadMoreBookmarkedPosts()` - Load more bookmarked posts (pagination)

### Engagement Actions
- `toggleLike(for post: Post)` - Toggle like status with optimistic updates
- `toggleBookmark(for post: Post)` - Toggle bookmark status with optimistic updates

### Utility Methods
- `isLiking(postId: Int) -> Bool` - Check if post is being liked
- `isBookmarking(postId: Int) -> Bool` - Check if post is being bookmarked
- `getPost(byId postId: Int) -> Post?` - Get post from collections
- `removePost(withId postId: Int)` - Remove post from collections
- `reset()` - Reset all state

## Requirements Compliance

This ViewModel implements the following requirements:

### Requirement 2: Like Functionality (2.1-2.5)
- ✅ Immediate like state toggle and count update
- ✅ Active/inactive state management
- ✅ API persistence via EngagementAPIService
- ✅ Rollback on API failure with error messages

### Requirement 3: Bookmark Functionality (3.1-3.5)
- ✅ Immediate bookmark state toggle and count update
- ✅ Active/inactive state management
- ✅ API persistence via EngagementAPIService
- ✅ Rollback on API failure with error messages

### Requirement 5: Sidebar Navigation Enhancement (5.1-5.5)
- ✅ Liked posts collection management
- ✅ Bookmarked posts collection management
- ✅ Compatible with existing post list UI
- ✅ Empty state handling support

## Testing

The ViewModel includes comprehensive unit tests covering:
- State management
- Optimistic updates
- Error handling
- Pagination
- Concurrent operations
- Utility methods
- Integration scenarios

Run tests with:
```bash
xcodebuild test -project kumatomo.xcodeproj -scheme kumatomo -only-testing:kumatomoTests/EngagementViewModelTests
```