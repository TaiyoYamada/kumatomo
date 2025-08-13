<template>
  <v-snackbar
    v-model="isOffline"
    :timeout="-1"
    location="top right"
    color="error"
    variant="elevated"
    class="network-status-offline"
  >
    <div class="d-flex align-center">
      <v-icon class="mr-3" size="20">mdi-wifi-off</v-icon>
      <div>
        <div class="text-body-2 font-weight-medium">オフライン</div>
        <div class="text-caption">インターネット接続を確認してください</div>
      </div>
    </div>
  </v-snackbar>
  
  <v-snackbar
    v-model="showOnlineMessage"
    :timeout="3000"
    location="top right"
    color="success"
    variant="elevated"
    class="network-status-online"
  >
    <div class="d-flex align-center">
      <v-icon class="mr-3" size="20">mdi-wifi</v-icon>
      <div>
        <div class="text-body-2 font-weight-medium">オンライン</div>
        <div class="text-caption">接続が復旧しました</div>
      </div>
    </div>
  </v-snackbar>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { isNetworkOnline, onNetworkStatusChange } from '../../utils/errorHandler.js'

export default {
  name: 'NetworkStatus',
  setup() {
    const isOnline = ref(isNetworkOnline())
    const isOffline = computed(() => !isOnline.value)
    const showOnlineMessage = ref(false)
    let unsubscribe = null

    const handleNetworkChange = (online) => {
      isOnline.value = online
      
      if (online) {
        // Show online message briefly
        showOnlineMessage.value = true
      } else {
        showOnlineMessage.value = false
      }
    }

    onMounted(() => {
      unsubscribe = onNetworkStatusChange(handleNetworkChange)
    })

    onUnmounted(() => {
      if (unsubscribe) {
        unsubscribe()
      }
    })

    return {
      isOnline,
      isOffline,
      showOnlineMessage
    }
  }
}
</script>

<style scoped>
/* Network status styling with consistent spacing */
.network-status-offline :deep(.v-snackbar__wrapper) {
  margin-top: 1rem;
  margin-right: 1rem;
}

.network-status-online :deep(.v-snackbar__wrapper) {
  margin-top: 1rem;
  margin-right: 1rem;
}

/* Responsive adjustments */
@media (max-width: 600px) {
  .network-status-offline :deep(.v-snackbar__wrapper),
  .network-status-online :deep(.v-snackbar__wrapper) {
    margin-left: 1rem;
    margin-right: 1rem;
  }
}
</style>