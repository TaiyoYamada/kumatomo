# AGENTS.md - kumatomo_ios

> AI coding assistants向けのプロジェクトガイドラインです。

## 🎯 Purpose

このファイルは、AI coding assistantsがkumatomo_iosプロジェクトで効果的にコード生成・支援を行うためのガイドラインを定義します。

---

## 📱 Project Overview

- **言語**: Swift 6.2
- **プラットフォーム**: iOS 17.0+
- **アーキテクチャ**: Clean Architecture
- **UI Framework**: SwiftUI

---

## 🏗️ Architecture - Clean Architecture

このプロジェクトはClean Architectureの原則に従って設計されています。レイヤー間の依存関係を必ず守ってください。

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│    (Views, ViewModels, UI Components, Navigation)            │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                            │
│    (Entities, Use Cases, Repository Protocols)                │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                             │
│    (Repository Implementations, Data Sources, DTOs, Mappers)  │
└─────────────────────────────────────────────────────────────┘
```

### ディレクトリ構成

```
kumatomo_ios/
├── App/           # アプリケーションエントリーポイント
├── Config/        # 設定ファイル、環境変数
├── DI/            # 依存性注入コンテナ
├── Data/          # データ層
│   ├── DataSources/   # API, Local Storage
│   ├── Repositories/  # Repository実装
│   ├── DTOs/          # Data Transfer Objects
│   └── Mappers/       # Entity ↔ DTO 変換
├── Domain/        # ドメイン層
│   ├── Entities/      # ビジネスエンティティ
│   ├── UseCases/      # ビジネスロジック
│   └── Protocols/     # Repository インターフェース
├── Presentation/  # プレゼンテーション層
│   ├── Views/         # SwiftUI Views
│   ├── ViewModels/    # ViewModels (@Observable)
│   ├── Components/    # 再利用可能UIコンポーネント
│   └── Navigation/    # ナビゲーション管理
└── Resources/     # Assets, Localization
```

### 依存関係ルール

```
✅ 許可される依存関係:
   Presentation → Domain
   Data → Domain
   DI → All Layers

❌ 禁止される依存関係:
   Domain → Presentation
   Domain → Data
   Presentation → Data (直接参照)
```

---

## 📁 File Granularity Rule

### 原則

**1ファイルにつき、1つの struct / class / enum / protocol のみを定義してください。**

- 各ファイルは単一の型・単一の責務を持つこと
- 複数の型を1つのファイルにまとめないこと

```swift
// ✅ OK
struct Shop { }

// ❌ NG
struct Shop { }
enum ShopCategory { }


### 例外（許可されるケース）
以下のケースのみ、同一ファイル内での定義を許可します：

- View とその Preview
- ViewModel 専用の小さな enum（例: ViewState, SheetState）
- fileprivate な Helper 型

### AI Assistants への指示（重要）
- 新しい型を追加する場合は、必ず新しいファイルを作成してください
- 既存ファイル内に複数の型が存在するのを見つけた場合は、 責務ごとにファイルを分割してください
- ファイル分割が発生した場合でも、既存のアーキテクチャルール （Clean Architecture の依存関係）を必ず守ってください


---

## 📐 Programming Principles

### SOLID原則

1. **Single Responsibility Principle (SRP)**
   - 各クラス/構造体は単一の責務のみを持つ
   - ViewModelは画面のロジックのみ、UseCaseはビジネスロジックのみ

2. **Open/Closed Principle (OCP)**
   - 拡張に対して開き、修正に対して閉じる
   - プロトコルを活用して拡張性を確保

3. **Liskov Substitution Principle (LSP)**
   - サブタイプは基底型と置換可能であるべき

4. **Interface Segregation Principle (ISP)**
   - クライアントに不要なメソッドへの依存を強制しない
   - 細粒度のプロトコルを定義

5. **Dependency Inversion Principle (DIP)**
   - 上位モジュールは下位モジュールに依存しない
   - 両者は抽象（プロトコル）に依存する

### その他の原則

- **DRY (Don't Repeat Yourself)**: 重複コードを避ける
- **KISS (Keep It Simple, Stupid)**: シンプルに保つ
- **YAGNI (You Aren't Gonna Need It)**: 必要になるまで実装しない
- **Composition over Inheritance**: 継承より合成を優先

---

## 🚀 Swift 6.2 Guidelines

### Concurrency

Swift 6.2の最新のconcurrency機能を活用してください：

```swift
// ✅ 推奨: @MainActor を適切に使用
@MainActor
@Observable
final class SampleViewModel {
    var items: [Item] = []
    
    func load() async {
        items = await useCase.fetchItems()
    }
}

// ✅ 推奨: @concurrent で背景処理
@concurrent
func processData() async -> Result {
    // Heavy computation in background
}

// ✅ 推奨: Sendable 準拠
struct UserDTO: Codable, Sendable {
    let id: String
    let name: String
}
```

### Modern Swift Patterns

```swift
// ✅ if/switch expressions (Swift 5.9+)
let status = if isLoading { "Loading..." } else { "Ready" }

// ✅ Typed throws (Swift 6.0+)
func fetchUser() async throws(NetworkError) -> User

// ✅ @Observable (Observation framework)
@Observable
final class ViewModel {
    var state: ViewState = .idle
}

// ✅ InlineArray for fixed-size performance (Swift 6.2)
let buffer: InlineArray<UInt8, 16> = .init(repeating: 0)

// ✅ Span for safe memory access (Swift 6.2)
func process(data: Span<UInt8>) { ... }
```

### 最新機能の調査

実装時は以下を確認してください：
- [Swift Evolution Proposals](https://apple.github.io/swift-evolution/)
- [Swift Forums](https://forums.swift.org/)
- 公式ドキュメント

---

## 📝 Coding Conventions

### Naming

```swift
// Types: UpperCamelCase
struct UserEntity { }
protocol UserRepositoryProtocol { }
class LoginViewModel { }

// Variables/Functions: lowerCamelCase
let userName: String
func fetchUserData() async { }

// Constants: lowerCamelCase
let maximumRetryCount = 3

// Protocol naming
protocol UserRepositoryProtocol { }  // 末尾に Protocol
protocol Fetchable { }               // 動詞形容詞で able/ible
```

### File Structure

```swift
// 1. Import statements
import SwiftUI
import Combine

// 2. Type definition
@Observable
final class UserViewModel {
    // 2.1 Properties
    var user: User?
    
    // 2.2 Dependencies
    private let useCase: FetchUserUseCaseProtocol
    
    // 2.3 Initializer
    init(useCase: FetchUserUseCaseProtocol) {
        self.useCase = useCase
    }
    
    // 2.4 Methods
    func load() async { }
}

// 3. Extensions (if needed)
extension UserViewModel: Equatable { }
```

---

## 📊 Logging Guidelines

このプロジェクトでは、ログ出力に **Apple Unified Logging System（os.Logger）** を使用します。
`print()` や `NSLog()` は使用せず、`AppLogger` を通じてログを出力してください。

### AppLogger の使用方法

```swift
// カテゴリ別のLoggerインスタンスを使用
private let logger = AppLogger.network  // API通信
private let logger = AppLogger.auth     // 認証・セッション
private let logger = AppLogger.debug    // デバッグ全般
private let logger = AppLogger.ui       // UI関連
private let logger = AppLogger.cache    // キャッシュ

// ログレベル別メソッド
logger.debug("詳細デバッグ情報")  // DEBUGビルドのみ出力
logger.info("一般情報")
logger.warning("警告")
logger.error("エラー")
logger.fault("致命的エラー")

// 便利メソッド
logger.logRequest(method: "POST", url: "/api/posts", body: requestBody)
logger.logResponse(statusCode: 200, url: "/api/posts")
logger.logError(error, context: "投稿作成")
```

### カテゴリ選択の指針

| カテゴリ | 用途 |
|---------|------|
| `network` | API通信、HTTPリクエスト/レスポンス |
| `auth` | 認証、トークン管理、ログイン/ログアウト |
| `debug` | 一般的なデバッグ、開発時の確認 |
| `ui` | UI関連のイベント、画面遷移 |
| `cache` | キャッシュ操作、永続化 |

---

## 🎨 UI Development Guidelines

このプロジェクトは **SwiftUI** をメインUIフレームワークとして使用しますが、
優れたUI/UXを実現するために、以下の標準APIも積極的に活用してください。

### 使用可能なAPI

```swift
// ✅ UIKit（UIViewRepresentableでラップして使用）
- UIScrollView（高度なスクロール制御）
- UICollectionView（複雑なレイアウト）
- UIVisualEffectView（ブラー効果）

// ✅ Core Animation
- CABasicAnimation（カスタムアニメーション）
- CAEmitterLayer（パーティクル効果）
- CAShapeLayer（複雑な図形描画）

// ✅ PhotoKit
- PHPickerViewController（写真選択）
- PHAsset（写真ライブラリアクセス）

// ✅ その他
- AVFoundation（動画・音声）
- MapKit（地図表示）
```

### 方針

- **SwiftUIで十分な場合はSwiftUIを使用**
- **高度なカスタマイズが必要な場合はUIKit/Core Animationを検討**
- **UIViewRepresentable/UIViewControllerRepresentable でSwiftUIに統合**
- **パフォーマンスが重要な場面では低レベルAPIを優先**

---

## ✅ Always Do

- [ ] Clean Architectureのレイヤー分離を遵守する
- [ ] 新しいファイルは適切なディレクトリに配置する
- [ ] Protocolを使用して依存性を注入する
- [ ] async/await と Swift Concurrency を活用する
- [ ] @MainActor を UI 関連のコードに適用する
- [ ] Sendable 準拠を意識する
- [ ] エラーハンドリングを適切に行う
- [ ] 日本語コメントでビジネスロジックを説明する

---

## ⚠️ Ask First

- [ ] 新しい外部依存関係（SPM Package）の追加
- [ ] アーキテクチャパターンの変更
- [ ] 破壊的な API 変更
- [ ] 大規模なリファクタリング
- [ ] セキュリティに関わる実装（認証、暗号化）

---

## 🚫 Never Do

- [ ] Domain層からData層/Presentation層への直接依存
- [ ] View内での直接的なAPI呼び出し
- [ ] 強制アンラップ（!）の多用
- [ ] ハードコードされた文字列（ローカライズ対象）
- [ ] 未テストのビジネスロジックのマージ
- [ ] コンパイル警告の無視
- [ ] 不要なforce castの使用

---

## 🔧 Build & Test Commands

```bash
# ビルド
xcodebuild -project kumatomo.xcodeproj -scheme kumatomo_ios build

# テスト
xcodebuild -project kumatomo.xcodeproj -scheme kumatomoTests test

# SwiftFormat (コードフォーマット)
swiftformat kumatomo_ios/

# SwiftLint (静的解析)
swiftlint lint kumatomo_ios/
```

---


## 📚 References

- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Swift Evolution](https://apple.github.io/swift-evolution/)
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
