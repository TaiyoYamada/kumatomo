<template>
  <v-dialog
    :model-value="modelValue"
    max-width="500px"
    persistent
    @update:model-value="$emit('update:modelValue', $event)"
  >
    <v-card>
      <v-card-title class="d-flex align-center justify-space-between">
        <div class="d-flex align-center">
          <v-icon class="me-2 text-error">mdi-delete-alert</v-icon>
          <span>店舗削除確認</span>
        </div>
        <v-btn
          icon="mdi-close"
          variant="text"
          @click="handleCancel"
          :disabled="loading"
        />
      </v-card-title>

      <v-divider />

      <v-card-text class="pa-6">
        <div v-if="store" class="text-center">
          <!-- Warning Icon -->
          <v-icon
            size="64"
            color="error"
            class="mb-4"
          >
            mdi-alert-circle-outline
          </v-icon>

          <!-- Confirmation Message -->
          <h3 class="text-h6 mb-3">
            以下の店舗を削除しますか？
          </h3>

          <!-- Store Information -->
          <v-card
            variant="outlined"
            class="mb-4"
          >
            <v-card-text class="pa-4">
              <div class="d-flex align-center justify-center mb-2">
                <v-icon class="me-2">mdi-store</v-icon>
                <span class="text-h6 font-weight-bold">{{ store.name }}</span>
              </div>
              
              <div v-if="store.address" class="text-body-2 text-medium-emphasis mb-1">
                <v-icon size="small" class="me-1">mdi-map-marker</v-icon>
                {{ store.address }}
              </div>
              
              <div v-if="store.genre" class="text-body-2 text-medium-emphasis mb-1">
                <v-icon size="small" class="me-1">mdi-tag</v-icon>
                {{ store.genre }}
              </div>
              
              <div v-if="store.phone" class="text-body-2 text-medium-emphasis">
                <v-icon size="small" class="me-1">mdi-phone</v-icon>
                {{ store.phone }}
              </div>
            </v-card-text>
          </v-card>

          <!-- Warning Message -->
          <v-alert
            type="warning"
            variant="tonal"
            class="text-start mb-4"
          >
            <v-icon slot="prepend">mdi-alert-triangle</v-icon>
            <div>
              <strong>注意:</strong> この操作は取り消すことができません。<br>
              店舗に関連するすべてのデータが完全に削除されます。
            </div>
          </v-alert>

          <!-- Error Alert -->
          <v-alert
            v-if="errorMessage"
            type="error"
            class="mb-4 text-start"
            closable
            @click:close="errorMessage = ''"
          >
            {{ errorMessage }}
          </v-alert>
        </div>

        <!-- Loading State -->
        <div v-else-if="loading" class="text-center py-8">
          <v-progress-circular
            indeterminate
            size="48"
            color="primary"
          />
          <div class="mt-3 text-body-1">削除処理中...</div>
        </div>

        <!-- No Store Selected -->
        <div v-else class="text-center py-4">
          <v-icon size="48" color="grey" class="mb-2">mdi-alert-circle</v-icon>
          <div class="text-body-1 text-medium-emphasis">削除する店舗が選択されていません</div>
        </div>
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
          color="error"
          :loading="loading"
          :disabled="!store"
          @click="handleDelete"
        >
          <v-icon class="me-1">mdi-delete</v-icon>
          削除する
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useStoreApi } from '../composables/useStoreApi'
import type { Store } from '../types/store'

interface Props {
  modelValue: boolean
  store?: Store | null
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'store-deleted', storeId: number): void
}

const props = withDefaults(defineProps<Props>(), {
  store: null
})

const emit = defineEmits<Emits>()

// Composables
const { deleteStore } = useStoreApi()

// State
const loading = ref(false)
const errorMessage = ref('')

// Methods
const handleDelete = async () => {
  if (!props.store) {
    errorMessage.value = '削除する店舗が選択されていません'
    return
  }

  try {
    loading.value = true
    errorMessage.value = ''

    // Call the delete API
    await deleteStore(props.store.id)

    // Emit success event
    emit('store-deleted', props.store.id)
    
    // Close dialog
    emit('update:modelValue', false)

  } catch (error: any) {
    // Handle different types of errors
    if (error.response?.status === 404) {
      errorMessage.value = '指定された店舗が見つかりません'
    } else if (error.response?.status === 403) {
      errorMessage.value = 'この店舗を削除する権限がありません'
    } else if (error.response?.status === 409) {
      errorMessage.value = 'この店舗は他のデータと関連付けられているため削除できません'
    } else {
      errorMessage.value = error.message || '店舗の削除に失敗しました'
    }
    
    console.error('Store deletion failed:', error)
  } finally {
    loading.value = false
  }
}

const handleCancel = () => {
  if (!loading.value) {
    emit('update:modelValue', false)
  }
}

// Clear error when dialog opens/closes
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue) {
      errorMessage.value = ''
    }
  }
)

// Clear error when store changes
watch(
  () => props.store,
  () => {
    errorMessage.value = ''
  }
)
</script>

<style scoped>
.v-card-title {
  font-size: 1.25rem;
  font-weight: 600;
}

.text-error {
  color: rgb(var(--v-theme-error)) !important;
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
  
  .v-card-text {
    padding: 16px !important;
  }
  
  .v-card-actions {
    padding: 16px !important;
  }
}

/* Animation for warning icon */
.v-icon.mdi-alert-circle-outline {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
  100% {
    opacity: 1;
  }
}
</style>