<template>
  <div class="shop-list">
    <!-- Page Header -->
    <v-card class="page-header pa-4 mb-6 d-flex justify-space-between align-center" elevation="1">
      <h2 class="page-title text-h4 font-weight-bold ma-0">お店管理</h2>
      <v-btn 
        to="/shops/create" 
        color="primary" 
        prepend-icon="mdi-plus"
        size="large"
      >
        新規お店登録
      </v-btn>
    </v-card>

    <!-- Search and Filter Section -->
    <v-card class="filters pa-4 mb-6" elevation="1">
      <v-row align="center" no-gutters>
        <v-col cols="12" md="8">
          <v-text-field
            v-model="searchQuery"
            placeholder="お店名で検索..."
            prepend-inner-icon="mdi-magnify"
            variant="outlined"
            density="comfortable"
            hide-details
            clearable
            @input="handleSearch"
          />
        </v-col>
        
        <v-col cols="12" md="4" class="pl-md-4">
          <v-select
            v-model="selectedGenre"
            :items="[
              { title: '全ジャンル', value: '' },
              { title: 'レストラン', value: 'レストラン' },
              { title: 'カフェ', value: 'カフェ' },
              { title: '居酒屋', value: '居酒屋' },
              { title: 'ファストフード', value: 'ファストフード' },
              { title: 'その他', value: 'その他' }
            ]"
            variant="outlined"
            density="comfortable"
            hide-details
            @update:model-value="handleFilter"
          />
        </v-col>
      </v-row>
    </v-card>

    <!-- Loading State -->
    <v-card v-if="loading" class="pa-8 text-center" elevation="1">
      <v-progress-circular indeterminate color="primary" class="mb-4" />
      <p class="text-body-1">読み込み中...</p>
    </v-card>

    <!-- Error State -->
    <v-alert v-if="error" type="error" class="mb-6">
      {{ error }}
    </v-alert>

    <!-- Shops Table -->
    <v-card v-if="!loading && !error" class="table-container" elevation="1">
      <v-data-table
        :headers="headers"
        :items="shops"
        :loading="loading"
        class="shops-table"
        item-key="id"
        no-data-text="お店が見つかりませんでした。"
        loading-text="読み込み中..."
      >
        <template v-slot:item.name="{ item }">
          <div class="shop-info d-flex align-center">
            <v-avatar
              v-if="item.image_url"
              :image="item.image_url"
              size="40"
              class="mr-3"
              rounded
            />
            <v-avatar
              v-else
              color="grey-lighten-2"
              size="40"
              class="mr-3"
              rounded
            >
              <v-icon color="grey">mdi-store</v-icon>
            </v-avatar>
            <span class="text-body-1 font-weight-medium">{{ item.name }}</span>
          </div>
        </template>

        <template v-slot:item.genre="{ item }">
          <v-chip
            v-if="item.genre"
            :text="item.genre"
            color="primary"
            variant="tonal"
            size="small"
          />
          <span v-else class="text-medium-emphasis">-</span>
        </template>

        <template v-slot:item.address="{ item }">
          <span class="text-body-2">{{ item.address || '-' }}</span>
        </template>

        <template v-slot:item.phone="{ item }">
          <span class="text-body-2">{{ item.phone || '-' }}</span>
        </template>

        <template v-slot:item.created_at="{ item }">
          <span class="text-body-2">{{ formatDate(item.created_at) }}</span>
        </template>

        <template v-slot:item.actions="{ item }">
          <div class="actions d-flex ga-2">
            <v-btn
              :to="`/shops/${item.id}/edit`"
              color="primary"
              variant="outlined"
              size="small"
              prepend-icon="mdi-pencil"
            >
              編集
            </v-btn>
            <v-btn
              @click="confirmDelete(item)"
              color="error"
              variant="outlined"
              size="small"
              prepend-icon="mdi-delete"
            >
              削除
            </v-btn>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Pagination -->
    <v-card 
      v-if="pagination && pagination.last_page > 1" 
      class="pagination pa-4 mt-6 d-flex justify-center align-center" 
      elevation="1"
    >
      <v-btn
        @click="changePage(pagination.current_page - 1)"
        :disabled="pagination.current_page <= 1"
        variant="outlined"
        prepend-icon="mdi-chevron-left"
        class="mr-4"
      >
        前へ
      </v-btn>
      
      <span class="page-info text-body-1 mx-4">
        {{ pagination.current_page }} / {{ pagination.last_page }}
      </span>
      
      <v-btn
        @click="changePage(pagination.current_page + 1)"
        :disabled="pagination.current_page >= pagination.last_page"
        variant="outlined"
        append-icon="mdi-chevron-right"
        class="ml-4"
      >
        次へ
      </v-btn>
    </v-card>

    <!-- Delete Confirmation Dialog -->
    <v-dialog v-model="showDeleteModal" max-width="400">
      <v-card class="pa-4">
        <v-card-title class="text-h6 font-weight-bold">
          削除確認
        </v-card-title>
        
        <v-card-text class="py-4">
          <p class="text-body-1 mb-2">「{{ shopToDelete?.name }}」を削除しますか？</p>
          <p class="text-body-2 text-error">この操作は取り消せません。</p>
        </v-card-text>
        
        <v-card-actions class="pt-0">
          <v-spacer />
          <v-btn
            @click="closeDeleteModal"
            variant="outlined"
            color="grey"
          >
            キャンセル
          </v-btn>
          <v-btn
            @click="deleteShop"
            :loading="deleting"
            color="error"
            variant="flat"
          >
            削除
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { shopService } from '../services/shopService.js'
import { handleApiError, handleApiErrorWithRetry, createErrorNotification, isNetworkOnline } from '../utils/errorHandler.js'

// Reactive data
const shops = ref([])
const loading = ref(false)
const error = ref('')
const notifications = ref([])
const searchQuery = ref('')
const selectedGenre = ref('')
const pagination = ref(null)
const currentPage = ref(1)

// Table headers
const headers = ref([
  { title: 'ID', key: 'id', sortable: true, width: '80px' },
  { title: 'お店名', key: 'name', sortable: true },
  { title: 'ジャンル', key: 'genre', sortable: true, width: '120px' },
  { title: '住所', key: 'address', sortable: false },
  { title: '電話番号', key: 'phone', sortable: false, width: '140px' },
  { title: '登録日', key: 'created_at', sortable: true, width: '120px' },
  { title: '操作', key: 'actions', sortable: false, width: '180px' }
])

// Delete modal
const showDeleteModal = ref(false)
const shopToDelete = ref(null)
const deleting = ref(false)

// Methods
const fetchShops = async () => {
  if (!isNetworkOnline()) {
    error.value = 'インターネット接続を確認してください'
    return
  }

  try {
    loading.value = true
    error.value = ''
    
    const params = {
      page: currentPage.value,
      per_page: 10
    }
    
    if (searchQuery.value) {
      params.search = searchQuery.value
    }
    
    if (selectedGenre.value) {
      params.genre = selectedGenre.value
    }

    const response = await handleApiErrorWithRetry(
      null,
      () => shopService.getShops(params),
      3
    )
    
    shops.value = response.data
    pagination.value = response.meta || response.pagination
  } catch (err) {
    error.value = handleApiError(err, 'お店の取得に失敗しました')
    
    // Add error notification
    const notification = createErrorNotification(err, 'お店一覧の取得')
    notifications.value.push(notification)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
  fetchShops()
}

const handleFilter = () => {
  currentPage.value = 1
  fetchShops()
}

const changePage = (page) => {
  currentPage.value = page
  fetchShops()
}

const confirmDelete = (shop) => {
  shopToDelete.value = shop
  showDeleteModal.value = true
}

const closeDeleteModal = () => {
  showDeleteModal.value = false
  shopToDelete.value = null
  deleting.value = false
}

const deleteShop = async () => {
  if (!shopToDelete.value) return
  
  try {
    deleting.value = true
    await shopService.deleteShop(shopToDelete.value.id)
    
    // Remove from local list
    shops.value = shops.value.filter(shop => shop.id !== shopToDelete.value.id)
    
    closeDeleteModal()
  } catch (err) {
    error.value = handleApiError(err, 'お店の削除に失敗しました')
  } finally {
    deleting.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('ja-JP')
}

// Lifecycle
onMounted(() => {
  fetchShops()
})
</script>

<style scoped>
/* Shop list layout with consistent spacing */
.shop-list {
  height: 100%;
}

/* Shop info styling with consistent spacing */
.shop-info {
  display: flex;
  align-items: center;
}

/* Actions styling with consistent spacing */
.actions {
  display: flex;
  gap: 0.5rem;
}

/* Responsive design */
@media (max-width: 960px) {
  .filters :deep(.v-row) {
    flex-direction: column;
  }
  
  .filters :deep(.pl-md-4) {
    padding-left: 0 !important;
    margin-top: 1rem;
  }
}

/* Data table customization */
.shops-table :deep(.v-data-table__wrapper) {
  border-radius: 0;
}

.shops-table :deep(.v-data-table-header) {
  background-color: rgb(var(--v-theme-surface));
}

.shops-table :deep(.v-data-table-header th) {
  font-weight: 600;
  color: rgb(var(--v-theme-on-surface));
  font-size: 0.875rem;
}

.shops-table :deep(.v-data-table__tr:hover) {
  background-color: rgba(var(--v-theme-primary), 0.04);
}

/* Pagination styling */
.pagination {
  background-color: rgb(var(--v-theme-surface));
}
</style>