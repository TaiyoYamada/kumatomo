<template>
  <div v-if="!isOnline" class="network-status offline">
    <div class="status-content">
      <svg class="status-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.07 2.93 1 9z"/>
        <path d="M5 13l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.24 9.24 8.76 9.24 5 13z"/>
        <path d="M9 17l2 2c.55-.55 1.45-.55 2 0l2-2C13.24 15.24 10.76 15.24 9 17z"/>
        <line x1="1" y1="1" x2="23" y2="23"/>
      </svg>
      <div class="status-text">
        <div class="status-title">オフライン</div>
        <div class="status-message">インターネット接続を確認してください</div>
      </div>
    </div>
  </div>
  
  <div v-else-if="showOnlineMessage" class="network-status online">
    <div class="status-content">
      <svg class="status-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.07 2.93 1 9z"/>
        <path d="M5 13l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.24 9.24 8.76 9.24 5 13z"/>
        <path d="M9 17l2 2c.55-.55 1.45-.55 2 0l2-2C13.24 15.24 10.76 15.24 9 17z"/>
      </svg>
      <div class="status-text">
        <div class="status-title">オンライン</div>
        <div class="status-message">接続が復旧しました</div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted } from 'vue'
import { isNetworkOnline, onNetworkStatusChange } from '../../utils/errorHandler.js'

export default {
  name: 'NetworkStatus',
  setup() {
    const isOnline = ref(isNetworkOnline())
    const showOnlineMessage = ref(false)
    let unsubscribe = null
    let onlineMessageTimer = null

    const handleNetworkChange = (online) => {
      isOnline.value = online
      
      if (online) {
        // Show online message briefly
        showOnlineMessage.value = true
        
        // Hide online message after 3 seconds
        if (onlineMessageTimer) {
          clearTimeout(onlineMessageTimer)
        }
        onlineMessageTimer = setTimeout(() => {
          showOnlineMessage.value = false
        }, 3000)
      } else {
        showOnlineMessage.value = false
        if (onlineMessageTimer) {
          clearTimeout(onlineMessageTimer)
        }
      }
    }

    onMounted(() => {
      unsubscribe = onNetworkStatusChange(handleNetworkChange)
    })

    onUnmounted(() => {
      if (unsubscribe) {
        unsubscribe()
      }
      if (onlineMessageTimer) {
        clearTimeout(onlineMessageTimer)
      }
    })

    return {
      isOnline,
      showOnlineMessage
    }
  }
}
</script>

<style scoped>
.network-status {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1000;
  padding: 12px 16px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  animation: slideIn 0.3s ease-out;
  max-width: 300px;
}

.network-status.offline {
  background-color: #fee;
  border: 1px solid #fcc;
  color: #c33;
}

.network-status.online {
  background-color: #efe;
  border: 1px solid #cfc;
  color: #3c3;
}

.status-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.status-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.status-text {
  flex: 1;
}

.status-title {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 2px;
}

.status-message {
  font-size: 12px;
  opacity: 0.8;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@media (max-width: 768px) {
  .network-status {
    top: 10px;
    right: 10px;
    left: 10px;
    max-width: none;
  }
}
</style>