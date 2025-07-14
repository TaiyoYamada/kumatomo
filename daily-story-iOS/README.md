# 熊本県掲示板アプリ（Kumamoto Bulletin Board App）

このアプリは、熊本県内の市区町村ごとに掲示板を分けた、ローカル向けSNSアプリです。SwiftUI + Laravel（API）を用いた設計で、シンプルかつ安全に地域のつながりをサポートします。

## クライアント概要（iOS）

- 言語：Swift 5.9+
- UI：SwiftUI
- 認証：Laravel Sanctum + Bearer Token（メール・パスワード・認証コード）
- ストレージ：ImgBB（画像アップロード）
- 対応OS：iOS 17+

## 🌐 バックエンド概要（API）

- フレームワーク：Laravel 11.x（Sail + Docker）
- データベース：MySQL 8.x
- 認証：Sanctum（SPA対応）
- API通信：REST（JSONベース）

## 🔐 主な機能

- ユーザー登録・ログイン（メール + 認証コード）
- プロフィール設定（初回セットアップ）
- 市区町村ごとの掲示板表示
- 投稿作成・画像添付
- 投稿一覧・詳細・削除（ユーザーのみ）
- お気に入り・投稿の絞り込み（予定）

## 🧪 開発メモ

- 初回登録後に `hasCompletedSetup = true` を `@AppStorage` 経由で保存
- 投稿は `Story` モデル経由で管理（`user`, `content`, `createdAt` 含む）
- iPhoneのみに対応（iPadは未対応）

## ディレクトリ構成

```plaintext
daily-story-iOS/
├── App/                   // アプリのエントリーポイント（@main）、ルーティング処理
├── Models/                // ユーザーモデル・デートモデルなど
├── Resources/             // Assetsやカスタムフォントなど
├── Services/              // API通信関連のサービス
├── Utils/                 // 共通処理や拡張
├── ViewModels/            // ビジネスロジック（ObservableObject）
├── Views/                 // SwiftUIビュー
└── README.md              // このファイル
```
