<template>
  <v-dialog
    :model-value="modelValue"
    max-width="800px"
    persistent
    @update:model-value="$emit('update:modelValue', $event)"
  >
    <v-card>
      <v-card-title class="d-flex align-center justify-space-between">
        <div class="d-flex align-center">
          <v-icon class="me-2">{{ isEditing ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
          <span>{{ isEditing ? '店舗情報編集' : '新規店舗登録' }}</span>
        </div>
        <v-btn
          icon="mdi-close"
          variant="text"
          @click="handleCancel"
        />
      </v-card-title>

      <v-divider />

      <v-card-text class="pa-6">
        <v-form ref="formRef" v-model="isFormValid" @submit.prevent="handleSubmit">
          <v-row>
            <!-- Store Name -->
            <v-col cols="12" md="6">
              <v-text-field
                v-model="formData.name"
                label="店舗名"
                placeholder="店舗名を入力してください"
                variant="outlined"
                :rules="nameRules"
                :error-messages="getFieldError('name')"
                required
              />
            </v-col>

            <!-- Genre -->
            <v-col cols="12" md="6">
              <v-select
                v-model="formData.genre"
                :items="genreOptions"
                label="ジャンル"
                placeholder="ジャンルを選択してください"
                variant="outlined"
                :rules="genreRules"
                :error-messages="getFieldError('genre')"
                clearable
              />
            </v-col>

            <!-- Address -->
            <v-col cols="12">
              <v-text-field
                v-model="formData.address"
                label="住所"
                placeholder="住所を入力してください"
                variant="outlined"
                :rules="addressRules"
                :error-messages="getFieldError('address')"
              />
            </v-col>

            <!-- Phone -->
            <v-col cols="12" md="6">
              <v-text-field
                v-model="formData.phone"
                label="電話番号"
                placeholder="電話番号を入力してください"
                variant="outlined"
                :rules="phoneRules"
                :error-messages="getFieldError('phone')"
              />
            </v-col>

            <!-- Business Hours -->
            <v-col cols="12" md="6">
              <v-text-field
                v-model="formData.business_hours"
                label="営業時間"
                placeholder="例: 10:00-22:00"
                variant="outlined"
                :rules="businessHoursRules"
                :error-messages="getFieldError('business_hours')"
              />
            </v-col>

            <!-- Description -->
            <v-col cols="12">
              <v-textarea
                v-model="formData.description"
                label="店舗説明"
                placeholder="店舗の説明を入力してください"
                variant="outlined"
                rows="3"
                :rules="descriptionRules"
                :error-messages="getFieldError('description')"
              />
            </v-col>

            <!-- Location -->
            <v-col cols="12" md="6">
              <v-text-field
                v-model="formData.latitude"
                label="緯度"
                placeholder="例: 35.6762"
                variant="outlined"
                type="number"
                step="any"
                :rules="latitudeRules"
                :error-messages="getFieldError('latitude')"
              />
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="formData.longitude"
                label="経度"
                placeholder="例: 139.6503"
                variant="outlined"
                type="number"
                step="any"
                :rules="longitudeRules"
                :error-messages="getFieldError('longitude')"
              />
            </v-col>

            <!-- Image URL -->
            <v-col cols="12">
              <v-text-field
                v-model="formData.image_url"
                label="画像URL"
                placeholder="店舗画像のURLを入力してください"
                variant="outlined"
                :rules="imageUrlRules"
                :error-messages="getFieldError('image_url')"
              />
              
              <!-- Image Preview -->
              <div v-if="formData.image_url" class="mt-3">
                <v-img
                  :src="formData.image_url"
                  max-height="200"
                  max-width="300"
                  class="rounded"
                  @error="handleImageError"
                >
                  <template #placeholder>
                    <div class="d-flex align-center justify-center fill-height">
                      <v-progress-circular indeterminate />
                    </div>
                  </template>
                </v-img>
              </div>
            </v-col>
          </v-row>

          <!-- Error Alert -->
          <v-alert
            v-if="errorMessage"
            type="error"
            class="mt-4"
            closable
            @click:close="errorMessage = ''"
          >
            {{ errorMessage }}
          </v-alert>

          <!-- Success Alert -->
          <v-alert
            v-if="successMessage"
            type="success"
            class="mt-4"
            closable
            @click:close="successMessage = ''"
          >
            {{ successMessage }}
          </v-alert>
        </v-form>
      </v-card-text>

      <v-divider />

      <v-card-actions class="pa-4">
        <v-spacer />
        <v-btn
          variant="text"
          @click="handleCancel"
          :disabled="loading"
        >
          キャンセル
        </v-btn>
        <v-btn
          color="primary"
          :loading="loading"
          :disabled="!isFormValid"
          @click="handleSubmit"
        >
          {{ isEditing ? '更新' : '登録' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import type { Store, StoreCreateRequest } from '../types/store'

interface Props {
  modelValue: boolean
  store?: Store | null
  loading?: boolean
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'save', data: StoreCreateRequest): void
  (e: 'update', id: number, data: Partial<StoreCreateRequest>): void
}

const props = withDefaults(defineProps<Props>(), {
  store: null,
  loading: false
})

const emit = defineEmits<Emits>()

// Form state
const formRef = ref()
const isFormValid = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const validationErrors = ref<Record<string, string[]>>({})

// Form data
const formData = ref<StoreCreateRequest>({
  name: '',
  description: '',
  address: '',
  phone: '',
  business_hours: '',
  genre: '',
  latitude: undefined,
  longitude: undefined,
  image_url: ''
})

// Computed
const isEditing = computed(() => !!props.store?.id)

// Genre options
const genreOptions = [
  'レストラン',
  'カフェ',
  '居酒屋',
  'ファストフード',
  'その他'
]

// Validation rules
const nameRules = [
  (v: string) => !!v || '店舗名は必須です',
  (v: string) => (v && v.length >= 2) || '店舗名は2文字以上で入力してください',
  (v: string) => (v && v.length <= 100) || '店舗名は100文字以内で入力してください'
]

const genreRules = [
  (v: string) => !!v || 'ジャンルは必須です'
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

const descriptionRules = [
  (v: string) => !v || v.length <= 1000 || '説明は1000文字以内で入力してください'
]

const latitudeRules = [
  (v: number | undefined) => v === undefined || (v >= -90 && v <= 90) || '緯度は-90から90の間で入力してください'
]

const longitudeRules = [
  (v: number | undefined) => v === undefined || (v >= -180 && v <= 180) || '経度は-180から180の間で入力してください'
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
  // Handle image loading error
  console.warn('Failed to load image:', formData.value.image_url)
}

// Form handlers
const resetForm = () => {
  formData.value = {
    name: '',
    description: '',
    address: '',
    phone: '',
    business_hours: '',
    genre: '',
    latitude: undefined,
    longitude: undefined,
    image_url: ''
  }
  errorMessage.value = ''
  successMessage.value = ''
  validationErrors.value = {}
  
  nextTick(() => {
    formRef.value?.resetValidation()
  })
}

const populateForm = (store: Store) => {
  formData.value = {
    name: store.name || '',
    description: store.description || '',
    address: store.address || '',
    phone: store.phone || '',
    business_hours: store.business_hours || '',
    genre: store.genre || '',
    latitude: store.latitude || undefined,
    longitude: store.longitude || undefined,
    image_url: store.image_url || ''
  }
}

const handleSubmit = async () => {
  if (!isFormValid.value) return

  try {
    errorMessage.value = ''
    validationErrors.value = {}

    if (isEditing.value && props.store) {
      emit('update', props.store.id, formData.value)
    } else {
      emit('save', formData.value)
    }
  } catch (error: any) {
    if (error.errors) {
      validationErrors.value = error.errors
    }
    errorMessage.value = error.message || '保存に失敗しました'
  }
}

const handleCancel = () => {
  emit('update:modelValue', false)
}

// Watchers
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue) {
      if (props.store) {
        populateForm(props.store)
      } else {
        resetForm()
      }
    }
  }
)

watch(
  () => props.store,
  (newStore) => {
    if (newStore && props.modelValue) {
      populateForm(newStore)
    }
  }
)
</script>

<style scoped>
.v-card-title {
  font-size: 1.25rem;
  font-weight: 600;
}

.v-form {
  width: 100%;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .v-dialog {
    margin: 16px;
  }
  
  .v-card {
    max-height: 90vh;
    overflow-y: auto;
  }
}
</style>