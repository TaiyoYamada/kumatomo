<template>
  <v-card class="store-filters" elevation="1">
    <v-card-text>
      <v-row>
        <!-- Search Field -->
        <v-col cols="12" md="4">
          <v-text-field
            v-model="localFilters.search"
            label="店舗名で検索"
            placeholder="店舗名を入力..."
            prepend-inner-icon="mdi-magnify"
            variant="outlined"
            density="compact"
            clearable
            @input="debouncedSearch"
          />
        </v-col>

        <!-- Genre Filter -->
        <v-col cols="12" md="3">
          <v-select
            v-model="localFilters.genre"
            :items="genreOptions"
            label="ジャンル"
            variant="outlined"
            density="compact"
            clearable
            @update:model-value="handleFilterChange"
          />
        </v-col>

        <!-- City Filter -->
        <v-col cols="12" md="3">
          <v-select
            v-model="localFilters.city"
            :items="cityOptions"
            label="市区町村"
            variant="outlined"
            density="compact"
            clearable
            @update:model-value="handleFilterChange"
          />
        </v-col>

        <!-- Try Benefit Filter -->
        <v-col cols="12" md="2">
          <v-select
            v-model="localFilters.has_try_benefit"
            :items="tryBenefitOptions"
            label="Try特典"
            variant="outlined"
            density="compact"
            clearable
            @update:model-value="handleFilterChange"
          />
        </v-col>
      </v-row>

      <!-- Filter Actions -->
      <v-row v-if="hasActiveFilters" class="mt-2">
        <v-col cols="12">
          <div class="d-flex align-center justify-space-between">
            <div class="d-flex flex-wrap gap-2">
              <v-chip
                v-if="localFilters.search"
                closable
                size="small"
                color="primary"
                variant="outlined"
                @click:close="clearSearchFilter"
              >
                検索: {{ localFilters.search }}
              </v-chip>
              
              <v-chip
                v-if="localFilters.genre"
                closable
                size="small"
                color="primary"
                variant="outlined"
                @click:close="clearGenreFilter"
              >
                ジャンル: {{ localFilters.genre }}
              </v-chip>
              
              <v-chip
                v-if="localFilters.city"
                closable
                size="small"
                color="primary"
                variant="outlined"
                @click:close="clearCityFilter"
              >
                市区町村: {{ localFilters.city }}
              </v-chip>
              
              <v-chip
                v-if="localFilters.has_try_benefit !== null"
                closable
                size="small"
                color="primary"
                variant="outlined"
                @click:close="clearTryBenefitFilter"
              >
                Try特典: {{ localFilters.has_try_benefit ? 'あり' : 'なし' }}
              </v-chip>
            </div>
            
            <v-btn
              size="small"
              variant="text"
              color="error"
              @click="clearAllFilters"
            >
              すべてクリア
            </v-btn>
          </div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import type { StoreFilters } from '../types/store'

interface Props {
  modelValue: StoreFilters
  loading?: boolean
}

interface Emits {
  (e: 'update:modelValue', value: StoreFilters): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<Emits>()

// Local reactive copy of filters
const localFilters = ref<StoreFilters>({ ...props.modelValue })

// Filter options
const genreOptions = [
  { title: 'レストラン', value: 'レストラン' },
  { title: 'カフェ', value: 'カフェ' },
  { title: '居酒屋', value: '居酒屋' },
  { title: 'ファストフード', value: 'ファストフード' },
  { title: 'その他', value: 'その他' }
]

const cityOptions = [
  { title: '東京都', value: '東京都' },
  { title: '大阪府', value: '大阪府' },
  { title: '神奈川県', value: '神奈川県' },
  { title: '愛知県', value: '愛知県' },
  { title: '福岡県', value: '福岡県' },
  { title: '北海道', value: '北海道' },
  { title: 'その他', value: 'その他' }
]

const tryBenefitOptions = [
  { title: 'あり', value: true },
  { title: 'なし', value: false }
]

// Computed properties
const hasActiveFilters = computed(() => {
  return !!(
    localFilters.value.search ||
    localFilters.value.genre ||
    localFilters.value.city ||
    localFilters.value.has_try_benefit !== null
  )
})

// Debounced search
let searchTimeout: NodeJS.Timeout | null = null

const debouncedSearch = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  
  searchTimeout = setTimeout(() => {
    handleFilterChange()
  }, 300) // 300ms delay
}

// Filter change handler
const handleFilterChange = () => {
  emit('update:modelValue', { ...localFilters.value })
}

// Clear individual filters
const clearSearchFilter = () => {
  localFilters.value.search = ''
  handleFilterChange()
}

const clearGenreFilter = () => {
  localFilters.value.genre = ''
  handleFilterChange()
}

const clearCityFilter = () => {
  localFilters.value.city = ''
  handleFilterChange()
}

const clearTryBenefitFilter = () => {
  localFilters.value.has_try_benefit = null
  handleFilterChange()
}

// Clear all filters
const clearAllFilters = () => {
  localFilters.value = {
    search: '',
    genre: '',
    city: '',
    has_try_benefit: null
  }
  handleFilterChange()
}

// Watch for external changes to modelValue
watch(
  () => props.modelValue,
  (newValue) => {
    localFilters.value = { ...newValue }
  },
  { deep: true }
)

// Cleanup timeout on unmount
onMounted(() => {
  return () => {
    if (searchTimeout) {
      clearTimeout(searchTimeout)
    }
  }
})
</script>

<style scoped>
.store-filters {
  margin-bottom: 1rem;
}

.gap-2 > * {
  margin-right: 0.5rem;
  margin-bottom: 0.5rem;
}

.gap-2 > *:last-child {
  margin-right: 0;
}
</style>