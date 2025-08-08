<template>
  <div class="dashboard">
    <!-- Stats Cards -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon">🏪</div>
        <div class="stat-content">
          <div class="stat-number">{{ stats.totalShops }}</div>
          <div class="stat-label">総店舗数</div>
        </div>
        <div class="stat-change positive">+12%</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">👥</div>
        <div class="stat-content">
          <div class="stat-number">{{ stats.totalUsers }}</div>
          <div class="stat-label">登録ユーザー</div>
        </div>
        <div class="stat-change positive">+8%</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">📊</div>
        <div class="stat-content">
          <div class="stat-number">{{ stats.monthlyViews }}</div>
          <div class="stat-label">月間閲覧数</div>
        </div>
        <div class="stat-change negative">-3%</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">⭐</div>
        <div class="stat-content">
          <div class="stat-number">{{ stats.averageRating }}</div>
          <div class="stat-label">平均評価</div>
        </div>
        <div class="stat-change positive">+0.2</div>
      </div>
    </div>

    <!-- Charts and Recent Activity -->
    <div class="dashboard-grid">
      <!-- Chart Section -->
      <div class="chart-section">
        <div class="section-header">
          <h3>月別店舗登録数</h3>
          <select class="period-select">
            <option>過去6ヶ月</option>
            <option>過去12ヶ月</option>
          </select>
        </div>
        <div class="chart-placeholder">
          <div class="chart-bar" style="height: 60%"></div>
          <div class="chart-bar" style="height: 80%"></div>
          <div class="chart-bar" style="height: 45%"></div>
          <div class="chart-bar" style="height: 90%"></div>
          <div class="chart-bar" style="height: 70%"></div>
          <div class="chart-bar" style="height: 85%"></div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="activity-section">
        <div class="section-header">
          <h3>最近のアクティビティ</h3>
          <button class="view-all-btn">すべて表示</button>
        </div>
        <div class="activity-list">
          <div class="activity-item">
            <div class="activity-icon">🏪</div>
            <div class="activity-content">
              <div class="activity-text">新しい店舗「カフェ・ド・パリ」が登録されました</div>
              <div class="activity-time">2時間前</div>
            </div>
          </div>
          <div class="activity-item">
            <div class="activity-icon">👤</div>
            <div class="activity-content">
              <div class="activity-text">ユーザー「田中太郎」がアカウントを作成しました</div>
              <div class="activity-time">4時間前</div>
            </div>
          </div>
          <div class="activity-item">
            <div class="activity-icon">⭐</div>
            <div class="activity-content">
              <div class="activity-text">「イタリアンレストラン・ベラ」に新しいレビューが投稿されました</div>
              <div class="activity-time">6時間前</div>
            </div>
          </div>
          <div class="activity-item">
            <div class="activity-icon">🏪</div>
            <div class="activity-content">
              <div class="activity-text">「和食処・さくら」の情報が更新されました</div>
              <div class="activity-time">1日前</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="quick-actions">
      <h3>クイックアクション</h3>
      <div class="actions-grid">
        <router-link to="/shops/create" class="action-card">
          <div class="action-icon">➕</div>
          <div class="action-text">新規店舗登録</div>
        </router-link>
        <router-link to="/shops" class="action-card">
          <div class="action-icon">📋</div>
          <div class="action-text">店舗一覧</div>
        </router-link>
        <router-link to="/analytics" class="action-card">
          <div class="action-icon">📈</div>
          <div class="action-text">分析レポート</div>
        </router-link>
        <router-link to="/settings" class="action-card">
          <div class="action-icon">⚙️</div>
          <div class="action-text">システム設定</div>
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const stats = ref({
  totalShops: 0,
  totalUsers: 0,
  monthlyViews: 0,
  averageRating: 0
})
</script>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.stat-icon {
  font-size: 2rem;
  width: 3rem;
  height: 3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #3b82f6, #1d4ed8);
  border-radius: 12px;
}

.stat-content {
  flex: 1;
}

.stat-number {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e293b;
  line-height: 1;
}

.stat-label {
  font-size: 0.875rem;
  color: #64748b;
  margin-top: 0.25rem;
}

.stat-change {
  font-size: 0.875rem;
  font-weight: 600;
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
}

.stat-change.positive {
  color: #059669;
  background-color: #d1fae5;
}

.stat-change.negative {
  color: #dc2626;
  background-color: #fee2e2;
}

/* Dashboard Grid */
.dashboard-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
}

.chart-section,
.activity-section {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.section-header h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.period-select {
  padding: 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.875rem;
}

.view-all-btn {
  background: none;
  border: none;
  color: #3b82f6;
  font-size: 0.875rem;
  cursor: pointer;
  text-decoration: underline;
}

/* Chart Placeholder */
.chart-placeholder {
  height: 200px;
  display: flex;
  align-items: end;
  justify-content: space-around;
  gap: 1rem;
  padding: 1rem 0;
}

.chart-bar {
  background: linear-gradient(180deg, #3b82f6, #1d4ed8);
  width: 2rem;
  border-radius: 4px 4px 0 0;
  transition: all 0.3s;
}

.chart-bar:hover {
  opacity: 0.8;
}

/* Activity List */
.activity-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.activity-item {
  display: flex;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 8px;
  transition: background-color 0.2s;
}

.activity-item:hover {
  background-color: #f8fafc;
}

.activity-icon {
  font-size: 1.25rem;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f1f5f9;
  border-radius: 8px;
  flex-shrink: 0;
}

.activity-content {
  flex: 1;
}

.activity-text {
  font-size: 0.875rem;
  color: #374151;
  line-height: 1.4;
}

.activity-time {
  font-size: 0.75rem;
  color: #9ca3af;
  margin-top: 0.25rem;
}

/* Quick Actions */
.quick-actions {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.quick-actions h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 1.5rem 0;
}

.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.action-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  text-decoration: none;
  color: #374151;
  transition: all 0.2s;
}

.action-card:hover {
  border-color: #3b82f6;
  background-color: #f8fafc;
  transform: translateY(-1px);
}

.action-icon {
  font-size: 1.25rem;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f1f5f9, #e2e8f0);
  border-radius: 8px;
}

.action-text {
  font-weight: 500;
}

/* Responsive */
@media (max-width: 768px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .actions-grid {
    grid-template-columns: 1fr;
  }
}
</style>