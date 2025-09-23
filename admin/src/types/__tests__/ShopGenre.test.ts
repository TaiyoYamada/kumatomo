import { describe, it, expect } from 'vitest'
import {
    ShopGenre,
    getGenreDisplayName,
    getAllGenreValues,
    getGenreOptions,
    getGenreColor,
    genreFromValue,
    isValidGenre,
    getGenreCount
} from '../ShopGenre'

describe('ShopGenre', () => {
    it('should have exactly 20 genres', () => {
        expect(getGenreCount()).toBe(20)
        expect(Object.values(ShopGenre)).toHaveLength(20)
    })

    it('should have correct genre values', () => {
        expect(ShopGenre.RAMEN).toBe('ラーメン')
        expect(ShopGenre.CAFE).toBe('カフェ')
        expect(ShopGenre.IZAKAYA).toBe('居酒屋')
        expect(ShopGenre.YAKINIKU).toBe('焼肉')
        expect(ShopGenre.SUSHI).toBe('寿司')
        expect(ShopGenre.SWEETS).toBe('スイーツ')
        expect(ShopGenre.FAST_FOOD).toBe('ファストフード')
        expect(ShopGenre.RESTAURANT).toBe('レストラン')
        expect(ShopGenre.BAR).toBe('バー')
        expect(ShopGenre.BAKERY).toBe('ベーカリー')
        expect(ShopGenre.ITALIAN).toBe('イタリアン')
        expect(ShopGenre.CHINESE).toBe('中華')
        expect(ShopGenre.KOREAN).toBe('韓国料理')
        expect(ShopGenre.FRENCH).toBe('フレンチ')
        expect(ShopGenre.JAPANESE).toBe('和食')
        expect(ShopGenre.WESTERN).toBe('洋食')
        expect(ShopGenre.SEAFOOD).toBe('海鮮')
        expect(ShopGenre.VEGETARIAN).toBe('ベジタリアン')
        expect(ShopGenre.BBQ).toBe('BBQ')
        expect(ShopGenre.OTHER).toBe('その他')
    })

    it('should return correct display names', () => {
        expect(getGenreDisplayName(ShopGenre.RAMEN)).toBe('ラーメン')
        expect(getGenreDisplayName(ShopGenre.CAFE)).toBe('カフェ')
        expect(getGenreDisplayName(ShopGenre.OTHER)).toBe('その他')
    })

    it('should return all genre values', () => {
        const values = getAllGenreValues()
        expect(values).toHaveLength(20)
        expect(values).toContain('ラーメン')
        expect(values).toContain('カフェ')
        expect(values).toContain('その他')
    })

    it('should return genre options with correct structure', () => {
        const options = getGenreOptions()
        expect(options).toHaveLength(20)

        const ramenOption = options.find(opt => opt.value === ShopGenre.RAMEN)
        expect(ramenOption).toBeDefined()
        expect(ramenOption?.label).toBe('ラーメン')
        expect(ramenOption?.color).toBe('#CC3333')
    })

    it('should return valid hex colors for all genres', () => {
        const hexColorRegex = /^#[0-9A-Fa-f]{6}$/

        Object.values(ShopGenre).forEach(genre => {
            const color = getGenreColor(genre)
            expect(color).toMatch(hexColorRegex)
        })
    })

    it('should return specific colors for consistency', () => {
        expect(getGenreColor(ShopGenre.RAMEN)).toBe('#CC3333')
        expect(getGenreColor(ShopGenre.CAFE)).toBe('#996633')
        expect(getGenreColor(ShopGenre.IZAKAYA)).toBe('#E69900')
        expect(getGenreColor(ShopGenre.OTHER)).toBe('#808080')
    })

    it('should create genre from valid string value', () => {
        expect(genreFromValue('ラーメン')).toBe(ShopGenre.RAMEN)
        expect(genreFromValue('カフェ')).toBe(ShopGenre.CAFE)
        expect(genreFromValue('その他')).toBe(ShopGenre.OTHER)
    })

    it('should return null for invalid string value', () => {
        expect(genreFromValue('invalid')).toBeNull()
        expect(genreFromValue('')).toBeNull()
        expect(genreFromValue('ramen')).toBeNull()
    })

    it('should validate genre strings correctly', () => {
        expect(isValidGenre('ラーメン')).toBe(true)
        expect(isValidGenre('カフェ')).toBe(true)
        expect(isValidGenre('その他')).toBe(true)

        expect(isValidGenre('invalid')).toBe(false)
        expect(isValidGenre('')).toBe(false)
        expect(isValidGenre('ramen')).toBe(false)
    })

    it('should have consistent color mapping across all genres', () => {
        const colorMap = new Map<string, ShopGenre>()

        Object.values(ShopGenre).forEach(genre => {
            const color = getGenreColor(genre)

            // Check that no two genres have the same color (except potentially OTHER)
            if (colorMap.has(color) && genre !== ShopGenre.OTHER) {
                const existingGenre = colorMap.get(color)
                expect(existingGenre).toBe(genre) // This should fail if colors are duplicated
            }

            colorMap.set(color, genre)
        })
    })

    it('should maintain enum value consistency for cross-platform compatibility', () => {
        // These values must match exactly with iOS Swift and Laravel PHP enums
        const expectedValues = [
            'ラーメン', 'カフェ', '居酒屋', '焼肉', '寿司', 'スイーツ',
            'ファストフード', 'レストラン', 'バー', 'ベーカリー',
            'イタリアン', '中華', '韓国料理', 'フレンチ', '和食',
            '洋食', '海鮮', 'ベジタリアン', 'BBQ', 'その他'
        ]

        const actualValues = Object.values(ShopGenre).sort()
        const sortedExpectedValues = expectedValues.sort()

        expect(actualValues).toEqual(sortedExpectedValues)
    })
})