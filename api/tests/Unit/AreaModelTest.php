<?php

namespace Tests\Unit;

use App\Models\Area;
use App\Models\Post;
use Illuminate\Database\Eloquent\Builder;
use Tests\TestCase;
use Mockery;

class AreaModelTest extends TestCase
{
    public function test_area_has_correct_fillable_attributes()
    {
        $area = new Area();
        
        $expectedFillable = [
            'name',
        ];
        
        $this->assertEquals($expectedFillable, $area->getFillable());
    }

    public function test_area_has_posts_relationship()
    {
        $area = new Area();
        
        $relation = $area->posts();
        
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsToMany::class, $relation);
        $this->assertEquals('area_post', $relation->getTable());
        $this->assertEquals('area_id', $relation->getForeignPivotKeyName());
        $this->assertEquals('post_id', $relation->getRelatedPivotKeyName());
    }

    public function test_search_scope_builds_correct_query()
    {
        $area = new Area();
        $builder = Mockery::mock(Builder::class);
        
        $keyword = '渋谷';
        
        $builder->shouldReceive('where')
                ->once()
                ->with('name', 'LIKE', "%{$keyword}%")
                ->andReturnSelf();
        
        $result = $area->scopeSearch($builder, $keyword);
        
        $this->assertSame($builder, $result);
    }

    public function test_ordered_scope_builds_correct_query()
    {
        $area = new Area();
        $builder = Mockery::mock(Builder::class);
        
        $builder->shouldReceive('orderBy')
                ->once()
                ->with('name')
                ->andReturnSelf();
        
        $result = $area->scopeOrdered($builder);
        
        $this->assertSame($builder, $result);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}