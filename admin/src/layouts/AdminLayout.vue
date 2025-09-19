<template>
  <!-- App Bar (Fixed Header) -->
  <v-app-bar
    app
    fixed
    color="surface"
    elevation="0"
    height="64"
    class="app-header"
  >
    <!-- Mobile/Tablet menu button -->
    <v-app-bar-nav-icon
      v-if="isDrawerTemporary"
      @click="toggleDrawer"
      color="on-surface"
      class="drawer-toggle-btn"
    />
    
    <!-- Logo/System Name -->
    <div class="d-flex align-center logo-section">
      <v-icon
        v-if="!isMobile"
        color="primary"
        size="32"
        class="mr-3 logo-icon"
      >
        mdi-flower
      </v-icon>
      <v-toolbar-title class="text-h5 font-weight-bold system-title">
        kumatomo
      </v-toolbar-title>
      <v-chip
        v-if="!isMobile"
        size="x-small"
        color="primary"
        variant="outlined"
        class="ml-2"
      >
        Admin
      </v-chip>
    </div>

    <v-spacer />

    <!-- User Actions -->
    <div class="d-flex align-center user-actions">
      <!-- Notification Button -->
      <v-btn
        icon
        variant="text"
        color="on-surface"
        class="mr-2 notification-btn"
        size="40"
      >
        <v-icon size="20">mdi-bell-outline</v-icon>
        <v-badge
          color="error"
          content="3"
          offset-x="2"
          offset-y="2"
        />
      </v-btn>

      <!-- User Menu -->
      <v-menu offset-y>
        <template v-slot:activator="{ props }">
          <v-btn
            v-bind="props"
            variant="text"
            class="d-flex align-center user-menu-btn"
            height="40"
          >
            <v-avatar
              color="primary"
              size="32"
              class="mr-2"
            >
              <v-icon color="white" size="18">mdi-account</v-icon>
            </v-avatar>
            <div v-if="isDesktop" class="d-flex flex-column align-start mr-2">
              <span class="text-body-2 font-weight-medium">管理者</span>
              <span class="text-caption text-medium-emphasis">admin@hidamari.com</span>
            </div>
            <v-icon v-if="isDesktop" size="18">mdi-chevron-down</v-icon>
          </v-btn>
        </template>
        <v-list min-width="200">
          <v-list-item prepend-icon="mdi-account-circle">
            <v-list-item-title>プロフィール</v-list-item-title>
          </v-list-item>
          <v-list-item prepend-icon="mdi-cog">
            <v-list-item-title>設定</v-list-item-title>
          </v-list-item>
          <v-divider />
          <v-list-item prepend-icon="mdi-logout" class="text-error">
            <v-list-item-title>ログアウト</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </div>
  </v-app-bar>

  <!-- Navigation Drawer (Sidebar) -->
  <v-navigation-drawer
    v-if="!isStandalone"
    v-model="drawer"
    app
    :permanent="isDrawerPermanent"
    :temporary="isDrawerTemporary"
    color="surface"
    width="280"
    elevation="8"
    :touchless="false"
    :disable-resize-watcher="false"
    :disable-route-watcher="false"
    class="navigation-drawer"
    @click:outside="closeDrawerOnMobile"
  >
    <!-- Logo Section for Mobile/Tablet -->
    <div v-if="isDrawerTemporary" class="pa-4 d-flex align-center drawer-header">
      <v-icon
        color="primary"
        size="32"
        class="mr-3 drawer-logo-icon"
      >
        mdi-flower
      </v-icon>
      <span class="text-h6 font-weight-bold drawer-title">kumatomo</span>
      <v-spacer />
      <v-btn
        icon
        variant="text"
        size="small"
        @click="closeDrawerOnMobile"
        class="drawer-close-btn"
      >
        <v-icon size="20">mdi-close</v-icon>
      </v-btn>
    </div>

    <v-divider v-if="isDrawerTemporary" />

    <!-- Navigation Items -->
    <v-list nav>
      <v-list-item
        v-for="item in navigationItems"
        :key="item.route"
        :to="item.route"
        :prepend-icon="item.icon"
        :title="item.title"
        :active="isActiveRoute(item.route)"
        color="primary"
        class="nav-item"
        :class="{ 'nav-item--active': isActiveRoute(item.route) }"
        @click="closeDrawerOnMobile"
      />
    </v-list>
  </v-navigation-drawer>

  <!-- Main Content Area -->
  <v-main class="main-content">
    <v-container fluid class="pa-6 main-container">
      <router-view />
    </v-container>
  </v-main>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useDisplay } from 'vuetify'
import { useRoute } from 'vue-router'

// Vuetify display composable for responsive behavior
const { width } = useDisplay()
const route = useRoute()

// Reactive data
const drawer = ref(true)

// Computed properties for responsive breakpoints
const isDesktop = computed(() => width.value >= 1024)
const isTablet = computed(() => width.value >= 768 && width.value < 1024)
const isMobile = computed(() => width.value < 768)

// Computed property for drawer behavior
const isDrawerTemporary = computed(() => !isDesktop.value)
const isDrawerPermanent = computed(() => isDesktop.value)

// Standalone pages (no sidebar): login/register or routes with meta.standalone
const isStandalone = computed(() => {
  const standaloneMeta = route.meta && (route.meta.standalone === true)
  return standaloneMeta || route.path === '/login' || route.path === '/register'
})

// Helper function to determine active route
const isActiveRoute = (itemRoute) => {
  // Handle exact match for dashboard
  if (itemRoute === '/dashboard') {
    return route.path === '/dashboard'
  }
  
  // Handle nested routes (e.g., /shops includes /shops/create, /shops/:id/edit)
  if (itemRoute === '/shops') {
    return route.path.startsWith('/shops')
  }
  
  // Handle other routes with exact match
  return route.path === itemRoute
}

// Navigation items
const navigationItems = [
  {
    title: 'ダッシュボード',
    icon: 'mdi-view-dashboard',
    route: '/dashboard'
  },
  {
    title: 'お店管理',
    icon: 'mdi-store',
    route: '/shops'
  },
  {
    title: 'ユーザー管理',
    icon: 'mdi-account-group',
    route: '/users'
  },
  {
    title: '分析',
    icon: 'mdi-chart-line',
    route: '/analytics'
  },
  {
    title: '設定',
    icon: 'mdi-cog',
    route: '/settings'
  }
]

// Handle responsive drawer behavior
const handleResize = () => {
  if (isDesktop.value) {
    // Desktop: drawer is always open and permanent
    drawer.value = true
  } else {
    // Mobile/Tablet: drawer is closed by default and temporary
    drawer.value = false
  }
}

// Toggle drawer function for mobile navigation
const toggleDrawer = () => {
  drawer.value = !drawer.value
}

// Close drawer when clicking outside on mobile/tablet
const closeDrawerOnMobile = () => {
  if (isDrawerTemporary.value) {
    drawer.value = false
  }
}

// Lifecycle hooks
onMounted(() => {
  handleResize()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
/* CSS Custom Properties for consistent orange accent usage */
:root {
  --orange-primary: 249, 168, 37;
  --orange-hover: rgba(249, 168, 37, 0.08);
  --orange-active: rgba(249, 168, 37, 0.12);
  --orange-shadow: rgba(249, 168, 37, 0.15);
  --orange-focus: rgba(249, 168, 37, 0.2);
}
/* Search field removed */

/* Enhanced navigation item styling with consistent spacing */
.nav-item {
  margin: 0.25rem 0.75rem;
  border-radius: 0.75rem;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

/* Add subtle ripple effect */
.nav-item::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: radial-gradient(circle, rgba(var(--orange-primary), 0.1) 0%, transparent 70%);
  opacity: 0;
  transform: scale(0);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none;
}

.nav-item:active::before {
  opacity: 1;
  transform: scale(1);
}

/* Hover effects with light orange background */
.nav-item:hover {
  background-color: var(--orange-hover) !important;
  transform: translateX(4px);
  box-shadow: 0 2px 8px var(--orange-shadow);
}

.nav-item:hover :deep(.v-list-item__prepend .v-icon) {
  color: rgb(var(--v-theme-primary)) !important;
  transform: scale(1.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.nav-item:hover :deep(.v-list-item-title) {
  color: rgb(var(--v-theme-primary)) !important;
  font-weight: 600;
}

/* Active state styling with orange accent */
.nav-item--active,
.nav-item.v-list-item--active {
  background-color: var(--orange-active) !important;
  border-left: 4px solid rgb(var(--v-theme-primary));
  transform: translateX(4px);
  box-shadow: 0 4px 12px var(--orange-focus);
}

.nav-item--active :deep(.v-list-item__prepend .v-icon),
.nav-item.v-list-item--active :deep(.v-list-item__prepend .v-icon) {
  color: rgb(var(--v-theme-primary)) !important;
  transform: scale(1.15);
}

.nav-item--active :deep(.v-list-item-title),
.nav-item.v-list-item--active :deep(.v-list-item-title) {
  color: rgb(var(--v-theme-primary)) !important;
  font-weight: 700;
}

/* Focus states for accessibility */
.nav-item:focus-visible {
  outline: 2px solid rgb(var(--v-theme-primary));
  outline-offset: 2px;
}

/* Smooth icon transitions */
.nav-item :deep(.v-list-item__prepend .v-icon) {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.nav-item :deep(.v-list-item-title) {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Main content styling with consistent spacing */
.main-content {
  background-color: rgb(var(--v-theme-background));
  min-height: 100vh;
}

.main-container {
  max-width: none;
  padding: 1.5rem;
}

/* Navigation drawer styling with subtle shadows */
.v-navigation-drawer {
  border-right: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}

/* App bar styling with subtle shadows and consistent spacing */
.app-header {
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  background-color: rgba(255, 255, 255, 0.95) !important;
}

/* Enhanced app bar with consistent padding */
.app-header :deep(.v-toolbar__content) {
  padding-left: 1rem;
  padding-right: 1rem;
}

/* Enhanced user actions styling with consistent spacing */
.user-actions {
  gap: 0.5rem;
  padding: 0 0.5rem;
}

.notification-btn {
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.notification-btn:hover {
  background-color: var(--orange-hover) !important;
  transform: scale(1.05);
  box-shadow: 0 2px 8px var(--orange-shadow);
}

.notification-btn:hover :deep(.v-icon) {
  color: rgb(var(--v-theme-primary)) !important;
}

.user-menu-btn {
  border-radius: 12px;
  padding: 4px 8px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.user-menu-btn:hover {
  background-color: rgba(var(--orange-primary), 0.06) !important;
  transform: scale(1.02);
  box-shadow: 0 2px 8px rgba(var(--orange-primary), 0.1);
}

.user-menu-btn:hover :deep(.v-avatar) {
  transform: scale(1.1);
  box-shadow: 0 2px 8px rgba(var(--orange-primary), 0.3);
}

/* Focus states for accessibility */
.notification-btn:focus-visible,
.user-menu-btn:focus-visible {
  outline: 2px solid rgb(var(--v-theme-primary));
  outline-offset: 2px;
}

/* Logo and title styling with consistent spacing */
.logo-section {
  transition: all 0.2s ease;
  padding: 0 0.5rem;
}

.logo-icon {
  transition: transform 0.2s ease;
  margin-right: 0.75rem;
}

.logo-section:hover .logo-icon {
  transform: rotate(5deg) scale(1.05);
}

.system-title {
  color: rgb(var(--v-theme-on-surface));
  font-weight: 700;
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #ff6f00);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* Enhanced search field with orange accent */
.search-field {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.search-field:hover :deep(.v-field__outline) {
  border-color: rgba(var(--orange-primary), 0.4);
  box-shadow: 0 0 0 1px rgba(var(--orange-primary), 0.1);
}

/* Search field styles removed */

/* Mobile/Tablet navigation button styling */
.drawer-toggle-btn {
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.drawer-toggle-btn:hover {
  background-color: var(--orange-hover) !important;
  transform: scale(1.05);
}

.drawer-toggle-btn:hover :deep(.v-icon) {
  color: rgb(var(--v-theme-primary)) !important;
}

/* Navigation drawer responsive styling */
.navigation-drawer {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Drawer header styling for mobile/tablet */
.drawer-header {
  background: linear-gradient(135deg, rgba(var(--orange-primary), 0.05), rgba(var(--orange-primary), 0.02));
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}

.drawer-logo-icon {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.drawer-header:hover .drawer-logo-icon {
  transform: rotate(5deg) scale(1.05);
}

.drawer-title {
  color: rgb(var(--v-theme-on-surface));
  font-weight: 700;
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #ff6f00);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.drawer-close-btn {
  border-radius: 8px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.drawer-close-btn:hover {
  background-color: var(--orange-hover) !important;
  transform: scale(1.1);
}

.drawer-close-btn:hover :deep(.v-icon) {
  color: rgb(var(--v-theme-primary)) !important;
}

/* Enhanced drawer animations for mobile/tablet */
@media (max-width: 1023px) {
  .navigation-drawer :deep(.v-navigation-drawer__content) {
    overflow-x: hidden;
  }
  
  .navigation-drawer :deep(.v-overlay__scrim) {
    background-color: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
  }
}

/* Desktop-specific drawer styling with subtle shadows */
@media (min-width: 1024px) {
  .navigation-drawer {
    border-right: 1px solid rgba(var(--v-theme-on-surface), 0.08);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12);
  }
}

/* Touch-friendly navigation items on mobile/tablet with consistent spacing */
@media (max-width: 1023px) {
  .nav-item {
    min-height: 3rem;
    margin: 0.375rem 1rem;
    border-radius: 1rem;
  }
  
  .nav-item :deep(.v-list-item__content) {
    padding: 0.5rem 0;
  }
  
  .nav-item :deep(.v-list-item-title) {
    font-size: 1rem;
    font-weight: 500;
  }
  
  .nav-item :deep(.v-list-item__prepend .v-icon) {
    font-size: 1.5rem;
  }
}

/* Smooth drawer slide animations */
.v-navigation-drawer--temporary {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.v-navigation-drawer--temporary.v-navigation-drawer--active {
  transform: translateX(0);
}

.v-navigation-drawer--temporary:not(.v-navigation-drawer--active) {
  transform: translateX(-100%);
}
</style>
