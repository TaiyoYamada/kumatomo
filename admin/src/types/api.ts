// API Response Types
export interface ApiResponse<T> {
    data: T
    message?: string
}

export interface PaginatedResponse<T> {
    data: T[]
    pagination: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number | null
        to: number | null
        has_more_pages: boolean
    }
    filters?: {
        genres?: string
        location?: {
            lat: number
            lng: number
            radius: number
        } | null
        search?: string
        sort_by?: string
        sort_order?: string
    }
}

export interface ApiError {
    error: {
        message: string
        code?: string
        details?: Record<string, string[]>
    }
}

// Request Parameters
export interface ShopListParams {
    genres?: string
    genre?: string // backward compatibility
    lat?: number
    lng?: number
    radius?: number
    q?: string
    per_page?: number
    page?: number
    sort_by?: 'name' | 'created_at' | 'distance' | 'stamp_count'
    sort_order?: 'asc' | 'desc'
}

export interface FavoriteListParams {
    genres?: string
    lat?: number
    lng?: number
    radius?: number
    q?: string
    per_page?: number
    page?: number
    sort_by?: 'name' | 'created_at' | 'distance'
    sort_order?: 'asc' | 'desc'
}

export interface ShopProposalParams {
    name: string
    address?: string
    genre?: string
    description?: string
}

export interface ShopFormData {
    name: string
    description?: string
    address?: string
    phone?: string
    business_hours?: string
    genre?: string
    latitude?: number
    longitude?: number
    image_url?: string
    has_try_benefit: boolean
    stamp_count: number
}