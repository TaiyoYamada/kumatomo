import api from '@/services/api'

interface LoginResponse {
  access_token: string
  token_type: string
  user?: any
}

export const authService = {
  async login(email: string, password: string): Promise<void> {
    const response = await api.post<LoginResponse>('/login', { email, password })
    const token = response.data.access_token
    if (!token) throw new Error('トークンを取得できませんでした')
    localStorage.setItem('admin_token', token)
  },

  async register(email: string, password: string): Promise<void> {
    const response = await api.post<LoginResponse>('/register', { email, password })
    const token = response.data.access_token
    if (!token) throw new Error('トークンを取得できませんでした')
    localStorage.setItem('admin_token', token)
  },

  logout(): void {
    localStorage.removeItem('admin_token')
  },

  isAuthenticated(): boolean {
    return !!localStorage.getItem('admin_token')
  }
}
