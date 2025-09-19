<?php

namespace App\Enums;

enum ShopGenre: string
{
    case RAMEN = 'ラーメン';
    case CAFE = 'カフェ';
    case IZAKAYA = '居酒屋';
    case YAKINIKU = '焼肉';
    case SUSHI = '寿司';
    case SWEETS = 'スイーツ';
    case FAST_FOOD = 'ファストフード';
    case RESTAURANT = 'レストラン';
    case BAR = 'バー';
    case BAKERY = 'ベーカリー';
    case ITALIAN = 'イタリアン';
    case CHINESE = '中華';
    case KOREAN = '韓国料理';
    case FRENCH = 'フレンチ';
    case JAPANESE = '和食';
    case WESTERN = '洋食';
    case SEAFOOD = '海鮮';
    case VEGETARIAN = 'ベジタリアン';
    case BBQ = 'BBQ';
    case OTHER = 'その他';

    /**
     * Get the display name for the genre
     */
    public function displayName(): string
    {
        return $this->value;
    }

    /**
     * Get all genre values as an array
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    /**
     * Get all genre names as an array
     */
    public static function names(): array
    {
        return array_column(self::cases(), 'name');
    }

    /**
     * Create genre from string value
     */
    public static function fromValue(string $value): ?self
    {
        foreach (self::cases() as $case) {
            if ($case->value === $value) {
                return $case;
            }
        }
        return null;
    }

    /**
     * Get color hex code for the genre (for admin panel consistency)
     */
    public function colorHex(): string
    {
        return match($this) {
            self::RAMEN => '#CC3333',
            self::CAFE => '#996633',
            self::IZAKAYA => '#E69900',
            self::YAKINIKU => '#B31A1A',
            self::SUSHI => '#0066CC',
            self::SWEETS => '#E666B3',
            self::FAST_FOOD => '#E6B300',
            self::RESTAURANT => '#8033B3',
            self::BAR => '#333333',
            self::BAKERY => '#CC9966',
            self::ITALIAN => '#009933',
            self::CHINESE => '#CC0000',
            self::KOREAN => '#990066',
            self::FRENCH => '#004D99',
            self::JAPANESE => '#669933',
            self::WESTERN => '#B3804D',
            self::SEAFOOD => '#00B3CC',
            self::VEGETARIAN => '#33CC33',
            self::BBQ => '#804000',
            self::OTHER => '#808080',
        };
    }

    /**
     * Check if the genre is valid
     */
    public static function isValid(string $value): bool
    {
        return in_array($value, self::values());
    }
}