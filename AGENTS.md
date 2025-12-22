# AGENTS.md - kumatomo

> AI coding assistants向けのプロジェクトガイドラインです。

## 🎯 Purpose

このファイルは、AI coding assistants（Copilot, Claude, Cursor, etc.）がkumatomoプロジェクト全体で効果的にコード生成・支援を行うためのガイドラインを定義します。

---

## 🏗️ Project Structure

```
kumatomo/
├── api/            # Laravel バックエンドAPI
├── admin/          # 管理画面
├── kumatomo_ios/   # iOS アプリケーション (別途AGENTS.md参照)
├── docker/         # Docker設定ファイル
├── docs/           # ドキュメント
└── docker-compose.yml
```

---

## 📐 Programming Principles

### SOLID原則

すべてのレイヤーで以下の原則を遵守してください：

1. **Single Responsibility Principle (SRP)**
   - 各クラス・モジュールは単一の責務のみを持つ
   - Controller は リクエスト/レスポンス処理のみ
   - Service は ビジネスロジックのみ
   - Repository は データアクセスのみ

2. **Open/Closed Principle (OCP)**
   - 拡張に対して開き、修正に対して閉じる
   - インターフェース/抽象クラスを活用

3. **Liskov Substitution Principle (LSP)**
   - サブタイプは基底型と完全に置換可能であるべき

4. **Interface Segregation Principle (ISP)**
   - 大きなインターフェースより、小さな専用インターフェースを優先
   - 不要なメソッドへの依存を強制しない

5. **Dependency Inversion Principle (DIP)**
   - 具象実装ではなく抽象に依存する
   - 依存性注入を活用

### その他の原則

- **DRY (Don't Repeat Yourself)**: 重複コードを避ける。共通処理はヘルパー/ユーティリティに抽出
- **KISS (Keep It Simple, Stupid)**: 過度な複雑さを避け、シンプルに保つ
- **YAGNI (You Aren't Gonna Need It)**: 現時点で必要ない機能は実装しない
- **Composition over Inheritance**: 継承より合成を優先
- **Fail Fast**: エラーは早期に検出・報告する
- **Clean Code**: 自己文書化されたコードを目指す

---

## 🔍 Research Before Implementation

### 最新コードの調査

実装前に以下を確認し、最新のベストプラクティスを適用してください：

1. **公式ドキュメント**
   - [Laravel Documentation](https://laravel.com/docs)
   - [PHP Official Docs](https://www.php.net/docs.php)
   - [MDN Web Docs](https://developer.mozilla.org/)

2. **パッケージ/ライブラリ**
   - 使用前にGitHubリポジトリで最新バージョンとBreaking Changesを確認
   - READMEとCHANGELOGを必ず読む

3. **既存コードベース**
   - 同様の機能がすでに実装されていないか確認
   - 既存のパターンと一貫性を保つ

---

## 📚 Code Quality Guidelines

### 可読性 (Readability)

```php
// ❌ 読みにくい
function p($d) { return $d['u']->save($d['i']); }

// ✅ 読みやすい
function processUserData(array $data): bool
{
    $user = $data['user'];
    $input = $data['input'];
    
    return $user->save($input);
}
```

### 拡張性 (Extensibility)

```php
// ❌ ハードコードされた実装
class PaymentService
{
    public function process($order)
    {
        // Stripe固有の処理
    }
}

// ✅ インターフェースによる拡張性
interface PaymentGatewayInterface
{
    public function process(Order $order): PaymentResult;
}

class StripePaymentGateway implements PaymentGatewayInterface
{
    public function process(Order $order): PaymentResult
    {
        // Stripe implementation
    }
}

class PaymentService
{
    public function __construct(
        private PaymentGatewayInterface $gateway
    ) {}
    
    public function process(Order $order): PaymentResult
    {
        return $this->gateway->process($order);
    }
}
```

### 命名規則

```php
// クラス名: PascalCase
class UserController {}
class OrderService {}
class UserRepository {}

// メソッド名: camelCase
public function getUserById(int $id): ?User {}
public function createOrder(array $data): Order {}

// 変数名: camelCase
$userName = 'John';
$orderItems = [];

// 定数: UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';
```

---

## 📁 API Layer (Laravel)

### ディレクトリ構成

```
api/
├── app/
│   ├── Http/
│   │   ├── Controllers/     # リクエスト/レスポンス処理
│   │   ├── Requests/        # バリデーション
│   │   └── Resources/       # APIレスポンス変換
│   ├── Services/            # ビジネスロジック
│   ├── Repositories/        # データアクセス
│   ├── Models/              # Eloquent Models
│   └── Exceptions/          # カスタム例外
├── database/
│   ├── migrations/          # DBマイグレーション
│   └── seeders/             # テストデータ
├── routes/
│   └── api.php              # APIルート定義
└── tests/
    ├── Feature/             # Feature tests
    └── Unit/                # Unit tests
```

### Laravel Best Practices

```php
// ✅ Form Request でバリデーション
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'unique:users'],
            'name' => ['required', 'string', 'max:255'],
        ];
    }
}

// ✅ API Resource でレスポンス変換
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}

// ✅ Service Pattern でビジネスロジック分離
class UserService
{
    public function __construct(
        private UserRepository $userRepository
    ) {}
    
    public function createUser(array $data): User
    {
        // ビジネスロジック
        return $this->userRepository->create($data);
    }
}
```

---

## ✅ Always Do

- [ ] 公式ドキュメントで最新の書き方を確認する
- [ ] 既存コードのパターンと一貫性を保つ
- [ ] 適切なエラーハンドリングを実装する
- [ ] 意味のある変数名・関数名を使用する
- [ ] 複雑なロジックにはコメントを追加する（日本語可）
- [ ] 型宣言を積極的に使用する
- [ ] デッドコードを削除する
- [ ] セキュリティベストプラクティスに従う

---

## ⚠️ Ask First

- [ ] 新しい外部依存関係（Composer/npm package）の追加
- [ ] データベーススキーマの変更
- [ ] 認証・認可ロジックの変更
- [ ] 破壊的な API 変更
- [ ] パフォーマンスに影響する大規模な変更
- [ ] 環境変数の追加・変更
- [ ] サードパーティサービスとの統合

---

## 🚫 Never Do

- [ ] ハードコードされた認証情報やシークレット
- [ ] SQLインジェクションを可能にするコード
- [ ] 未検証のユーザー入力の直接使用
- [ ] N+1クエリ問題を放置
- [ ] 本番環境でのデバッグ出力
- [ ] テストなしのビジネスロジック変更
- [ ] 既存APIの後方互換性を壊す変更
- [ ] `dd()` や `var_dump()` のコミット

---

## 🔧 Development Commands

```bash
# API (Laravel)
cd api
composer install
php artisan migrate
php artisan serve

# Docker
docker-compose up -d
docker-compose logs -f api

# テスト
php artisan test
php artisan test --filter=UserTest

# コードフォーマット
./vendor/bin/pint

# 静的解析
./vendor/bin/phpstan analyse
```

---

## 🔒 Security Guidelines

- ユーザー入力は必ずバリデーション
- パスワードは Hash ファサードで暗号化
- API認証には Laravel Sanctum を使用
- 機密データは環境変数で管理
- CORS設定を適切に構成

---

## 📚 References

- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [PHP The Right Way](https://phptherightway.com/)
- [Clean Code PHP](https://github.com/piotrplenik/clean-code-php)
- [12 Factor App](https://12factor.net/)
