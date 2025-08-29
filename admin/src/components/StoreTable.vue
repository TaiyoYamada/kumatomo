<template>
  <v-card elevation="1">
    <v-card-title class="d-flex align-center justify-space-between">
      <div class="d-flex align-center">
        <v-icon class="me-2">mdi-store</v-icon>
        <span>店舗一覧</span>
        <v-chip
          v-if="stores.length > 0"
          class="ms-2"
          size="small"
          color="primary"
          variant="outlined"
        >
          {{ stores.length }}件
        </v-chip>
      </div>
      
      <v-btn
        color="primary"
        prepend-icon="mdi-plus"
        @click="$emit('create-store')"
      >
        新規登録
      </v-btn>
    </v-card-title>

    <v-divider />

    <!-- Data Table -->
    <v-data-table
      :headers="headers"
      :items="stores"
      :loading="loading"
      :sort-by="sortBy"
      :items-per-page="itemsPerPage"
      :items-per-page-options="itemsPerPageOptions"
      class="store-table"
      @update:sort-by="handleSortChange"
    >
      <!-- Loading slot -->
      <template #loading>
        <v-skeleton-loader type="table-row@10" />
      </template>

      <!-- Store name with image -->
      <template #item.name="{ item }">
        <div class="d-flex align-center py-2">
          <v-avatar
            :image="item.image_url"
            size="40"
            class="me-3"
          >
            <v-icon v-if="!item.image_url">mdi-store</v-icon>
          </v-avatar>
          <div>
            <div class="font-weight-medium">{{ item.name }}</div>
            <div v-if="item.description" class="text-caption text-medium-emphasis">
              {{ truncateText(item.description, 50) }}
            </div>
          </div>
        </div>
      </template>

      <!-- City -->
      <template #item.city="{ item }">
        <v-chip
          v-if="item.city"
          size="small"
          variant="outlined"
          color="info"
        >
          {{ item.city }}
        </v-chip>
        <span v-else class="text-medium-emphasis">-</span>
      </template>

      <!-- Genre -->
      <template #item.genre="{ item }">
        <v-chip
          v-if="item.genre"
          size="small"
          :color="getGenreColor(item.genre)"
          variant="tonal"
        >
          {{ item.genre }}
        </v-chip>
        <span v-else class="text-medium-emphasis">-</span>
      </template>

      <!-- Try Benefit -->
      <template #item.has_try_benefit="{ item }">
        <v-chip
          :color="item.has_try_benefit ? 'success' : 'default'"
          :variant="item.has_try_benefit ? 'tonal' : 'outlined'"
          size="small"
        >
          <v-icon
            :icon="item.has_try_benefit ? 'mdi-check-circle' : 'mdi-minus-circle'"
            size="small"
            class="me-1"
          />
          {{ item.has_try_benefit ? 'あり' : 'なし' }}
        </v-chip>
      </template>

      <!-- Registration Date -->
      <template #item.created_at="{ item }">
        <div class="text-body-2">
          {{ formatDate(item.created_at) }}
        </div>
      </template>

      <!-- Status -->
      <template #item.status="{ item }">
        <v-chip
          :color="item.status === 'active' ? 'success' : 'warning'"
          variant="tonal"
          size="small"
        >
          <v-icon
            :icon="item.status === 'active' ? 'mdi-check-circle' : 'mdi-pause-circle'"
            size="small"
            class="me-1"
          />
          {{ item.status === 'active' ? 'アクティブ' : '非アクティブ' }}
        </v-chip>
      </template>

      <!-- Actions -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center">
          <!-- Coupon Management -->
          <v-tooltip text="クーポン管理">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-ticket-percent"
                size="small"
                variant="text"
                color="info"
                @click="$emit('manage-coupons', item)"
              />
            </template>
          </v-tooltip>

          <!-- Edit -->
          <v-tooltip text="編集">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-pencil"
                size="small"
                variant="text"
                color="primary"
                @click="$emit('edit-store', item)"
              />
            </template>
          </v-tooltip>

          <!-- Delete -->
          <v-tooltip text="削除">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-delete"
                size="small"
                variant="text"
                color="error"
                @click="$emit('delete-store', item)"
              />
            </template>
          </v-tooltip>
        </div>
      </template>

      <!-- No data -->
      <template #no-data>
        <div class="text-center py-8">
          <v-icon size="64" color="grey-lighten-1">mdi-store-off</v-icon>
          <div class="text-h6 mt-4 text-medium-emphasis">
            店舗が見つかりませんでした
          </div>
          <div class="text-body-2 text-medium-emphasis mt-2">
            検索条件を変更するか、新しい店舗を登録してください
          </div>
          <v-btn
            class="mt-4"
            color="primary"
            prepend-icon="mdi-plus"
            @click="$emit('create-store')"
          >
            新規店舗登録
          </v-btn>
        </div>
      </template>
    </v-data-table>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Store } from '../types/store'

interface Props {
  stores: Store[]
  loading?: boolean
  sortBy?: Array<{ key: string; order: 'asc' | 'desc' }>
  itemsPerPage?: number
}

interface Emits {
  (e: 'edit-store', store: Store): void
  (e: 'delete-store', store: Store): void
  (e: 'manage-coupons', store: Store): void
  (e: 'create-store'): void
  (e: 'sort-change', sortBy: Array<{ key: string; order: 'asc' | 'desc' }>): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  sortBy: () => [{ key: 'created_at', order: 'desc' }],
  itemsPerPage: 10
})

const emit = defineEmits<Emits>()

// Table configuration
const headers = [
  {
    title: '店舗名',
    key: 'name',
    sortable: true,
    width: '250px'
  },
  {
    title: '市区町村',
    key: 'city',
    sortable: true,
    width: '120px'
  },
  {
    title: 'ジャンル',
    key: 'genre',
    sortable: true,
    width: '120px'
  },
  {
    title: 'Try特典',
    key: 'has_try_benefit',
    sortable: true,
    width: '100px'
  },
  {
    title: '登録日',
    key: 'created_at',
    sortable: true,
    width: '120px'
  },
  {
    title: 'ステータス',
    key: 'status',
    sortable: true,
    width: '120px'
  },
  {
    title: 'アクション',
    key: 'actions',
    sortable: false,
    width: '150px',
    align: 'center' as const
  }
]

const itemsPerPageOptions = [
  { value: 10, title: '10' },
  { value: 25, title: '25' },
  { value: 50, title: '50' },
  { value: 100, title: '100' }
]

// Methods
const handleSortChange = (sortBy: Array<{ key: string; order: 'asc' | 'desc' }>) => {
  emit('sort-change', sortBy)
}

const formatDate = (dateString: string): string => {
  if (!dateString) return '-'
  
  try {
    const date = new Date(dateString)
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    })
  } catch {
    return '-'
  }
}

const truncateText = (text: string, maxLength: number): string => {
  if (!text) return ''
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
}

const getGenreColor = (genre: string): string => {
  const colorMap: Record<string, string> = {
    'レストラン': 'orange',
    'カフェ': 'brown',
    '居酒屋': 'red',
    'ファストフード': 'green',
    'その他': 'grey'
  }
  return colorMap[genre] || 'primary'
}
</script>

<style scoped>
.store-table :deep(.v-data-table__td) {
  padding: 8px 16px;
}

.store-table :deep(.v-data-table__th) {
  font-weight: 600;
  color: rgb(var(--v-theme-on-surface));
}

/* Mobile responsiveness */
@media (max-width: 768px) {
  .store-table :deep(.v-data-table) {
    font-size: 0.875rem;
  }
  
  .store-table :deep(.v-data-table__td) {
    padding: 4px 8px;
  }
}

/* Hover effects */
.store-table :deep(.v-data-table__tr:hover) {
  background-color: rgb(var(--v-theme-surface-variant));
}

/* Loading skeleton customization */
.store-table :deep(.v-skeleton-loader__table-row) {
  height: 60px;
}
</style>