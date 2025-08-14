export interface Store {
    id: number
    name: string
    description: string | null
    address: string | null
    phone: string | null
    business_hours: string | null
    genre: string | null
    latitude: number | null
    longitude: number | null
    image_url: string | null
    created_at: string
    updated_at: string

    // Computed fields
    city?: string // Extracted from address
    has_try_benefit?: boolean // Based on business logic
    status?: 'active' | 'inactive' // Based on business logic
}

export interface StoreFilters {
    search: string
    genre: string
    city: string
    has_try_benefit: boolean | null
}

export interface StoreListResponse {
    data: Store[]
    meta: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number
        to: number
    }
}

export interface StoreApiResponse {
    data: Store
    message: string
}

export interface StoreCreateRequest {
    name: string
    description?: string
    address?: string
    phone?: string
    business_hours?: string
    genre?: string
    latitude?: number
    longitude?: number
    image_url?: string
}

export interface StoreUpdateRequest extends Partial<StoreCreateRequest> {
    id: number
}

// API response types
export interface ApiResponse<T> {
    data: T
    message?: string
}

export interface PaginatedResponse<T> {
    data: T[]
    meta: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number
        to: number
    }
}

export interface ApiError {
    message: string
    errors?: Record<string, string[]>
}

// Filter and search parameters
export interface StoreQueryParams {
    page?: number
    per_page?: number
    search?: string
    genre?: string
    city?: string
    has_try_benefit?: boolean
    sort_by?: string
    sort_desc?: boolean
}