// Shop Genre Enum - matches Laravel and iOS definitions
export enum ShopGenre {
    RAMEN = 'ラーメン',
    CAFE = 'カフェ',
    IZAKAYA = '居酒屋',
    YAKINIKU = '焼肉',
    SUSHI = '寿司',
    SWEETS = 'スイーツ',
    FAST_FOOD = 'ファストフード',
    RESTAURANT = 'レストラン',
    BAR = 'バー',
    BAKERY = 'ベーカリー',
    ITALIAN = 'イタリアン',
    CHINESE = '中華',
    KOREAN = '韓国料理',
    FRENCH = 'フレンチ',
    JAPANESE = '和食',
    WESTERN = '洋食',
    SEAFOOD = '海鮮',
    VEGETARIAN = 'ベジタリアン',
    BBQ = 'BBQ',
    OTHER = 'その他'
}

// Shop interface - enhanced version of Store interface
export interface Shop {
    id: number
    name: string
    description: string | null
    address: string | null
    phone: string | null
    business_hours: string | null
    genre: ShopGenre | null
    latitude: number | null
    longitude: number | null
    image_url: string | null
    has_try_benefit: boolean
    stamp_count: number
    is_approved: boolean
    created_at: string
    updated_at: string
}

export interface ShopFormData {
    name: string
    description?: string
    address?: string
    phone?: string
    business_hours?: string
    genre?: ShopGenre
    latitude?: number
    longitude?: number
    image_url?: string
    has_try_benefit: boolean
    stamp_count: number
    is_approved?: boolean
}

export interface ShopCreateRequest extends ShopFormData { }

export interface ShopUpdateRequest extends Partial<ShopFormData> {
    id: number
}

export interface ShopListResponse {
    data: Shop[]
    meta: {
        current_page: number
        last_page: number
        per_page: number
        total: number
        from: number
        to: number
    }
}

export interface ShopApiResponse {
    data: Shop
    message?: string
}

export interface ShopFilters {
    search: string
    genre: ShopGenre | null
    city: string
    has_try_benefit: boolean | null
    is_approved: boolean | null
    stamp_count_min: number | null
    stamp_count_max: number | null
}

export interface ShopQueryParams {
    page?: number
    per_page?: number
    search?: string
    genre?: ShopGenre
    city?: string
    has_try_benefit?: boolean
    is_approved?: boolean
    stamp_count_min?: number
    stamp_count_max?: number
    sort_by?: string
    sort_desc?: boolean
}

// Favorite interfaces
export interface Favorite {
    id: number
    user_id: number
    shop_id: number
    shop?: Shop
    created_at: string
    updated_at: string
}

export interface FavoriteCreateRequest {
    shop_id: number
}

export interface FavoriteToggleResponse {
    favorited: boolean
    message?: string
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

// Shop Proposal interfaces
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
    genre: ShopGenre | null
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
    genre?: ShopGenre
    description?: string
}

export interface ShopProposalUpdateRequest {
    status: ProposalStatus
    admin_notes?: string
}

export interface ShopProposalApprovalRequest {
    admin_notes?: string
}

export interface ShopProposalRejectionRequest {
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

export interface ShopProposalApiResponse {
    data: ShopProposal
    message?: string
}

export interface ShopProposalFilters {
    status: ProposalStatus | null
    search: string
    user_id: number | null
    genre: ShopGenre | null
}

export interface ShopProposalQueryParams {
    page?: number
    per_page?: number
    status?: ProposalStatus
    search?: string
    user_id?: number
    genre?: ShopGenre
    sort_by?: string
    sort_desc?: boolean
}

// Common API response types
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

// Utility types for form validation
export interface ValidationRule {
    required?: boolean
    minLength?: number
    maxLength?: number
    pattern?: RegExp
    custom?: (value: any) => boolean | string
}

export interface FormValidationRules {
    [key: string]: ValidationRule[]
}

// Genre utility functions
export const getGenreOptions = () => {
    return Object.values(ShopGenre).map(genre => ({
        label: genre,
        value: genre
    }))
}

export const getGenreDisplayName = (genre: ShopGenre | null): string => {
    return genre || 'ジャンル未設定'
}

export const getProposalStatusDisplayName = (status: ProposalStatus): string => {
    switch (status) {
        case ProposalStatus.PENDING:
            return '承認待ち'
        case ProposalStatus.APPROVED:
            return '承認済み'
        case ProposalStatus.REJECTED:
            return '却下'
        default:
            return '不明'
    }
}

export const getProposalStatusColor = (status: ProposalStatus): string => {
    switch (status) {
        case ProposalStatus.PENDING:
            return 'warning'
        case ProposalStatus.APPROVED:
            return 'success'
        case ProposalStatus.REJECTED:
            return 'error'
        default:
            return 'default'
    }
}