# Design Document

## Overview

This design document outlines the implementation of a modern, clean admin dashboard design system for the Hidamari admin application. The system will replace the current emoji-based navigation with a professional icon-based interface using Material Design Icons, implement the specified color scheme with orange accents, and provide a fully responsive layout using Vuetify 3 components.

The design focuses on creating a cohesive visual language that balances functionality with aesthetics, ensuring excellent usability across all device sizes while maintaining the clean, modern flat design principles specified in the requirements.

## Architecture

### Component Structure
```
AdminLayout (Main Layout Container)
├── AppBar (Fixed Header)
│   ├── Logo/System Name (Left)
│   └── User Actions (Right)
│       ├── Notifications
│       └── User Menu
├── NavigationDrawer (Sidebar)
│   ├── Navigation Items
│   └── Responsive Behavior
└── Main Content Area
    └── Router View (Dynamic Content)
```

### Theme Architecture
The design system will use Vuetify's theme configuration to define:
- Primary colors (orange accent #f9a825)
- Surface colors (white base, light grey background #f5f5f5)
- Typography settings (sans-serif font family)
- Component customizations

### Responsive Breakpoints
- Desktop (≥1024px): Fixed sidebar layout
- Tablet (768px-1023px): Collapsible sidebar with overlay
- Mobile (<768px): Drawer-based navigation

## Components and Interfaces

### 1. Theme Configuration (vuetify.ts)
**Purpose**: Define the color scheme and visual styling
**Key Features**:
- Custom orange accent color (#f9a825)
- Light grey background (#f5f5f5)
- White surface colors
- Sans-serif typography
- Subtle shadow definitions

### 2. App Bar Component
**Purpose**: Fixed header with branding and user actions
**Key Features**:
- Fixed positioning at top
- Logo/system name on left side
- User avatar and notification icons on right
- Subtle shadow and backdrop blur
- Responsive behavior for mobile

### 3. Navigation Drawer Component
**Purpose**: Sidebar navigation with menu items
**Key Features**:
- Fixed positioning on desktop
- Drawer behavior on mobile
- Material Design Icons instead of emojis
- Hover effects with orange accent
- Active state indication
- Smooth transitions

### 4. Main Layout Container
**Purpose**: Overall layout structure using Vuetify components
**Key Features**:
- v-app wrapper for Vuetify application
- Proper spacing and margins
- Responsive grid system
- Content area for cards, tables, and other components

### 5. Navigation Menu Items
**Purpose**: Individual menu items with icons and labels
**Key Features**:
- Material Design Icons (mdi-*)
- Text labels in Japanese
- Hover state with orange background
- Active state styling
- Router integration

## Data Models

### Theme Configuration Model
```typescript
interface ThemeConfig {
  colors: {
    primary: string;      // #f9a825 (orange accent)
    secondary: string;    // #6c757d (grey)
    surface: string;      // #ffffff (white)
    background: string;   // #f5f5f5 (light grey)
    error: string;        // #dc3545 (red)
    warning: string;      // #ffc107 (yellow)
    info: string;         // #17a2b8 (blue)
    success: string;      // #28a745 (green)
  };
  typography: {
    fontFamily: string;   // sans-serif
  };
}
```

### Navigation Item Model
```typescript
interface NavigationItem {
  id: string;
  title: string;
  icon: string;         // Material Design Icon name
  route: string;        // Vue Router path
  active?: boolean;
  children?: NavigationItem[];
}
```

### Layout State Model
```typescript
interface LayoutState {
  sidebarOpen: boolean;
  isMobile: boolean;
  currentRoute: string;
  pageTitle: string;
}
```

## Error Handling

### Responsive Breakpoint Handling
- Graceful degradation for unsupported screen sizes
- Fallback layouts for edge cases
- Touch-friendly interactions on mobile devices

### Theme Loading
- Default theme fallback if custom theme fails to load
- Progressive enhancement for advanced styling features
- Accessibility compliance for color contrast

### Navigation State Management
- Proper handling of route changes
- Sidebar state persistence across page reloads
- Error boundaries for navigation failures

## Testing Strategy

### Unit Testing
- Theme configuration validation
- Navigation item rendering
- Responsive behavior testing
- Color contrast accessibility testing

### Integration Testing
- Layout component interaction
- Router integration with navigation
- Theme switching functionality
- Mobile drawer behavior

### Visual Regression Testing
- Screenshot comparison for layout consistency
- Cross-browser compatibility testing
- Mobile device testing on various screen sizes
- Dark/light theme switching (future enhancement)

### Accessibility Testing
- Keyboard navigation support
- Screen reader compatibility
- Color contrast validation
- Focus management in drawer navigation

## Implementation Details

### Vuetify Component Usage
```vue
<template>
  <v-app>
    <v-app-bar app fixed>
      <!-- Header content -->
    </v-app-bar>
    
    <v-navigation-drawer
      v-model="drawer"
      app
      fixed
      :temporary="isMobile"
    >
      <!-- Navigation content -->
    </v-navigation-drawer>
    
    <v-main>
      <v-container fluid>
        <!-- Main content -->
      </v-container>
    </v-main>
  </v-app>
</template>
```

### Color Scheme Implementation
- Primary: #f9a825 (Orange accent for buttons, links, active states)
- Surface: #ffffff (Card backgrounds, sidebar background)
- Background: #f5f5f5 (Main content area background)
- On-surface: #1a1a1a (Text on white backgrounds)
- On-primary: #ffffff (Text on orange backgrounds)

### Typography System
- Font Family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif
- Heading weights: 600-700
- Body text weight: 400-500
- Letter spacing: Optimized for readability

### Spacing System
- Base unit: 8px
- Padding/margins: Multiples of base unit (8px, 16px, 24px, 32px)
- Component spacing: Consistent across all interface elements
- Responsive scaling: Adjusted for mobile devices

### Shadow System
- Subtle shadows: 0 2px 4px rgba(0,0,0,0.1)
- Card shadows: 0 4px 8px rgba(0,0,0,0.12)
- Elevated elements: 0 8px 16px rgba(0,0,0,0.15)
- No heavy shadows to maintain flat design aesthetic