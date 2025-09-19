<template>
  <v-container class="fill-height d-flex align-center justify-center">
    <v-card class="pa-6" max-width="420" elevation="2">
      <v-card-title class="text-h5 font-weight-bold pb-2">管理者ログイン</v-card-title>
      <v-card-subtitle class="pb-4">メールアドレスとパスワードを入力してください</v-card-subtitle>
      <v-alert v-if="error" type="error" class="mb-4" closable @click:close="error = ''">
        {{ error }}
      </v-alert>
      <v-form ref="formRef" v-model="valid" @submit.prevent="onSubmit">
        <v-text-field v-model="email" label="メールアドレス" type="email" variant="outlined"
          :rules="emailRules" density="comfortable" class="mb-3" required></v-text-field>
        <v-text-field v-model="password" label="パスワード" type="password" variant="outlined"
          :rules="passwordRules" density="comfortable" required></v-text-field>

        <v-card-actions class="px-0 pt-6">
          <v-btn :loading="loading" type="submit" color="primary" block>ログイン</v-btn>
        </v-card-actions>
      </v-form>

      <div class="text-center mt-4">
        アカウントをお持ちでないですか？
        <RouterLink to="/register">新規登録</RouterLink>
      </div>
    </v-card>
  </v-container>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/authService'

const router = useRouter()

const formRef = ref()
const valid = ref(false)
const loading = ref(false)
const error = ref('')
const email = ref('')
const password = ref('')

const emailRules = [
  (v: string) => !!v || 'メールアドレスは必須です',
  (v: string) => /.+@.+\..+/.test(v) || '正しいメールアドレスを入力してください'
]

const passwordRules = [
  (v: string) => !!v || 'パスワードは必須です',
  (v: string) => v.length >= 6 || 'パスワードは6文字以上で入力してください'
]

const onSubmit = async () => {
  if (!valid.value) return
  try {
    loading.value = true
    error.value = ''
    await authService.login(email.value, password.value)
    router.push('/dashboard')
  } catch (e: any) {
    error.value = e?.response?.data?.message || e?.message || 'ログインに失敗しました'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.fill-height {
  min-height: 100vh;
}
</style>
