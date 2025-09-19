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
    has_try_benefit: boolean
    stamp_count: number
    is_approved: boolean
    created_at: string
    updated_at: string

    // Computed fields
    city?: string // Extracted from address
    status?: 'active' | 'inactive' // Based on business logic
}

export interface StoreFilters {
    search: string
    genre: string
    city: string
    has_try_benefit: boolean | null
    is_approved: boolean | null
    stamp_count_min: number | null
    stamp_count_max: number | null
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
    has_try_benefit?: boolean
    stamp_count?: number
    is_approved?: boolean
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
    is_approved?: boolean
    stamp_count_min?: number
    stamp_count_max?: number
    sort_by?: string
    sort_desc?: boolean
}

// Favorite related interfaces
export interface Favorite {
    id: number
    user_id: number
    shop_id: number
    shop?: Store
    created_at: string
    updated_at: string
}

export interface FavoriteCreateRequest {
    shop_id: number
}

export interface FavoriteListResponse {
    data: Favorite[]
    meta: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number
        to: number
    }
}

// Shop Proposal related interfaces
export enum ProposalStatus {
    PENDING = 'pending',
    APPROVED = 'approved',
    REJECTED = 'rejected'
}

export interface ShopProposal {
    id: number
    user_id: number
    name: string
    address: string | null
    genre: string | null
    description: string | null
    status: ProposalStatus
    admin_notes: string | null
    created_at: string
    updated_at: string
    user?: {
        id: number
        name: string
        username: string
        email: string
    }
}

export interface ShopProposalCreateRequest {
    name: string
    address?: string
    genre?: string
    description?: string
}

export interface ShopProposalUpdateRequest {
    status: ProposalStatus
    admin_notes?: string
}

export interface ShopProposalListResponse {
    data: ShopProposal[]
    meta: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number
        to: number
    }
}

export interface ShopProposalFilters {
    status: ProposalStatus | null
    search: string
    user_id: number | null
    genre: string | null
}

export interface ShopProposalQueryParams {
    page?: number
    per_page?: number
    status?: ProposalStatus
    search?: string
    user_id?: number
    genre?: string
    sort_by?: string
    sort_desc?: boolean
}