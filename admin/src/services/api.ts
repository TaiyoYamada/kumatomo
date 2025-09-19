import axios, { AxiosInstance, AxiosResponse, AxiosError } from 'axios'

// Legacy API service for backward compatibility
// This maintains the same interface as the old api.js file
// New code should use apiClient.ts instead

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'

const api: AxiosInstance = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
})

// Request interceptor for auth token
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('admin_token')
        if (token) {
            config.headers.Authorization = `Bearer ${token}`
        }
        return config
    },
    (error: AxiosError) => {
        return Promise.reject(error)
    }
)

// Response interceptor for error handling
api.interceptors.response.use(
    (response: AxiosResponse) => response,
    (error: AxiosError) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('admin_token')
            // Redirect to login if needed
        }
        return Promise.reject(error)
    }
)

export default api