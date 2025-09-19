<template>
  <v-container class="shop-form pa-6">
    <!-- Page Header -->
    <v-card class="page-header pa-4 mb-6 d-flex justify-space-between align-center" elevation="1">
      <h2 class="page-title text-h4 font-weight-bold ma-0">
        {{ isEdit ? 'お店編集' : '新規お店登録' }}
      </h2>
      <v-btn to="/shops" color="grey" variant="outlined" prepend-icon="mdi-arrow-left">
        一覧に戻る
      </v-btn>
    </v-card>

    <!-- Loading State -->
    <v-card v-if="loading" class="pa-8 text-center" elevation="1">
      <v-progress-circular indeterminate color="primary" class="mb-4" />
      <p class="text-body-1">読み込み中...</p>
    </v-card>

    <!-- Error State -->
    <v-alert v-if="error" type="error" class="mb-6" closable @click:close="error = ''">
      {{ error }}
    </v-alert>

    <!-- Form -->
    <v-card v-if="!loading" class="pa-6" elevation="1">
      <v-form ref="formRef" v-model="isFormValid" @submit.prevent="handleSubmit">
        <v-row>
          <!-- Shop Name -->
          <v-col cols="12" md="6">
            <v-text-field v-model="form.name" label="お店名" placeholder="お店名を入力してください" variant="outlined"
              :rules="nameRules" :error-messages="getFieldError('name')" required counter="100" />
          </v-col>

          <!-- Genre -->
          <v-col cols="12" md="6">
            <v-select v-model="form.genre" :items="genreOptions" label="ジャンル" placeholder="ジャンルを選択してください"
              variant="outlined" :rules="genreRules" :error-messages="getFieldError('genre')" clearable />
          </v-col>

          <!-- Description -->
          <v-col cols="12">
            <v-textarea v-model="form.description" label="お店の説明" placeholder="お店の説明を入力してください" variant="outlined"
              rows="4" :rules="descriptionRules" :error-messages="getFieldError('description')" counter="1000" />
          </v-col>

          <!-- Address -->
          <v-col cols="12">
            <v-text-field v-model="form.address" label="住所" placeholder="住所を入力してください" variant="outlined"
              :rules="addressRules" :error-messages="getFieldError('address')" counter="255" />
          </v-col>

          <!-- Phone -->
          <v-col cols="12" md="6">
            <v-text-field v-model="form.phone" label="電話番号" placeholder="電話番号を入力してください" variant="outlined"
              :rules="phoneRules" :error-messages="getFieldError('phone')" counter="20" />
          </v-col>

          <!-- Business Hours -->
          <v-col cols="12" md="6">
            <v-text-field v-model="form.business_hours" label="営業時間" placeholder="例: 10:00-22:00" variant="outlined"
              :rules="businessHoursRules" :error-messages="getFieldError('business_hours')" counter="100" />
          </v-col>

          <!-- Location -->
          <v-col cols="12" md="6">
            <v-text-field v-model="form.latitude" label="緯度" placeholder="例: 35.6762" variant="outlined" type="number"
              step="any" :rules="latitudeRules" :error-messages="getFieldError('latitude')" />
          </v-col>

          <v-col cols="12" md="6">
            <v-text-field v-model="form.longitude" label="経度" placeholder="例: 139.6503" variant="outlined" type="number"
              step="any" :rules="longitudeRules" :error-messages="getFieldError('longitude')" />
          </v-col>

          <!-- Try特典 Toggle -->
          <v-col cols="12" md="6">
            <v-switch v-model="form.has_try_benefit" label="Try特典あり" color="primary"
              :error-messages="getFieldError('has_try_benefit')" hide-details="auto" />
            <div class="text-caption text-medium-emphasis mt-1">
              お客様がTry特典を利用できる場合はオンにしてください
            </div>
          </v-col>

          <!-- Stamp Count -->
          <v-col cols="12" md="6">
            <v-text-field v-model.number="form.stamp_count" label="スタンプ数" placeholder="0" variant="outlined"
              type="number" min="0" :rules="stampCountRules" :error-messages="getFieldError('stamp_count')" />
          </v-col>

          <!-- Image URL -->
          <v-col cols="12">
            <v-text-field v-model="form.image_url" label="画像URL" placeholder="店舗画像のURLを入力してください" variant="outlined"
              :rules="imageUrlRules" :error-messages="getFieldError('image_url')" />

            <!-- Image Preview -->
            <div v-if="form.image_url" class="mt-3">
              <v-img :src="form.image_url" max-height="200" max-width="300" class="rounded" @error="handleImageError">
                <template #placeholder>
                  <div class="d-flex align-center justify-center fill-height">
                    <v-progress-circular indeterminate />
                  </div>
                </template>
              </v-img>
            </div>
          </v-col>

          <!-- Approval Status (for editing) -->
          <v-col v-if="isEdit" cols="12" md="6">
            <v-switch v-model="form.is_approved" label="承認済み" color="success"
              :error-messages="getFieldError('is_approved')" hide-details="auto" />
            <div class="text-caption text-medium-emphasis mt-1">
              お店を公開する場合はオンにしてください
            </div>
          </v-col>
        </v-row>

        <!-- Submit Buttons -->
        <v-card-actions class="px-0 pt-6">
          <v-spacer />
          <v-btn to="/shops" variant="outlined" color="grey" :disabled="submitting">
            キャンセル
          </v-btn>
          <v-btn type="submit" color="primary" :loading="submitting" :disabled="!isFormValid">
            {{ isEdit ? '更新' : '登録' }}
          </v-btn>
        </v-card-actions>
      </v-form>
    </v-card>
  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { shopService } from '@/services/shopService'
import { ShopGenre, getGenreOptions, type Shop } from '@/types/shop'
import type { ShopFormData } from '@/types/api'

interface Props {
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  id: undefined
})

const router = useRouter()
const route = useRoute()

// Form state
const formRef = ref()
const isFormValid = ref(false)
const loading = ref(false)
const submitting = ref(false)
const error = ref('')
const validationErrors = ref<Record<string, string[]>>({})

// Form data with proper typing
const form = ref<ShopFormData & { is_approved?: boolean }>({
  name: '',
  description: '',
  address: '',
  phone: '',
  business_hours: '',
  genre: undefined,
  latitude: undefined,
  longitude: undefined,
  image_url: '',
  has_try_benefit: false,
  stamp_count: 0,
  is_approved: true
})

// Computed
const isEdit = computed(() => !!props.id)

// Genre options from enum
const genreOptions = computed(() => getGenreOptions())

// Validation rules
const nameRules = [
  (v: string) => !!v || 'お店名は必須です',
  (v: string) => (v && v.length >= 2) || 'お店名は2文字以上で入力してください',
  (v: string) => (v && v.length <= 100) || 'お店名は100文字以内で入力してください'
]

const genreRules = [
  (v: ShopGenre | undefined) => !!v || 'ジャンルは必須です'
]

const descriptionRules = [
  (v: string) => !v || v.length <= 1000 || '説明は1000文字以内で入力してください'
]

const addressRules = [
  (v: string) => !v || v.length <= 255 || '住所は255文字以内で入力してください'
]

const phoneRules = [
  (v: string) => !v || /^[\d\-\(\)\+\s]+$/.test(v) || '正しい電話番号形式で入力してください',
  (v: string) => !v || v.length <= 20 || '電話番号は20文字以内で入力してください'
]

const businessHoursRules = [
  (v: string) => !v || v.length <= 100 || '営業時間は100文字以内で入力してください'
]

const latitudeRules = [
  (v: number | undefined) => v === undefined || (v >= -90 && v <= 90) || '緯度は-90から90の間で入力してください'
]

const longitudeRules = [
  (v: number | undefined) => v === undefined || (v >= -180 && v <= 180) || '経度は-180から180の間で入力してください'
]

const stampCountRules = [
  (v: number) => v >= 0 || 'スタンプ数は0以上で入力してください',
  (v: number) => Number.isInteger(v) || 'スタンプ数は整数で入力してください'
]

const imageUrlRules = [
  (v: string) => !v || isValidUrl(v) || '正しいURL形式で入力してください'
]

// Helper functions
const isValidUrl = (url: string): boolean => {
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}

const getFieldError = (field: string): string[] => {
  return validationErrors.value[field] || []
}

const handleImageError = () => {
  console.warn('Failed to load image:', form.value.image_url)
}

// Methods
const fetchShop = async (): Promise<void> => {
  if (!props.id) return

  try {
    loading.value = true
    error.value = ''
    validationErrors.value = {}

    const response = await shopService.getShop(Number(props.id))

    if (response.data) {
      // Populate form with existing data
      form.value = {
        name: response.data.name || '',
        description: response.data.description || '',
        address: response.data.address || '',
        phone: response.data.phone || '',
        business_hours: response.data.business_hours || '',
        genre: response.data.genre || undefined,
        latitude: response.data.latitude || undefined,
        longitude: response.data.longitude || undefined,
        image_url: response.data.image_url || '',
        has_try_benefit: response.data.has_try_benefit || false,
        stamp_count: response.data.stamp_count || 0,
        is_approved: response.data.is_approved || false
      }
    }
  } catch (err: any) {
    error.value = err.message || 'お店の取得に失敗しました'
  } finally {
    loading.value = false
  }
}

const resetForm = (): void => {
  form.value = {
    name: '',
    description: '',
    address: '',
    phone: '',
    business_hours: '',
    genre: undefined,
    latitude: undefined,
    longitude: undefined,
    image_url: '',
    has_try_benefit: false,
    stamp_count: 0,
    is_approved: true
  }
  error.value = ''
  validationErrors.value = {}

  nextTick(() => {
    formRef.value?.resetValidation()
  })
}

const handleSubmit = async (): Promise<void> => {
  if (!isFormValid.value) return

  try {
    submitting.value = true
    error.value = ''
    validationErrors.value = {}

    // Prepare data for submission
    const submitData: ShopFormData = {
      name: form.value.name,
      description: form.value.description || undefined,
      address: form.value.address || undefined,
      phone: form.value.phone || undefined,
      business_hours: form.value.business_hours || undefined,
      genre: form.value.genre,
      latitude: form.value.latitude,
      longitude: form.value.longitude,
      image_url: form.value.image_url || undefined,
      has_try_benefit: form.value.has_try_benefit,
      stamp_count: form.value.stamp_count
    }

    let result: Shop | null = null

    if (isEdit.value && props.id) {
      result = await shopService.updateShop(Number(props.id), submitData)
    } else {
      result = await shopService.createShop(submitData)
    }

    if (result) {
      // Redirect to shop list
      router.push('/shops')
    }
  } catch (err: any) {
    if (err.response?.status === 422) {
      // Validation errors from server
      validationErrors.value = err.response.data.errors || {}
    } else {
      error.value = err.message || (isEdit.value ? 'お店の更新に失敗しました' : 'お店の登録に失敗しました')
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
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  background-color: rgb(var(--v-theme-surface));
}

.v-form {
  width: 100%;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .v-container {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch !important;
  }
}
</style>