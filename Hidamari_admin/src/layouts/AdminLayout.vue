<template>
  <div class="admin-layout">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="logo">
          <span class="logo-icon">🌻</span>
          <span class="logo-text">Hidamari</span>
        </div>
      </div>
      
      <nav class="sidebar-nav">
        <router-link to="/dashboard" class="nav-item">
          <span class="nav-icon">📊</span>
          <span class="nav-text">ダッシュボード</span>
        </router-link>
        <router-link to="/shops" class="nav-item">
          <span class="nav-icon">🏪</span>
          <span class="nav-text">お店管理</span>
        </router-link>
        <router-link to="/users" class="nav-item">
          <span class="nav-icon">👥</span>
          <span class="nav-text">ユーザー管理</span>
        </router-link>
        <router-link to="/analytics" class="nav-item">
          <span class="nav-icon">📈</span>
          <span class="nav-text">分析</span>
        </router-link>
        <router-link to="/settings" class="nav-item">
          <span class="nav-icon">⚙️</span>
          <span class="nav-text">設定</span>
        </router-link>
      </nav>
    </aside>

    <!-- Main Content -->
    <div class="main-wrapper">
      <!-- Top Header -->
      <header class="top-header">
        <div class="header-left">
          <h1 class="page-title">{{ pageTitle }}</h1>
        </div>
        <div class="header-right">
          <div class="search-box">
            <input type="text" placeholder="検索..." class="search-input">
            <span class="search-icon">🔍</span>
          </div>
          <div class="user-menu">
            <div class="user-avatar">👤</div>
            <span class="user-name">管理者</span>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="main-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const pageTitle = computed(() => {
  const titles = {
    '/dashboard': 'ダッシュボード',
    '/shops': 'お店管理',
    '/shops/create': '新規お店登録',
    '/users': 'ユーザー管理',
    '/analytics': '分析',
    '/settings': '設定'
  }
  return titles[route.path] || 'Hidamari 管理画面'
})
</script>

<style scoped>
.admin-layout {
  min-height: 100vh;
  background-color: #f1f5f9;
  position: relative;
}

/* Sidebar - 完全固定 */
.sidebar {
  width: 280px;
  background: linear-gradient(180deg, #0f172a 0%, #1e293b 50%, #334155 100%);
  color: white;
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  z-index: 1000;
  box-shadow: 4px 0 20px rgba(0, 0, 0, 0.15);
  backdrop-filter: blur(10px);
}

.sidebar-header {
  padding: 2rem 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.05);
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.logo-icon {
  font-size: 2rem;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
}

.logo-text {
  font-size: 1.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #fbbf24, #f59e0b);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  letter-spacing: -0.025em;
}

.sidebar-nav {
  padding: 2rem 0;
  height: calc(100vh - 120px);
  overflow-y: auto;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 1.5rem;
  margin: 0.25rem 1rem;
  color: #cbd5e1;
  text-decoration: none;
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  font-weight: 500;
}

.nav-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: linear-gradient(180deg, #3b82f6, #1d4ed8);
  border-radius: 0 4px 4px 0;
  transform: scaleY(0);
  transition: transform 0.3s ease;
}

.nav-item:hover {
  background: rgba(59, 130, 246, 0.1);
  color: white;
  transform: translateX(4px);
}

.nav-item:hover::before {
  transform: scaleY(1);
}

.nav-item.router-link-active {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(29, 78, 216, 0.1));
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.nav-item.router-link-active::before {
  transform: scaleY(1);
}

.nav-icon {
  font-size: 1.25rem;
  min-width: 1.25rem;
  filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.2));
}

.nav-text {
  font-size: 0.95rem;
  letter-spacing: 0.025em;
}

/* Main Wrapper - サイドバー分のマージン */
.main-wrapper {
  margin-left: 280px;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Top Header - 固定 */
.top-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  padding: 1.25rem 2rem;
  border-bottom: 1px solid rgba(226, 232, 240, 0.8);
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  position: sticky;
  top: 0;
  z-index: 900;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
  letter-spacing: -0.025em;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.search-box {
  position: relative;
}

.search-input {
  padding: 0.75rem 3rem 0.75rem 1.25rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  width: 350px;
  font-size: 0.95rem;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.search-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1), 0 4px 12px rgba(0, 0, 0, 0.1);
  background: white;
}

.search-input::placeholder {
  color: #94a3b8;
}

.search-icon {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: #64748b;
  font-size: 1.1rem;
}

.user-menu {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1.25rem;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid #e2e8f0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.user-menu:hover {
  background: white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-1px);
}

.user-avatar {
  width: 2.25rem;
  height: 2.25rem;
  background: linear-gradient(135deg, #3b82f6, #1d4ed8);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}

.user-name {
  font-weight: 600;
  color: #1e293b;
  font-size: 0.95rem;
}

/* Main Content - スクロール可能 */
.main-content {
  flex: 1;
  padding: 2.5rem;
  background: #f1f5f9;
  min-height: calc(100vh - 100px);
}

/* カスタムスクロールバー */
.sidebar-nav::-webkit-scrollbar {
  width: 6px;
}

.sidebar-nav::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.sidebar-nav::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

.sidebar-nav::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}

/* Responsive */
@media (max-width: 1024px) {
  .search-input {
    width: 250px;
  }
}

@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }
  
  .sidebar.sidebar-open {
    transform: translateX(0);
  }
  
  .main-wrapper {
    margin-left: 0;
  }
  
  .search-input {
    width: 200px;
  }
  
  .user-name {
    display: none;
  }
  
  .header-right {
    gap: 1rem;
  }
  
  .main-content {
    padding: 1.5rem;
  }
}
</style>