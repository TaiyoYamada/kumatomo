# AGENTS.md - kumatomo_ios

> AI coding assistants向けのプロジェクトガイドラインです。

## 🎯 Purpose

このファイルは、AI coding assistants（Copilot, Claude, Cursor, etc.）がkumatomo_iosプロジェクトで効果的にコード生成・支援を行うためのガイドラインを定義します。

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
