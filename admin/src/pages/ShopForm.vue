<template>
  <div class="shop-form">
    <div class="page-header">
      <h2 class="page-title">
        {{ isEdit ? 'お店編集' : '新規お店登録' }}
      </h2>
      <router-link to="/shops" class="btn btn-secondary">
        一覧に戻る
      </router-link>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      読み込み中...
    </div>

    <!-- Error State -->
    <div v-if="error" class="error">
      {{ error }}
    </div>

    <!-- Form -->
    <form v-if="!loading" @submit.prevent="handleSubmit" class="form">
      <!-- Shop Name -->
      <div class="form-group">
        <label for="name" class="form-label required">お店名</label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          class="form-input"
          :class="{ 'error': errors.name }"
          placeholder="お店名を入力してください"
          maxlength="100"
          required
        />
        <div v-if="errors.name" class="field-error">{{ errors.name[0] }}</div>
      </div>

      <!-- Description -->
      <div class="form-group">
        <label for="description" class="form-label">説明</label>
        <textarea
          id="description"
          v-model="form.description"
          class="form-textarea"
          :class="{ 'error': errors.description }"
          placeholder="お店の説明を入力してください"
          rows="4"
        ></textarea>
        <div v-if="errors.description" class="field-error">{{ errors.description[0] }}</div>
      </div>

      <!-- Address -->
      <div class="form-group">
        <label for="address" class="form-label">住所</label>
        <input
          id="address"
          v-model="form.address"
          type="text"
          class="form-input"
          :class="{ 'error': errors.address }"
          placeholder="住所を入力してください"
          maxlength="255"
        />
        <div v-if="errors.address" class="field-error">{{ errors.address[0] }}</div>
      </div>

      <!-- Phone -->
      <div class="form-group">
        <label for="phone" class="form-label">電話番号</label>
        <input
          id="phone"
          v-model="form.phone"
          type="tel"
          class="form-input"
          :class="{ 'error': errors.phone }"
          placeholder="電話番号を入力してください"
          maxlength="20"
        />
        <div v-if="errors.phone" class="field-error">{{ errors.phone[0] }}</div>
      </div>

      <!-- Business Hours -->
      <div class="form-group">
        <label for="business_hours" class="form-label">営業時間</label>
        <textarea
          id="business_hours"
          v-model="form.business_hours"
          class="form-textarea"
          :class="{ 'error': errors.business_hours }"
          placeholder="営業時間を入力してください（例：10:00-22:00）"
          rows="3"
        ></textarea>
        <div v-if="errors.business_hours" class="field-error">{{ errors.business_hours[0] }}</div>
      </div>

      <!-- Genre -->
      <div class="form-group">
        <label for="genre" class="form-label">ジャンル</label>
        <select
          id="genre"
          v-model="form.genre"
          class="form-select"
          :class="{ 'error': errors.genre }"
        >
          <option value="">ジャンルを選択してください</option>
          <option value="レストラン">レストラン</option>
          <option value="カフェ">カフェ</option>
          <option value="居酒屋">居酒屋</option>
          <option value="ファストフード">ファストフード</option>
          <option value="その他">その他</option>
        </select>
        <div v-if="errors.genre" class="field-error">{{ errors.genre[0] }}</div>
      </div>

      <!-- Location -->
      <div class="form-row">
        <div class="form-group">
          <label for="latitude" class="form-label">緯度</label>
          <input
            id="latitude"
            v-model.number="form.latitude"
            type="number"
            step="0.00000001"
            class="form-input"
            :class="{ 'error': errors.latitude }"
            placeholder="35.6762"
          />
          <div v-if="errors.latitude" class="field-error">{{ errors.latitude[0] }}</div>
        </div>

        <div class="form-group">
          <label for="longitude" class="form-label">経度</label>
          <input
            id="longitude"
            v-model.number="form.longitude"
            type="number"
            step="0.00000001"
            class="form-input"
            :class="{ 'error': errors.longitude }"
            placeholder="139.6503"
          />
          <div v-if="errors.longitude" class="field-error">{{ errors.longitude[0] }}</div>
        </div>
      </div>

      <!-- Image Upload -->
      <div class="form-group">
        <label for="image" class="form-label">お店の画像</label>
        
        <!-- Current Image -->
        <div v-if="form.image_url && !newImagePreview" class="current-image">
          <img :src="form.image_url" :alt="form.name" class="image-preview" />
          <button type="button" @click="removeCurrentImage" class="btn btn-sm btn-danger">
            画像を削除
          </button>
        </div>

        <!-- New Image Preview -->
        <div v-if="newImagePreview" class="image-preview-container">
          <img :src="newImagePreview" alt="プレビュー" class="image-preview" />
          <button type="button" @click="removeNewImage" class="btn btn-sm btn-danger">
            画像を削除
          </button>
        </div>

        <!-- File Input -->
        <input
          id="image"
          ref="imageInput"
          type="file"
          accept="image/*"
          @change="handleImageChange"
          class="form-file"
          :class="{ 'error': errors.image }"
        />
        <div class="file-help">
          JPEGまたはPNG形式の画像をアップロードしてください（最大5MB）
        </div>
        <div v-if="errors.image" class="field-error">{{ errors.image[0] }}</div>
        <div v-if="imageUploading" class="upload-progress">
          画像をアップロード中...
        </div>
      </div>

      <!-- Submit Buttons -->
      <div class="form-actions">
        <router-link to="/shops" class="btn btn-secondary">
          キャンセル
        </router-link>
        <button type="submit" class="btn btn-primary" :disabled="submitting">
          {{ submitting ? '保存中...' : (isEdit ? '更新' : '登録') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { shopService } from '../services/shopService.js'
import { handleApiError } from '../utils/errorHandler.js'

const router = useRouter()
const route = useRoute()

// Props
const props = defineProps({
  id: String
})

// Reactive data
const loading = ref(false)
const submitting = ref(false)
const imageUploading = ref(false)
const error = ref('')
const errors = ref({})
const newImageFile = ref(null)
const newImagePreview = ref('')
const imageInput = ref(null)

const form = ref({
  name: '',
  description: '',
  address: '',
  phone: '',
  business_hours: '',
  genre: '',
  latitude: null,
  longitude: null,
  image_url: ''
})

// Computed
const isEdit = computed(() => !!props.id)

// Methods
const fetchShop = async () => {
  if (!props.id) return
  
  try {
    loading.value = true
    error.value = ''
    
    const response = await shopService.getShop(props.id)
    
    // Populate form with existing data
    Object.keys(form.value).forEach(key => {
      if (response.data[key] !== undefined) {
        form.value[key] = response.data[key]
      }
    })
  } catch (err) {
    error.value = handleApiError(err, 'お店の取得に失敗しました')
  } finally {
    loading.value = false
  }
}

const handleImageChange = (event) => {
  const file = event.target.files[0]
  if (!file) return

  // Validate file type
  if (!file.type.startsWith('image/')) {
    errors.value.image = ['画像ファイルを選択してください']
    return
  }

  // Validate file size (5MB)
  if (file.size > 5 * 1024 * 1024) {
    errors.value.image = ['ファイルサイズは5MB以下にしてください']
    return
  }

  newImageFile.value = file
  errors.value.image = null

  // Create preview
  const reader = new FileReader()
  reader.onload = (e) => {
    newImagePreview.value = e.target.result
  }
  reader.readAsDataURL(file)
}

const removeCurrentImage = () => {
  form.value.image_url = ''
}

const removeNewImage = () => {
  newImageFile.value = null
  newImagePreview.value = ''
  if (imageInput.value) {
    imageInput.value.value = ''
  }
}

const uploadImage = async () => {
  if (!newImageFile.value) return null

  try {
    imageUploading.value = true
    const response = await shopService.uploadImage(newImageFile.value)
    return response.image_url
  } catch (err) {
    throw new Error(handleApiError(err, '画像のアップロードに失敗しました'))
  } finally {
    imageUploading.value = false
  }
}

const validateForm = () => {
  errors.value = {}
  
  if (!form.value.name.trim()) {
    errors.value.name = ['お店名は必須です']
  }
  
  if (form.value.name.length > 100) {
    errors.value.name = ['お店名は100文字以内で入力してください']
  }
  
  if (form.value.address && form.value.address.length > 255) {
    errors.value.address = ['住所は255文字以内で入力してください']
  }
  
  if (form.value.phone && form.value.phone.length > 20) {
    errors.value.phone = ['電話番号は20文字以内で入力してください']
  }
  
  if (form.value.latitude && (form.value.latitude < -90 || form.value.latitude > 90)) {
    errors.value.latitude = ['緯度は-90から90の間で入力してください']
  }
  
  if (form.value.longitude && (form.value.longitude < -180 || form.value.longitude > 180)) {
    errors.value.longitude = ['経度は-180から180の間で入力してください']
  }
  
  return Object.keys(errors.value).length === 0
}

const handleSubmit = async () => {
  if (!validateForm()) return
  
  try {
    submitting.value = true
    error.value = ''
    
    // Upload new image if selected
    if (newImageFile.value) {
      const imageUrl = await uploadImage()
      form.value.image_url = imageUrl
    }
    
    // Prepare data for submission
    const submitData = { ...form.value }
    
    // Convert empty strings to null for optional fields
    Object.keys(submitData).forEach(key => {
      if (submitData[key] === '') {
        submitData[key] = null
      }
    })
    
    if (isEdit.value) {
      await shopService.updateShop(props.id, submitData)
    } else {
      await shopService.createShop(submitData)
    }
    
    // Redirect to shop list
    router.push('/shops')
  } catch (err) {
    if (err.response?.status === 422) {
      // Validation errors from server
      errors.value = err.response.data.errors || {}
    } else {
      error.value = handleApiError(err, isEdit.value ? 'お店の更新に失敗しました' : 'お店の登録に失敗しました')
    }
  } finally {
    submitting.value = false
  }
}

// Lifecycle
onMounted(() => {
  if (isEdit.value) {
    fetchShop()
  }
})
</script>

<style scoped>
.shop-form {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #333;
  margin: 0;
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

.form {
  max-width: 600px;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-row {
  display: flex;
  gap: 1rem;
}

.form-row .form-group {
  flex: 1;
}

.form-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #333;
}

.form-label.required::after {
  content: ' *';
  color: #dc3545;
}

.form-input,
.form-textarea,
.form-select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  transition: border-color 0.2s;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-input.error,
.form-textarea.error,
.form-select.error,
.form-file.error {
  border-color: #dc3545;
}

.form-file {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.file-help {
  font-size: 0.8rem;
  color: #666;
  margin-top: 0.25rem;
}

.field-error {
  color: #dc3545;
  font-size: 0.8rem;
  margin-top: 0.25rem;
}

.current-image,
.image-preview-container {
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.image-preview {
  width: 100px;
  height: 100px;
  object-fit: cover;
  border-radius: 4px;
  border: 1px solid #ddd;
}

.upload-progress {
  color: #007bff;
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #eee;
}

/* Button Styles */
.btn {
  padding: 0.75rem 1.5rem;
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

@media (max-width: 768px) {
  .form-row {
    flex-direction: column;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .current-image,
  .image-preview-container {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>