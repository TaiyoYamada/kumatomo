<template>
  <div class="shop-list">
    <div class="page-header">
      <h2 class="page-title">お店管理</h2>
      <router-link to="/shops/create" class="btn btn-primary">
        新規お店登録
      </router-link>
    </div>

    <!-- Search and Filter Section -->
    <div class="filters">
      <div class="search-box">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="お店名で検索..."
          class="search-input"
          @input="handleSearch"
        />
      </div>
      
      <div class="filter-box">
        <select v-model="selectedGenre" @change="handleFilter" class="filter-select">
          <option value="">全ジャンル</option>
          <option value="レストラン">レストラン</option>
          <option value="カフェ">カフェ</option>
          <option value="居酒屋">居酒屋</option>
          <option value="ファストフード">ファストフード</option>
          <option value="その他">その他</option>
        </select>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      読み込み中...
    </div>

    <!-- Error State -->
    <div v-if="error" class="error">
      {{ error }}
    </div>

    <!-- Shops Table -->
    <div v-if="!loading && !error" class="table-container">
      <table class="shops-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>お店名</th>
            <th>ジャンル</th>
            <th>住所</th>
            <th>電話番号</th>
            <th>登録日</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="shop in shops" :key="shop.id">
            <td>{{ shop.id }}</td>
            <td class="shop-name">
              <div class="shop-info">
                <img 
                  v-if="shop.image_url" 
                  :src="shop.image_url" 
                  :alt="shop.name"
                  class="shop-thumbnail"
                />
                <span>{{ shop.name }}</span>
              </div>
            </td>
            <td>{{ shop.genre || '-' }}</td>
            <td>{{ shop.address || '-' }}</td>
            <td>{{ shop.phone || '-' }}</td>
            <td>{{ formatDate(shop.created_at) }}</td>
            <td class="actions">
              <router-link 
                :to="`/shops/${shop.id}/edit`" 
                class="btn btn-sm btn-secondary"
              >
                編集
              </router-link>
              <button 
                @click="confirmDelete(shop)" 
                class="btn btn-sm btn-danger"
              >
                削除
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Empty State -->
      <div v-if="shops.length === 0" class="empty-state">
        <p>お店が見つかりませんでした。</p>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="pagination && pagination.last_page > 1" class="pagination">
      <button 
        @click="changePage(pagination.current_page - 1)"
        :disabled="pagination.current_page <= 1"
        class="btn btn-sm"
      >
        前へ
      </button>
      
      <span class="page-info">
        {{ pagination.current_page }} / {{ pagination.last_page }}
      </span>
      
      <button 
        @click="changePage(pagination.current_page + 1)"
        :disabled="pagination.current_page >= pagination.last_page"
        class="btn btn-sm"
      >
        次へ
      </button>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click="closeDeleteModal">
      <div class="modal" @click.stop>
        <h3>削除確認</h3>
        <p>「{{ shopToDelete?.name }}」を削除しますか？</p>
        <p class="warning">この操作は取り消せません。</p>
        <div class="modal-actions">
          <button @click="closeDeleteModal" class="btn btn-secondary">
            キャンセル
          </button>
          <button @click="deleteShop" class="btn btn-danger" :disabled="deleting">
            {{ deleting ? '削除中...' : '削除' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { shopService } from '../services/shopService.js'
import { handleApiError } from '../utils/errorHandler.js'

// Reactive data
const shops = ref([])
const loading = ref(false)
const error = ref('')
const searchQuery = ref('')
const selectedGenre = ref('')
const pagination = ref(null)
const currentPage = ref(1)

// Delete modal
const showDeleteModal = ref(false)
const shopToDelete = ref(null)
const deleting = ref(false)

// Methods
const fetchShops = async () => {
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
    
    const response = await shopService.getShops(params)
    shops.value = response.data
    pagination.value = response.meta || response.pagination
  } catch (err) {
    error.value = handleApiError(err, 'お店の取得に失敗しました')
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
.shop-list {
  height: 100%;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.filters {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 1rem;
  margin-bottom: 2rem;
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.search-box,
.filter-box {
  flex: 1;
  min-width: 200px;
}

.search-input,
.filter-select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.search-input:focus,
.filter-select:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.loading,
.error {
  text-align: center;
  padding: 2rem;
  font-size: 1rem;
}

.error {
  color: #dc3545;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}

.table-container {
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.shops-table {
  width: 100%;
  border-collapse: collapse;
}

.shops-table th,
.shops-table td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.shops-table th {
  background-color: #f8fafc;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.shops-table tbody tr {
  transition: background-color 0.2s;
}

.shops-table tbody tr:hover {
  background-color: #f8fafc;
}

.shop-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.shop-thumbnail {
  width: 40px;
  height: 40px;
  object-fit: cover;
  border-radius: 4px;
}

.actions {
  display: flex;
  gap: 0.5rem;
}

.empty-state {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
}

.page-info {
  font-size: 0.9rem;
  color: #666;
}

/* Button Styles */
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  text-decoration: none;
  display: inline-block;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover {
  background-color: #0056b3;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background-color: #545b62;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover {
  background-color: #c82333;
}

.btn-sm {
  padding: 0.25rem 0.5rem;
  font-size: 0.8rem;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  max-width: 400px;
  width: 90%;
}

.modal h3 {
  margin-top: 0;
  margin-bottom: 1rem;
  color: #333;
}

.modal p {
  margin-bottom: 1rem;
  color: #666;
}

.warning {
  color: #dc3545;
  font-size: 0.9rem;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
}
</style>