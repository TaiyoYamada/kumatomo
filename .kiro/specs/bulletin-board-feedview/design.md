# Design Document

## Overview

This design transforms the existing FeedView from a simple timeline interface into a comprehensive bulletin board-style application. The bulletin board will introduce a new Post model to replace Story usage, providing enhanced visual organization, categorization, and location-based interaction capabilities for community-focused content.

The design leverages SwiftUI's native components and follows iOS design patterns to create an intuitive, visually appealing bulletin board experience that feels natural to iOS users while providing the structured organization of a traditional community bulletin board.

## Architecture

### Component Hierarchy

```
BulletinBoardFeedView (Main Container)
├── NavigationView
│   ├── CitySelector (Top App Bar)
│   ├── TabView (Follow, All Posts, Events)
│   ├── SearchAndFilterBar
│   └── ScrollView
│       ├── LazyVGrid (Bulletin Board Layout)
│       │   └── BulletinPostCard (New Post Card)
│       │       ├── PostHeader (User info, timestamp, category, location)
│       │       ├── PostContent (Title, content preview, image)
│       │       ├── PostTags
│       │       └── PostActions (Like, comment, share)
│       └── FloatingActionButton (Create Post)
└── Overlays (Loading, Error, Modals)
```

### Data Flow

```
BulletinBoardFeedView
├── PostViewModel (New)
│   ├── posts: [Post]
│   ├── filteredPosts: [Post]
│   ├── pinnedPosts: [Post]
│   ├── followedPosts: [Post]
│   ├── eventPosts: [Post]
│   ├── selectedCity: City
│   ├── selectedTab: TabType
│   ├── categories: [PostCategory]
│   ├── selectedCategory: PostCategory?
│   ├── searchText: String
│   └── activeFilters: [FilterType]
├── CityManager
│   └── manages city selection and location data
├── CategoryManager
│   └── manages post categorization
└── FilterManager
    └── handles search and filtering logic
```

## Components and Interfaces

### 1. Enhanced Story Model Extensions

```swift
extension Story {
    var category: PostCategory {
        // Derive category from tags or content analysis
    }

    var isPinned: Bool {
        // Check if post is pinned (could be from tags or separate field)
    }

    var priority: PostPriority {
        // Determine priority level
    }

    var contentPreview: String {
        // Truncated content for card display
    }
}

enum PostCategory: String, CaseIterable {
    case general = "General"
    case announcement = "Announcement"
    case discussion = "Discussion"
    case event = "Event"
    case question = "Question"

    var color: Color {
        // Category-specific colors
    }

    var icon: String {
        // SF Symbol for category
    }
}

enum PostPriority: Int, CaseIterable {
    case normal = 0
    case important = 1
    case urgent = 2

    var borderColor: Color {
        // Priority-specific border colors
    }
}
```

### 2. BulletinBoardFeedView

Main container view that orchestrates the bulletin board layout and functionality.

**Key Features:**

- Grid-based layout using LazyVGrid
- Search and filter integration
- Category-based organization
- Pinned posts section
- Pull-to-refresh functionality

**Layout Configuration:**

- Adaptive grid columns based on device size
- Minimum card width: 300pt (iPhone), 350pt (iPad)
- Spacing: 16pt between cards
- Padding: 16pt horizontal margins

### 3. BulletinPostCard

Enhanced version of the current StoryCardView with bulletin board-specific features.

**Visual Enhancements:**

- Larger card size with more prominent visual hierarchy
- Category badge in top-right corner
- Priority border indicators
- Enhanced user profile display
- Action buttons with improved spacing
- Image thumbnails with proper aspect ratios

**Interactive Features:**

- Tap to expand to detail view
- Long press for context menu
- Swipe gestures for quick actions
- Like button with animation feedback

### 4. SearchAndFilterBar

Integrated search and filtering interface at the top of the feed.

**Components:**

- Search text field with real-time filtering
- Filter button with popover menu
- Active filter chips display
- Clear filters button

### 5. CategoryFilterChips

Horizontal scrollable row of category filter chips below the search bar.

**Features:**

- Color-coded category chips
- Selection state management
- Smooth scrolling animation
- Badge counts for each category

### 6. PinnedPostsSection

Special section for pinned/important posts that appears at the top.

**Characteristics:**

- Distinct visual styling with pin icons
- Collapsible section when multiple pinned posts exist
- Priority-based ordering within pinned posts
- Quick access navigation

## Data Models

### Enhanced StoryViewModel

```swift
@MainActor
class StoryViewModel: ObservableObject {
    // Existing properties...

    // New bulletin board properties
    @Published var filteredStories: [Story] = []
    @Published var pinnedStories: [Story] = []
    @Published var selectedCategory: PostCategory?
    @Published var searchText: String = ""
    @Published var activeFilters: Set<FilterType> = []
    @Published var categories: [PostCategory] = PostCategory.allCases

    // New methods
    func filterStories()
    func searchStories(query: String)
    func toggleCategory(_ category: PostCategory)
    func togglePin(for story: Story)
    func categorizeStories()
}
```

### FilterType Enum

```swift
enum FilterType: String, CaseIterable {
    case hasImage = "Has Image"
    case hasTitle = "Has Title"
    case recentlyPosted = "Recent"
    case mostLiked = "Popular"

    var icon: String {
        // SF Symbol for filter type
    }
}
```

## Error Handling

### Enhanced Error Management

Building on the existing error handling system, add bulletin board-specific error cases:

```swift
enum BulletinBoardError: LocalizedError {
    case categoryLoadFailed
    case filterApplicationFailed
    case searchIndexingFailed
    case pinnedPostsLoadFailed

    var errorDescription: String? {
        // Localized error messages
    }
}
```

### Error Recovery Strategies

- **Category Load Failure:** Fall back to default "General" category
- **Search Failure:** Display all posts with search disabled message
- **Filter Failure:** Reset to no filters applied
- **Network Errors:** Show cached content with offline indicator

## Testing Strategy

### Unit Tests

1. **Story Model Extensions**

   - Test category derivation logic
   - Test priority calculation
   - Test content preview generation

2. **ViewModel Logic**

   - Test filtering algorithms
   - Test search functionality
   - Test category management
   - Test pinned posts handling

3. **Filter and Search**
   - Test various search queries
   - Test filter combinations
   - Test performance with large datasets

### UI Tests

1. **Navigation and Interaction**

   - Test card tap navigation
   - Test search bar functionality
   - Test category filter selection
   - Test pull-to-refresh

2. **Layout and Responsiveness**

   - Test grid layout on different screen sizes
   - Test card sizing and spacing
   - Test scroll performance
   - Test orientation changes

3. **Accessibility**
   - Test VoiceOver navigation
   - Test dynamic type support
   - Test high contrast mode
   - Test reduced motion preferences

### Integration Tests

1. **API Integration**

   - Test story fetching with new filtering
   - Test category data synchronization
   - Test pinned posts API calls

2. **Performance Testing**
   - Test with large numbers of posts (1000+)
   - Test search performance
   - Test memory usage during scrolling
   - Test image loading performance

### Visual Testing

1. **Design Consistency**

   - Test category color schemes
   - Test priority indicators
   - Test card layouts across devices
   - Test dark mode compatibility

2. **Animation and Transitions**
   - Test filter application animations
   - Test card interaction feedback
   - Test search result transitions
   - Test loading state animations

## Implementation Considerations

### Performance Optimizations

- Use LazyVGrid for efficient memory usage with large datasets
- Implement image caching for post thumbnails
- Debounce search input to reduce API calls
- Use computed properties for filtered results
- Implement pagination for large bulletin boards

### Accessibility

- Provide meaningful accessibility labels for all interactive elements
- Support Dynamic Type for text scaling
- Ensure sufficient color contrast for category indicators
- Implement VoiceOver navigation hints
- Support reduced motion preferences

### Localization

- Prepare all text strings for localization
- Consider right-to-left language support
- Adapt date formatting for different locales
- Handle category names in multiple languages

### Future Extensibility

- Design category system to support custom categories
- Prepare for real-time updates and notifications
- Consider offline functionality for cached content
- Plan for advanced filtering options (date ranges, user filters)
- Design for potential integration with push notifications
