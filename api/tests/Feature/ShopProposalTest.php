<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\ShopProposal;
use App\Models\Shop;
use App\Enums\ShopGenre;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use Laravel\Sanctum\Sanctum;

class ShopProposalTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create a test user
        $this->user = User::factory()->create([
            'username' => 'testuser',
            'email' => 'test@example.com'
        ]);
    }

    /** @test */
    public function user_can_submit_shop_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposalData = [
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3',
            'genre' => ShopGenre::RAMEN->value,
            'description' => 'とても美味しいラーメン店です。'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(201)
                ->assertJsonStructure([
                    'data' => [
                        'id',
                        'user_id',
                        'name',
                        'address',
                        'genre',
                        'description',
                        'status',
                        'created_at',
                        'updated_at'
                    ],
                    'message'
                ]);

        $this->assertDatabaseHas('shop_proposals', [
            'user_id' => $this->user->id,
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3',
            'genre' => ShopGenre::RAMEN->value,
            'description' => 'とても美味しいラーメン店です。',
            'status' => ShopProposal::STATUS_PENDING
        ]);
    }

    /** @test */
    public function user_can_submit_minimal_shop_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposalData = [
            'name' => 'ミニマル店舗'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(201);

        $this->assertDatabaseHas('shop_proposals', [
            'user_id' => $this->user->id,
            'name' => 'ミニマル店舗',
            'address' => null,
            'genre' => null,
            'description' => null,
            'status' => ShopProposal::STATUS_PENDING
        ]);
    }

    /** @test */
    public function shop_proposal_requires_authentication()
    {
        $proposalData = [
            'name' => 'テスト店舗'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(401);
    }

    /** @test */
    public function shop_proposal_validates_required_fields()
    {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/shop-proposals', []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name']);
    }

    /** @test */
    public function shop_proposal_validates_field_lengths()
    {
        Sanctum::actingAs($this->user);

        $proposalData = [
            'name' => str_repeat('a', 101), // Too long
            'address' => str_repeat('b', 256), // Too long
            'description' => str_repeat('c', 1001), // Too long
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name', 'address', 'description']);
    }

    /** @test */
    public function shop_proposal_validates_genre()
    {
        Sanctum::actingAs($this->user);

        $proposalData = [
            'name' => 'テスト店舗',
            'genre' => 'invalid_genre'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['genre']);
    }

    /** @test */
    public function user_cannot_submit_duplicate_pending_proposals()
    {
        Sanctum::actingAs($this->user);

        // Create existing pending proposal
        ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'テスト店舗',
            'status' => ShopProposal::STATUS_PENDING
        ]);

        $proposalData = [
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(422)
                ->assertJson([
                    'error' => [
                        'message' => '同じ名前の店舗提案が既に承認待ちです。',
                        'code' => 'DUPLICATE_PROPOSAL'
                    ]
                ]);
    }

    /** @test */
    public function user_can_submit_proposal_with_same_name_if_previous_was_processed()
    {
        Sanctum::actingAs($this->user);

        // Create existing approved proposal
        ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'テスト店舗',
            'status' => ShopProposal::STATUS_APPROVED
        ]);

        $proposalData = [
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(201);
    }

    /** @test */
    public function rate_limiting_prevents_too_many_proposals()
    {
        Sanctum::actingAs($this->user);

        // Submit 3 proposals in the last hour
        for ($i = 0; $i < 3; $i++) {
            ShopProposal::factory()->create([
                'user_id' => $this->user->id,
                'name' => "テスト店舗{$i}",
                'created_at' => now()->subMinutes(30)
            ]);
        }

        $proposalData = [
            'name' => 'テスト店舗4'
        ];

        $response = $this->postJson('/api/shop-proposals', $proposalData);

        $response->assertStatus(429)
                ->assertJson([
                    'error' => [
                        'message' => '1時間に3件以上の提案はできません。しばらく時間をおいてから再度お試しください。',
                        'code' => 'RATE_LIMIT_EXCEEDED'
                    ]
                ]);
    }

    /** @test */
    public function user_can_view_their_proposals()
    {
        Sanctum::actingAs($this->user);

        $proposals = ShopProposal::factory()->count(3)->create([
            'user_id' => $this->user->id
        ]);

        // Create proposals for another user (should not be visible)
        $otherUser = User::factory()->create();
        ShopProposal::factory()->count(2)->create([
            'user_id' => $otherUser->id
        ]);

        $response = $this->getJson('/api/shop-proposals');

        $response->assertStatus(200)
                ->assertJsonCount(3, 'data');

        // Verify only user's proposals are returned
        $responseData = $response->json('data');
        foreach ($responseData as $proposal) {
            $this->assertEquals($this->user->id, $proposal['user_id']);
        }
    }

    /** @test */
    public function user_can_view_specific_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id
        ]);

        $response = $this->getJson("/api/shop-proposals/{$proposal->id}");

        $response->assertStatus(200)
                ->assertJson([
                    'data' => [
                        'id' => $proposal->id,
                        'user_id' => $this->user->id,
                        'name' => $proposal->name
                    ]
                ]);
    }

    /** @test */
    public function user_cannot_view_other_users_proposals()
    {
        Sanctum::actingAs($this->user);

        $otherUser = User::factory()->create();
        $proposal = ShopProposal::factory()->create([
            'user_id' => $otherUser->id
        ]);

        $response = $this->getJson("/api/shop-proposals/{$proposal->id}");

        $response->assertStatus(403);
    }

    /** @test */
    public function user_can_update_pending_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_PENDING
        ]);

        $updateData = [
            'name' => '更新された店舗名',
            'address' => '更新された住所',
            'genre' => ShopGenre::CAFE->value,
            'description' => '更新された説明'
        ];

        $response = $this->putJson("/api/shop-proposals/{$proposal->id}", $updateData);

        $response->assertStatus(200)
                ->assertJson([
                    'data' => [
                        'name' => '更新された店舗名',
                        'address' => '更新された住所',
                        'genre' => ShopGenre::CAFE->value,
                        'description' => '更新された説明'
                    ]
                ]);

        $this->assertDatabaseHas('shop_proposals', [
            'id' => $proposal->id,
            'name' => '更新された店舗名'
        ]);
    }

    /** @test */
    public function user_cannot_update_processed_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_APPROVED
        ]);

        $updateData = [
            'name' => '更新された店舗名'
        ];

        $response = $this->putJson("/api/shop-proposals/{$proposal->id}", $updateData);

        $response->assertStatus(422)
                ->assertJson([
                    'error' => [
                        'message' => '承認済みまたは却下された提案は編集できません。',
                        'code' => 'PROPOSAL_NOT_EDITABLE'
                    ]
                ]);
    }

    /** @test */
    public function user_can_delete_pending_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_PENDING
        ]);

        $response = $this->deleteJson("/api/shop-proposals/{$proposal->id}");

        $response->assertStatus(200);

        $this->assertDatabaseMissing('shop_proposals', [
            'id' => $proposal->id
        ]);
    }

    /** @test */
    public function user_cannot_delete_processed_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_APPROVED
        ]);

        $response = $this->deleteJson("/api/shop-proposals/{$proposal->id}");

        $response->assertStatus(422);

        $this->assertDatabaseHas('shop_proposals', [
            'id' => $proposal->id
        ]);
    }

    /** @test */
    public function user_can_get_proposal_status_summary()
    {
        Sanctum::actingAs($this->user);

        // Create proposals with different statuses
        ShopProposal::factory()->count(2)->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_PENDING
        ]);

        ShopProposal::factory()->count(1)->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_APPROVED
        ]);

        ShopProposal::factory()->count(1)->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_REJECTED
        ]);

        $response = $this->getJson('/api/shop-proposals-status');

        $response->assertStatus(200)
                ->assertJson([
                    'summary' => [
                        'pending' => 2,
                        'approved' => 1,
                        'rejected' => 1
                    ]
                ])
                ->assertJsonCount(4, 'data');
    }

    /** @test */
    public function admin_can_approve_proposal_and_create_shop()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_PENDING,
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3',
            'genre' => ShopGenre::RAMEN->value,
            'description' => 'テスト説明'
        ]);

        $approvalData = [
            'admin_notes' => '承認しました。',
            'latitude' => 32.7903,
            'longitude' => 130.7414,
            'phone' => '096-123-4567',
            'business_hours' => '11:00-22:00',
            'image_url' => 'https://example.com/image.jpg'
        ];

        $response = $this->postJson("/api/admin/shop-proposals/{$proposal->id}/approve", $approvalData);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data' => [
                        'shop' => [
                            'id',
                            'name',
                            'address',
                            'genre',
                            'description',
                            'latitude',
                            'longitude',
                            'phone',
                            'business_hours',
                            'image_url',
                            'is_approved'
                        ],
                        'proposal' => [
                            'id',
                            'status',
                            'admin_notes'
                        ]
                    ]
                ]);

        // Verify shop was created
        $this->assertDatabaseHas('shops', [
            'name' => 'テスト店舗',
            'address' => '熊本市中央区テスト町1-2-3',
            'genre' => ShopGenre::RAMEN->value,
            'description' => 'テスト説明',
            'latitude' => 32.7903,
            'longitude' => 130.7414,
            'phone' => '096-123-4567',
            'business_hours' => '11:00-22:00',
            'image_url' => 'https://example.com/image.jpg',
            'is_approved' => true
        ]);

        // Verify proposal was updated
        $this->assertDatabaseHas('shop_proposals', [
            'id' => $proposal->id,
            'status' => ShopProposal::STATUS_APPROVED,
            'admin_notes' => '承認しました。'
        ]);
    }

    /** @test */
    public function admin_can_reject_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_PENDING
        ]);

        $rejectionData = [
            'admin_notes' => '情報が不十分です。'
        ];

        $response = $this->postJson("/api/admin/shop-proposals/{$proposal->id}/reject", $rejectionData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('shop_proposals', [
            'id' => $proposal->id,
            'status' => ShopProposal::STATUS_REJECTED,
            'admin_notes' => '情報が不十分です。'
        ]);
    }

    /** @test */
    public function admin_cannot_process_already_processed_proposal()
    {
        Sanctum::actingAs($this->user);

        $proposal = ShopProposal::factory()->create([
            'user_id' => $this->user->id,
            'status' => ShopProposal::STATUS_APPROVED
        ]);

        $response = $this->postJson("/api/admin/shop-proposals/{$proposal->id}/approve", [
            'admin_notes' => 'テスト'
        ]);

        $response->assertStatus(422)
                ->assertJson([
                    'error' => [
                        'message' => 'この提案は既に処理済みです。',
                        'code' => 'PROPOSAL_ALREADY_PROCESSED'
                    ]
                ]);
    }
}