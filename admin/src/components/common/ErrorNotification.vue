<template>
  <div v-if="visible" class="error-notification" :class="notification.type">
    <div class="notification-content">
      <div class="notification-icon">
        <svg v-if="notification.type === 'error'" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10"/>
          <line x1="15" y1="9" x2="9" y2="15"/>
          <line x1="9" y1="9" x2="15" y2="15"/>
        </svg>
        <svg v-else-if="notification.type === 'warning'" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
          <line x1="12" y1="9" x2="12" y2="13"/>
          <line x1="12" y1="17" x2="12.01" y2="17"/>
        </svg>
        <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10"/>
          <path d="M12 6v6l4 2"/>
        </svg>
      </div>
      
      <div class="notification-text">
        <div class="notification-title">{{ notification.title }}</div>
        <div class="notification-message">{{ notification.message }}</div>
        <div v-if="notification.suggestion" class="notification-suggestion">
          {{ notification.suggestion }}
        </div>
        <div v-if="notification.context" class="notification-context">
          コンテキスト: {{ notification.context }}
        </div>
      </div>
      
      <div class="notification-actions">
        <button 
          v-if="notification.isRetryable && onRetry" 
          @click="handleRetry"
          class="retry-button"
          :disabled="retrying"
        >
          <svg v-if="retrying" class="spin" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M21 12a9 9 0 11-6.219-8.56"/>
          </svg>
          <span>{{ retrying ? '再試行中...' : '再試行' }}</span>
        </button>
        
        <button @click="dismiss" class="dismiss-button">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <line x1="18" y1="6" x2="6" y2="18"/>
            <line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>
    </div>
    
    <div v-if="autoHide" class="progress-bar">
      <div class="progress-fill" :style="{ animationDuration: `${autoHideDelay}ms` }"></div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted } from 'vue'

export default {
  name: 'ErrorNotification',
  props: {
    notification: {
      type: Object,
      required: true
    },
    autoHide: {
      type: Boolean,
      default: true
    },
    autoHideDelay: {
      type: Number,
      default: 5000
    },
    onRetry: {
      type: Function,
      default: null
    },
    onDismiss: {
      type: Function,
      default: null
    }
  },
  emits: ['dismiss', 'retry'],
  setup(props, { emit }) {
    const visible = ref(true)
    const retrying = ref(false)
    let autoHideTimer = null

    const dismiss = () => {
      visible.value = false
      if (autoHideTimer) {
        clearTimeout(autoHideTimer)
      }
      emit('dismiss')
      if (props.onDismiss) {
        props.onDismiss()
      }
    }

    const handleRetry = async () => {
      if (retrying.value) return
      
      retrying.value = true
      
      try {
        if (props.onRetry) {
          await props.onRetry()
        }
        emit('retry')
        dismiss()
      } catch (error) {
        console.error('Retry failed:', error)
      } finally {
        retrying.value = false
      }
    }

    onMounted(() => {
      if (props.autoHide && props.notification.type !== 'error') {
        autoHideTimer = setTimeout(() => {
          dismiss()
        }, props.autoHideDelay)
      }
    })

    onUnmounted(() => {
      if (autoHideTimer) {
        clearTimeout(autoHideTimer)
      }
    })

    return {
      visible,
      retrying,
      dismiss,
      handleRetry
    }
  }
}
</script>

<style scoped>
.error-notification {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1001;
  min-width: 320px;
  max-width: 480px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  animation: slideIn 0.3s ease-out;
  overflow: hidden;
}

.error-notification.error {
  background-color: #fee;
  border: 1px solid #fcc;
  color: #c33;
}

.error-notification.warning {
  background-color: #fff3cd;
  border: 1px solid #ffeaa7;
  color: #856404;
}

.error-notification.info {
  background-color: #e3f2fd;
  border: 1px solid #bbdefb;
  color: #1565c0;
}

.notification-content {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px;
}

.notification-icon {
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  margin-top: 2px;
}

.notification-icon svg {
  width: 100%;
  height: 100%;
}

.notification-text {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 4px;
}

.notification-message {
  font-size: 13px;
  line-height: 1.4;
  margin-bottom: 4px;
}

.notification-suggestion {
  font-size: 12px;
  opacity: 0.8;
  font-style: italic;
  margin-bottom: 4px;
}

.notification-context {
  font-size: 11px;
  opacity: 0.6;
  font-family: monospace;
}

.notification-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex-shrink: 0;
}

.retry-button,
.dismiss-button {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 8px;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.retry-button {
  background-color: rgba(0, 0, 0, 0.1);
  color: inherit;
}

.retry-button:hover:not(:disabled) {
  background-color: rgba(0, 0, 0, 0.2);
}

.retry-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.dismiss-button {
  background-color: transparent;
  color: inherit;
  opacity: 0.6;
}

.dismiss-button:hover {
  opacity: 1;
  background-color: rgba(0, 0, 0, 0.1);
}

.retry-button svg,
.dismiss-button svg {
  width: 14px;
  height: 14px;
}

.progress-bar {
  height: 3px;
  background-color: rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background-color: currentColor;
  opacity: 0.3;
  animation: progress linear;
  transform-origin: left;
}

.spin {
  animation: spin 1s linear infinite;
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

@keyframes progress {
  from {
    transform: scaleX(1);
  }
  to {
    transform: scaleX(0);
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 768px) {
  .error-notification {
    top: 10px;
    right: 10px;
    left: 10px;
    min-width: auto;
    max-width: none;
  }
}
</style>