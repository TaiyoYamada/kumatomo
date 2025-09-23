// Shop Genre Enum
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

// Shop Interface
export interface Shop {
    id: number
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
    is_approved: boolean
    created_at: string
    updated_at: string
    distance?: number // Added when location filtering is used
}

// Favorite Interface
export interface Favorite {
    id: number
    user_id: number
    shop_id: number
    shop?: Shop
    created_at: string
    favorited_at?: string // When fetching favorites with shop data
}

// Shop Proposal Interface
export interface ShopProposal {
    id: number
    user_id: number
    name: string
    address?: string
    genre?: ShopGenre
    description?: string
    status: ProposalStatus
    admin_notes?: string
    created_at: string
    updated_at: string
    processing?: boolean // UI state for loading
    user?: {
        id: number
        name: string
        username: string
        email: string
    }
}

export enum ProposalStatus {
    PENDING = 'pending',
    APPROVED = 'approved',
    REJECTED = 'rejected'
}

// Favorite Statistics
export interface FavoriteStats {
    total_favorites: number
    favorites_by_genre: Record<string, number>
}

// Toggle Response
export interface FavoriteToggleResponse {
    favorited: boolean
    message: string
}

// Check Response
export interface FavoriteCheckResponse {
    favorited: boolean
}

// Genre Option for UI
export interface GenreOption {
    label: string
    value: ShopGenre
}

// Helper function to get genre options
export const getGenreOptions = (): GenreOption[] => {
    return Object.values(ShopGenre).map(genre => ({
        label: genre,
        value: genre
    }))
}

// Helper function to get genre color (can be customized)
export const getGenreColor = (genre: ShopGenre): string => {
    const colorMap: Record<ShopGenre, string> = {
        [ShopGenre.RAMEN]: '#FF6B6B',
        [ShopGenre.CAFE]: '#4ECDC4',
        [ShopGenre.IZAKAYA]: '#45B7D1',
        [ShopGenre.YAKINIKU]: '#96CEB4',
        [ShopGenre.SUSHI]: '#FFEAA7',
        [ShopGenre.SWEETS]: '#DDA0DD',
        [ShopGenre.FAST_FOOD]: '#98D8C8',
        [ShopGenre.RESTAURANT]: '#F7DC6F',
        [ShopGenre.BAR]: '#BB8FCE',
        [ShopGenre.BAKERY]: '#F8C471',
        [ShopGenre.ITALIAN]: '#85C1E9',
        [ShopGenre.CHINESE]: '#F1948A',
        [ShopGenre.KOREAN]: '#82E0AA',
        [ShopGenre.FRENCH]: '#D7BDE2',
        [ShopGenre.JAPANESE]: '#A9DFBF',
        [ShopGenre.WESTERN]: '#F9E79F',
        [ShopGenre.SEAFOOD]: '#85C1E9',
        [ShopGenre.VEGETARIAN]: '#ABEBC6',
        [ShopGenre.BBQ]: '#FADBD8',
        [ShopGenre.OTHER]: '#D5DBDB'
    }
    return colorMap[genre] || '#D5DBDB'
}