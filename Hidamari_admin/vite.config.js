import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vuetify from 'vuetify/vite-plugin'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),
    vuetify({ autoImport: true }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'resources/js'),
    },
  },
  server: {
    host: '0.0.0.0',
    port: Number(process.env.VITE_PORT) || 5173,
    hmr: {
      host: 'localhost',
    },
  },
})
