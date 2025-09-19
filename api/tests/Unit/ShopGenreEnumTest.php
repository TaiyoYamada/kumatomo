<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Enums\ShopGenre;

class ShopGenreEnumTest extends TestCase
{
    public function test_genre_count()
    {
        // Test that we have exactly 20 genres as specified
        $this->assertCount(20, ShopGenre::cases(), 'Should have exactly 20 genres');
    }

    public function test_genre_display_names()
    {
        // Test that display names match values
        foreach (ShopGenre::cases() as $genre) {
            $this->assertEquals($genre->value, $genre->displayName(), "Display name should match value for {$genre->name}");
        }
    }

    public function test_genre_values()
    {
        $values = ShopGenre::values();
        
        // Test that values method returns correct count
        $this->assertCount(20, $values, 'Values should return 20 items');
        
        // Test specific values for consistency
        $this->assertContains('ラーメン', $values);
        $this->assertContains('カフェ', $values);
        $this->assertContains('居酒屋', $values);
        $this->assertContains('焼肉', $values);
        $this->assertContains('寿司', $values);
        $this->assertContains('スイーツ', $values);
        $this->assertContains('ファストフード', $values);
        $this->assertContains('レストラン', $values);
        $this->assertContains('バー', $values);
        $this->assertContains('ベーカリー', $values);
        $this->assertContains('イタリアン', $values);
        $this->assertContains('中華', $values);
        $this->assertContains('韓国料理', $values);
        $this->assertContains('フレンチ', $values);
        $this->assertContains('和食', $values);
        $this->assertContains('洋食', $values);
        $this->assertContains('海鮮', $values);
        $this->assertContains('ベジタリアン', $values);
        $this->assertContains('BBQ', $values);
        $this->assertContains('その他', $values);
    }

    public function test_genre_names()
    {
        $names = ShopGenre::names();
        
        // Test that names method returns correct count
        $this->assertCount(20, $names, 'Names should return 20 items');
        
        // Test specific names
        $this->assertContains('RAMEN', $names);
        $this->assertContains('CAFE', $names);
        $this->assertContains('OTHER', $names);
    }

    public function test_from_value()
    {
        // Test valid values
        $this->assertEquals(ShopGenre::RAMEN, ShopGenre::fromValue('ラーメン'));
        $this->assertEquals(ShopGenre::CAFE, ShopGenre::fromValue('カフェ'));
        $this->assertEquals(ShopGenre::OTHER, ShopGenre::fromValue('その他'));
        
        // Test invalid value
        $this->assertNull(ShopGenre::fromValue('invalid'));
        $this->assertNull(ShopGenre::fromValue(''));
    }

    public function test_is_valid()
    {
        // Test valid values
        $this->assertTrue(ShopGenre::isValid('ラーメン'));
        $this->assertTrue(ShopGenre::isValid('カフェ'));
        $this->assertTrue(ShopGenre::isValid('その他'));
        
        // Test invalid values
        $this->assertFalse(ShopGenre::isValid('invalid'));
        $this->assertFalse(ShopGenre::isValid(''));
        $this->assertFalse(ShopGenre::isValid('ramen'));
    }

    public function test_color_hex()
    {
        // Test that all genres have valid hex colors
        foreach (ShopGenre::cases() as $genre) {
            $color = $genre->colorHex();
            
            // Test hex color format
            $this->assertMatchesRegularExpression('/^#[0-9A-Fa-f]{6}$/', $color, "Genre {$genre->name} should have valid hex color");
        }
        
        // Test specific colors for consistency
        $this->assertEquals('#CC3333', ShopGenre::RAMEN->colorHex());
        $this->assertEquals('#996633', ShopGenre::CAFE->colorHex());
        $this->assertEquals('#808080', ShopGenre::OTHER->colorHex());
    }

    public function test_specific_genre_values()
    {
        // Test specific genre values to ensure consistency across platforms
        $this->assertEquals('ラーメン', ShopGenre::RAMEN->value);
        $this->assertEquals('カフェ', ShopGenre::CAFE->value);
        $this->assertEquals('居酒屋', ShopGenre::IZAKAYA->value);
        $this->assertEquals('焼肉', ShopGenre::YAKINIKU->value);
        $this->assertEquals('寿司', ShopGenre::SUSHI->value);
        $this->assertEquals('スイーツ', ShopGenre::SWEETS->value);
        $this->assertEquals('ファストフード', ShopGenre::FAST_FOOD->value);
        $this->assertEquals('レストラン', ShopGenre::RESTAURANT->value);
        $this->assertEquals('バー', ShopGenre::BAR->value);
        $this->assertEquals('ベーカリー', ShopGenre::BAKERY->value);
        $this->assertEquals('イタリアン', ShopGenre::ITALIAN->value);
        $this->assertEquals('中華', ShopGenre::CHINESE->value);
        $this->assertEquals('韓国料理', ShopGenre::KOREAN->value);
        $this->assertEquals('フレンチ', ShopGenre::FRENCH->value);
        $this->assertEquals('和食', ShopGenre::JAPANESE->value);
        $this->assertEquals('洋食', ShopGenre::WESTERN->value);
        $this->assertEquals('海鮮', ShopGenre::SEAFOOD->value);
        $this->assertEquals('ベジタリアン', ShopGenre::VEGETARIAN->value);
        $this->assertEquals('BBQ', ShopGenre::BBQ->value);
        $this->assertEquals('その他', ShopGenre::OTHER->value);
    }

    public function test_enum_serialization()
    {
        // Test that enum can be serialized to JSON
        $genre = ShopGenre::RAMEN;
        $json = json_encode($genre);
        
        // Decode to verify the value is correct (handles Unicode encoding)
        $decoded = json_decode($json);
        $this->assertEquals('ラーメン', $decoded);
    }
}