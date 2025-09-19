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

export interface ShopGenreOption {
    label: string
    value: ShopGenre
    color: string
}

/**
 * Get display name for a genre
 */
export const getGenreDisplayName = (genre: ShopGenre): string => {
    return genre
}

/**
 * Get all genre values as an array
 */
export const getAllGenreValues = (): ShopGenre[] => {
    return Object.values(ShopGenre)
}

/**
 * Get all genre options for dropdowns/selects
 */
export const getGenreOptions = (): ShopGenreOption[] => {
    return Object.values(ShopGenre).map(genre => ({
        label: genre,
        value: genre,
        color: getGenreColor(genre)
    }))
}

/**
 * Get color hex code for a genre
 */
export const getGenreColor = (genre: ShopGenre): string => {
    const colorMap: Record<ShopGenre, string> = {
        [ShopGenre.RAMEN]: '#CC3333',
        [ShopGenre.CAFE]: '#996633',
        [ShopGenre.IZAKAYA]: '#E69900',
        [ShopGenre.YAKINIKU]: '#B31A1A',
        [ShopGenre.SUSHI]: '#0066CC',
        [ShopGenre.SWEETS]: '#E666B3',
        [ShopGenre.FAST_FOOD]: '#E6B300',
        [ShopGenre.RESTAURANT]: '#8033B3',
        [ShopGenre.BAR]: '#333333',
        [ShopGenre.BAKERY]: '#CC9966',
        [ShopGenre.ITALIAN]: '#009933',
        [ShopGenre.CHINESE]: '#CC0000',
        [ShopGenre.KOREAN]: '#990066',
        [ShopGenre.FRENCH]: '#004D99',
        [ShopGenre.JAPANESE]: '#669933',
        [ShopGenre.WESTERN]: '#B3804D',
        [ShopGenre.SEAFOOD]: '#00B3CC',
        [ShopGenre.VEGETARIAN]: '#33CC33',
        [ShopGenre.BBQ]: '#804000',
        [ShopGenre.OTHER]: '#808080'
    }

    return colorMap[genre] || '#808080'
}

/**
 * Create genre from string value
 */
export const genreFromValue = (value: string): ShopGenre | null => {
    const genre = Object.values(ShopGenre).find(g => g === value)
    return genre || null
}

/**
 * Check if a string is a valid genre value
 */
export const isValidGenre = (value: string): value is ShopGenre => {
    return Object.values(ShopGenre).includes(value as ShopGenre)
}

/**
 * Get genre count (useful for validation)
 */
export const getGenreCount = (): number => {
    return Object.values(ShopGenre).length
}