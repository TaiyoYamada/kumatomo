<template>
  <div class="dashboard">
    <!-- Stats Cards -->
    <div class="stats-grid mb-6">
      <v-card class="stat-card pa-4 d-flex align-center" elevation="1">
        <div class="stat-icon mr-4">
          <v-icon color="white" size="24">mdi-store</v-icon>
        </div>
        <div class="stat-content flex-grow-1">
          <div class="stat-number text-h4 font-weight-bold">{{ stats.totalShops }}</div>
          <div class="stat-label text-body-2 text-medium-emphasis">総店舗数</div>
        </div>
        <v-chip class="stat-change" color="success" variant="tonal" size="small">+12%</v-chip>
      </v-card>
      
      <v-card class="stat-card pa-4 d-flex align-center" elevation="1">
        <div class="stat-icon mr-4">
          <v-icon color="white" size="24">mdi-account-group</v-icon>
        </div>
        <div class="stat-content flex-grow-1">
          <div class="stat-number text-h4 font-weight-bold">{{ stats.totalUsers }}</div>
          <div class="stat-label text-body-2 text-medium-emphasis">登録ユーザー</div>
        </div>
        <v-chip class="stat-change" color="success" variant="tonal" size="small">+8%</v-chip>
      </v-card>
      
      <v-card class="stat-card pa-4 d-flex align-center" elevation="1">
        <div class="stat-icon mr-4">
          <v-icon color="white" size="24">mdi-chart-line</v-icon>
        </div>
        <div class="stat-content flex-grow-1">
          <div class="stat-number text-h4 font-weight-bold">{{ stats.monthlyViews }}</div>
          <div class="stat-label text-body-2 text-medium-emphasis">月間閲覧数</div>
        </div>
        <v-chip class="stat-change" color="error" variant="tonal" size="small">-3%</v-chip>
      </v-card>
      
      <v-card class="stat-card pa-4 d-flex align-center" elevation="1">
        <div class="stat-icon mr-4">
          <v-icon color="white" size="24">mdi-star</v-icon>
        </div>
        <div class="stat-content flex-grow-1">
          <div class="stat-number text-h4 font-weight-bold">{{ stats.averageRating }}</div>
          <div class="stat-label text-body-2 text-medium-emphasis">平均評価</div>
        </div>
        <v-chip class="stat-change" color="success" variant="tonal" size="small">+0.2</v-chip>
      </v-card>
    </div>

    <!-- Charts and Recent Activity -->
    <div class="dashboard-grid mb-6">
      <!-- Chart Section -->
      <v-card class="chart-section pa-4" elevation="1">
        <div class="section-header d-flex justify-space-between align-center mb-4">
          <h3 class="text-h6 font-weight-medium">月別店舗登録数</h3>
          <v-select
            class="period-select"
            :items="['過去6ヶ月', '過去12ヶ月']"
            model-value="過去6ヶ月"
            variant="outlined"
            density="compact"
            hide-details
            style="max-width: 150px;"
          />
        </div>
        <div class="chart-placeholder d-flex align-end justify-space-around pa-4" style="height: 200px;">
          <div class="chart-bar" style="height: 60%"></div>
          <div class="chart-bar" style="height: 80%"></div>
          <div class="chart-bar" style="height: 45%"></div>
          <div class="chart-bar" style="height: 90%"></div>
          <div class="chart-bar" style="height: 70%"></div>
          <div class="chart-bar" style="height: 85%"></div>
        </div>
      </v-card>

      <!-- Recent Activity -->
      <v-card class="activity-section pa-4" elevation="1">
        <div class="section-header d-flex justify-space-between align-center mb-4">
          <h3 class="text-h6 font-weight-medium">最近のアクティビティ</h3>
          <v-btn variant="text" color="primary" size="small">すべて表示</v-btn>
        </div>
        <v-list class="activity-list pa-0">
          <v-list-item class="activity-item px-0 py-2">
            <template v-slot:prepend>
              <v-avatar class="activity-icon mr-3" color="primary" size="32">
                <v-icon color="white" size="16">mdi-store</v-icon>
              </v-avatar>
            </template>
            <v-list-item-title class="activity-text text-body-2">
              新しい店舗「カフェ・ド・パリ」が登録されました
            </v-list-item-title>
            <v-list-item-subtitle class="activity-time text-caption">
              2時間前
            </v-list-item-subtitle>
          </v-list-item>
          
          <v-list-item class="activity-item px-0 py-2">
            <template v-slot:prepend>
              <v-avatar class="activity-icon mr-3" color="primary" size="32">
                <v-icon color="white" size="16">mdi-account</v-icon>
              </v-avatar>
            </template>
            <v-list-item-title class="activity-text text-body-2">
              ユーザー「田中太郎」がアカウントを作成しました
            </v-list-item-title>
            <v-list-item-subtitle class="activity-time text-caption">
              4時間前
            </v-list-item-subtitle>
          </v-list-item>
          
          <v-list-item class="activity-item px-0 py-2">
            <template v-slot:prepend>
              <v-avatar class="activity-icon mr-3" color="primary" size="32">
                <v-icon color="white" size="16">mdi-star</v-icon>
              </v-avatar>
            </template>
            <v-list-item-title class="activity-text text-body-2">
              「イタリアンレストラン・ベラ」に新しいレビューが投稿されました
            </v-list-item-title>
            <v-list-item-subtitle class="activity-time text-caption">
              6時間前
            </v-list-item-subtitle>
          </v-list-item>
          
          <v-list-item class="activity-item px-0 py-2">
            <template v-slot:prepend>
              <v-avatar class="activity-icon mr-3" color="primary" size="32">
                <v-icon color="white" size="16">mdi-store</v-icon>
              </v-avatar>
            </template>
            <v-list-item-title class="activity-text text-body-2">
              「和食処・さくら」の情報が更新されました
            </v-list-item-title>
            <v-list-item-subtitle class="activity-time text-caption">
              1日前
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </v-card>
    </div>

    <!-- Quick Actions -->
    <v-card class="quick-actions pa-4" elevation="1">
      <h3 class="text-h6 font-weight-medium mb-4">クイックアクション</h3>
      <div class="actions-grid">
        <v-card 
          to="/shops/create" 
          class="action-card pa-3 d-flex align-center" 
          variant="outlined"
          hover
          ripple
        >
          <v-avatar class="action-icon mr-3" color="primary" size="40">
            <v-icon color="white" size="20">mdi-plus</v-icon>
          </v-avatar>
          <span class="action-text text-body-1 font-weight-medium">新規店舗登録</span>
        </v-card>
        
        <v-card 
          to="/shops" 
          class="action-card pa-3 d-flex align-center" 
          variant="outlined"
          hover
          ripple
        >
          <v-avatar class="action-icon mr-3" color="primary" size="40">
            <v-icon color="white" size="20">mdi-format-list-bulleted</v-icon>
          </v-avatar>
          <span class="action-text text-body-1 font-weight-medium">店舗一覧</span>
        </v-card>
        
        <v-card 
          to="/analytics" 
          class="action-card pa-3 d-flex align-center" 
          variant="outlined"
          hover
          ripple
        >
          <v-avatar class="action-icon mr-3" color="primary" size="40">
            <v-icon color="white" size="20">mdi-chart-line</v-icon>
          </v-avatar>
          <span class="action-text text-body-1 font-weight-medium">分析レポート</span>
        </v-card>
        
        <v-card 
          to="/settings" 
          class="action-card pa-3 d-flex align-center" 
          variant="outlined"
          hover
          ripple
        >
          <v-avatar class="action-icon mr-3" color="primary" size="40">
            <v-icon color="white" size="20">mdi-cog</v-icon>
          </v-avatar>
          <span class="action-text text-body-1 font-weight-medium">システム設定</span>
        </v-card>
      </div>
    </v-card>
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
/* Dashboard layout with consistent spacing */
.dashboard {
  display: flex;
  flex-direction: column;
}

/* Stats Grid with consistent spacing */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-icon {
  width: 3rem;
  height: 3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #ff6f00);
  border-radius: 0.75rem;
}

/* Dashboard Grid with consistent spacing */
.dashboard-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 1.5rem;
}

/* Chart styling with consistent spacing */
.chart-bar {
  background: linear-gradient(180deg, rgb(var(--v-theme-primary)), #ff6f00);
  width: 2rem;
  border-radius: 0.25rem 0.25rem 0 0;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.chart-bar:hover {
  opacity: 0.8;
  transform: scale(1.05);
}

/* Activity list styling */
.activity-item {
  transition: background-color 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 0.5rem;
}

.activity-item:hover {
  background-color: rgba(var(--v-theme-primary), 0.04);
}

/* Quick Actions Grid with consistent spacing */
.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
}

.action-card {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  text-decoration: none;
  color: inherit;
}

.action-card:hover {
  transform: translateY(-1px);
  border-color: rgb(var(--v-theme-primary)) !important;
}

/* Responsive design with consistent breakpoints */
@media (max-width: 960px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 600px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .actions-grid {
    grid-template-columns: 1fr;
  }
}
</style>