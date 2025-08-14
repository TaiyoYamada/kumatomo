<?php

namespace Tests\Unit;

use App\Models\Shop;
use Illuminate\Database\Eloquent\Builder;
use Tests\TestCase;
use Mockery;

class ShopModelTest extends TestCase
{
    public function test_nearby_scope_builds_correct_query()
    {
        $shop = new Shop();
        $builder = Mockery::mock(Builder::class);
        
        $latitude = 35.6812;
        $longitude = 139.7671;
        $radius = 10;
        
        $builder->shouldReceive('selectRaw')
                ->once()
                ->with(
                    "
            *,
            (6371 * acos(cos(radians(?)) 
            * cos(radians(latitude)) 
            * cos(radians(longitude) - radians(?)) 
            + sin(radians(?)) 
            * sin(radians(latitude)))) AS distance
        ",
                    [$latitude, $longitude, $latitude]
                )
                ->andReturnSelf();
                
        $builder->shouldReceive('having')
                ->once()
                ->with('distance', '<', $radius)
                ->andReturnSelf();
                
        $builder->shouldReceive('orderBy')
                ->once()
                ->with('distance')
                ->andReturnSelf();
        
        $result = $shop->scopeNearby($builder, $latitude, $longitude, $radius);
        
        $this->assertSame($builder, $result);
    }

    public function test_by_genre_scope_builds_correct_query()
    {
        $shop = new Shop();
        $builder = Mockery::mock(Builder::class);
        
        $genre = 'レストラン';
        
        $builder->shouldReceive('where')
                ->once()
                ->with('genre', $genre)
                ->andReturnSelf();
        
        $result = $shop->scopeByGenre($builder, $genre);
        
        $this->assertSame($builder, $result);
    }

    public function test_search_scope_builds_correct_query()
    {
        $shop = new Shop();
        $builder = Mockery::mock(Builder::class);
        $innerBuilder = Mockery::mock(Builder::class);
        
        $keyword = 'ラーメン';
        
        $builder->shouldReceive('where')
                ->once()
                ->with(Mockery::type('Closure'))
                ->andReturnUsing(function ($closure) use ($innerBuilder) {
                    $closure($innerBuilder);
                    return $innerBuilder;
                });
        
        $innerBuilder->shouldReceive('where')
                     ->once()
                     ->with('name', 'LIKE', "%{$keyword}%")
                     ->andReturnSelf();
                     
        $innerBuilder->shouldReceive('orWhere')
                     ->once()
                     ->with('description', 'LIKE', "%{$keyword}%")
                     ->andReturnSelf();
                     
        $innerBuilder->shouldReceive('orWhere')
                     ->once()
                     ->with('address', 'LIKE', "%{$keyword}%")
                     ->andReturnSelf();
        
        $result = $shop->scopeSearch($builder, $keyword);
        
        $this->assertSame($innerBuilder, $result);
    }

    public function test_shop_has_correct_fillable_attributes()
    {
        $shop = new Shop();
        
        $expectedFillable = [
            'name',
            'description',
            'address',
            'phone',
            'business_hours',
            'genre',
            'latitude',
            'longitude',
            'image_url'
        ];
        
        $this->assertEquals($expectedFillable, $shop->getFillable());
    }

    public function test_shop_has_correct_casts()
    {
        $shop = new Shop();
        
        $expectedCasts = [
            'latitude' => 'decimal:8',
            'longitude' => 'decimal:8',
        ];
        
        $casts = $shop->getCasts();
        
        $this->assertEquals('decimal:8', $casts['latitude']);
        $this->assertEquals('decimal:8', $casts['longitude']);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}