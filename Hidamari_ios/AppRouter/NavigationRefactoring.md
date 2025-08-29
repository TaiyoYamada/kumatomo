# 画面遷移enum整理 - 修正内容まとめ

## 実施日
2025年8月29日

## 修正概要
ひだまりアプリのiOS画面遷移に関するenumを整理し、AppRouterフォルダに統合しました。

## 修正内容

### 1. enum統合
- **統合前**: `MainTabView.Selection` (ContentView.swift内)
- **統合後**: `TabSelection` (AppRouter/RouterDestination.swift内)
- **理由**: タブ選択もナビゲーションの一部として統一管理

### 2. 命名規則統一
- **enum名**: PascalCase（例: `RouterDestination`, `TabSelection`, `SheetDestination`）
- **case名**: camelCase（例: `myProfile`, `shopList`, `initialSetup`）
- **Swift標準の命名規則に準拠**

### 3. NavigationView → NavigationStack置き換え
以下のファイルでNavigationViewをNavigationStackに置き換え：
- `Hidamari_ios/Views/MainTab/MyPage/ProfileEditView.swift`
- `Hidamari_ios/Views/MainTab/MyPage/MyProfileView.swift`
- `Hidamari_ios/Views/MainTab/Shop/ShopPickerView.swift`
- `Hidamari_ios/Views/MainTab/Shop/ShopDetailView.swift`
- `Hidamari_ios/Views/MainTab/Post/PostView.swift`
- `Hidamari_ios/Views/MainTab/Home/Components/TabNavigationHeader.swift`
- `Hidamari_ios/Views/Auth/InitialSetupView.swift`
- `Hidamari_ios/Views/MainTab/Post/PostDetailView.swift`
- `Hidamari_ios/Views/MainTab/Post/PostPreviewView.swift`

### 4. 整理後のenum構造

#### RouterDestination (画面遷移用)
```swift
enum RouterDestination: Hashable {
    case myProfile      // マイプロフィール画面
    case shopList       // お店一覧画面
    case bookmarks      // ブックマーク画面
    case likes          // いいね一覧画面
    case coupons        // クーポン画面
    case settings       // 設定画面
    case search         // 検索画面
    case signUp         // サインアップ画面
    case initialSetup   // 初期設定画面
}
```

#### TabSelection (タブ選択用)
```swift
enum TabSelection: Hashable {
    case home     // ホームタブ
    case search   // 検索タブ
    case post     // 投稿タブ
    case profile  // プロフィールタブ
}
```

#### SheetDestination (モーダル表示用)
```swift
enum SheetDestination: Identifiable {
    case postDetail(Post)
    case shopDetail(Shop)
    case shopPicker(selectedShop: Binding<Shop?>)
    case postPreview(content: String, images: [UIImage], shop: Shop?, onPost: () -> Void)
    case profileEdit(User)
    case municipalityPicker(selected: String?, onSelect: (String) -> Void)
    case postEdit(viewModel: PostViewModel)
}
```

## 修正されたファイル一覧

### AppRouterフォルダ
- `RouterDestination.swift` - TabSelectionを追加、コメント追加
- `SheetDestination.swift` - コメント追加

### ContentView
- `ContentView.swift` - Selection enumを削除、TabSelectionを使用

### NavigationView → NavigationStack置き換え
- `ProfileEditView.swift`
- `MyProfileView.swift`
- `ShopPickerView.swift`
- `ShopDetailView.swift`
- `PostView.swift`
- `TabNavigationHeader.swift`
- `InitialSetupView.swift`
- `PostDetailView.swift`
- `PostPreviewView.swift`

## 動作確認項目
- [ ] タブ切り替えが正常に動作する
- [ ] 画面遷移が正常に動作する
- [ ] モーダル表示が正常に動作する
- [ ] NavigationStackでの戻るボタンが正常に動作する
- [ ] 既存の機能に影響がない

## 今後の方針
1. 新しい画面を追加する際は、AppRouter内のenumに追加する
2. 画面遷移関連のenumは他のファイルに作成しない
3. NavigationViewは使用せず、NavigationStackを使用する
4. 命名規則（PascalCase/camelCase）を遵守する

## 注意事項
- アプリの仕様や動作は変更していません
- 既存のNavigationLinkの実装はそのまま維持
- エラーハンドリングや状態管理は既存のまま